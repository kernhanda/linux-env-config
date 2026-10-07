# jj + gh pull-request helper.  Stowed to ~/.jj-gh.sh, sourced from .zshrc.
#
# Built for colocated jj checkouts, where git is permanently detached and
# `gh` therefore can't infer --head from a current branch. Branch names come
# from jj's own `templates.git_push_bookmark`, so they track that config.
#
#   jpr [TOP] [-d|--draft] [-y|--yes] [--base BRANCH] [--no-footer] [--no-footer-for REVSET] [--no-reuse] [--no-stack]
#       Create/refresh one draft PR per non-empty change in (trunk()..TOP)
#       (default TOP=@). Each PR is based on its *actual* parent: a change's
#       base is the branch of its nearest ancestor that is itself a pushable
#       change in the range, or the trunk branch (--base / JPR_BASE, default
#       main) when it has no such ancestor. So a linear stack chains, and
#       parallel branches each target trunk — e.g. three sibling changes joined
#       by an empty merge produce three independent PRs against main, not a fake
#       linear chain. Empty changes (the working copy, merge nodes) and changes
#       with no description set are dropped, so a lone real change just makes one
#       PR. Every run resyncs each PR's
#       title and body from its jj change description, so re-running after
#       `jj describe` keeps the PR text current (jpr owns the description; edits
#       made on GitHub are overwritten). With 2+ changes outside a GitHub stack
#       (below), their PR bodies are then annotated with the relationship map
#       (a stack when changes chain, a related-PR group when they are
#       independent).
#
#       --no-footer (JPR_NO_FOOTER=1) suppresses this relationship map entirely;
#       bodies then carry only the change description, and any map left by a
#       previous run is dropped. --no-footer-for REVSET (JPR_NO_FOOTER_FOR)
#       excludes the changes matching REVSET from the map: each still gets its
#       own PR but with no map, and it is omitted from the others' maps; a child
#       whose nearest in-range ancestor is excluded re-points past it to the
#       next visible ancestor (or trunk). The excluded change's own PR base is
#       left untouched — only the cosmetic map hides it.
#
#       A change may already live on a differently-named upstream bookmark
#       (pushed before jpr, or under another git_push_bookmark template). When
#       the templated branch has no open PR but another local bookmark on the
#       change does, jpr adopts that bookmark as the change's head and updates
#       its PR instead of minting a duplicate branch + PR; such lines are marked
#       [existing bookmark] in the plan, and stacked children base on the
#       adopted name. --no-reuse (JPR_NO_REUSE=1) disables the adoption.
#
#       Each linear chain of 2+ PRs is linked into a native GitHub stack. A
#       re-run keeps a stack whose open PRs start with the chain (TOP may sit
#       mid-stack), appends to one the chain extends, and otherwise unstacks
#       and recreates it. GitHub won't retarget a stacked PR, so a stack holding
#       a PR whose base must move is unstacked before the edit; a stack touched
#       only by a lone or branched change is otherwise left alone. Stacked PRs
#       get no relationship map. --no-stack (JPR_NO_STACK=1) skips the stacks
#       API; repos without stacked PRs fall back to the map.
#
#       jpr first prints the plan (which branches it will push, which PRs it
#       will create vs update, with their bases, and the stack changes) and
#       asks for confirmation before touching the remote. Nothing is pushed or
#       edited until you confirm. -y/--yes (or JPR_YES=1) skips the prompt;
#       with no TTY and no -y, jpr refuses to proceed.
#
# There is no separate single-PR vs stacked-PR command: in jj a single PR is
# just a one-deep stack, so jpr is the only verb.
#
# Notifications: existing PRs are drafted before the push, so even the push's
# new commits land quietly; all create/base/body churn likewise happens in
# draft; PRs are flipped to "ready for review" only once at the very end
# (unless -d), so reviewers get at most one notification per PR. Final state
# defaults to ready; export
# JPR_DRAFT=1 to default to draft (matches the "all PRs are drafts" house rule).
# JPR_BASE overrides the trunk base branch (default main). JPR_KEEP_READY=1
# leaves already-ready PRs alone instead of force-drafting them during edits.
# JPR_NO_FOOTER=1 defaults --no-footer on; JPR_NO_FOOTER_FOR sets a default
# --no-footer-for revset. JPR_NO_STACK=1 defaults --no-stack on. Written to run
# under both zsh and bash.

# _pr_set_draft PR WANT_DRAFT(1|0): move a PR to the requested draft state,
# skipping the (notifying) call when it is already there.
_pr_set_draft() {
  local d
  d=$(gh pr view "$1" --json isDraft --jq .isDraft)
  if [ "$2" -eq 1 ]; then
    [ "$d" = "false" ] && gh pr ready --undo "$1" >/dev/null
  else
    [ "$d" = "true" ] && gh pr ready "$1" >/dev/null
  fi
}

# _jpr_open_pr HEAD: "<number>\t<base branch>" of HEAD's open PR, if any.
_jpr_open_pr() {
  gh pr list --head "$1" --state open --json number,baseRefName \
    --jq '.[0] | select(.) | "\(.number)\t\(.baseRefName)"'
}

# _jpr_unstack STACK: pull a GitHub stack's open PRs out of it. Queued or
# auto-merge PRs can't leave a stack; report any that stay.
_jpr_unstack() {
  local left
  left=$(gh api -X POST "repos/{owner}/{repo}/stacks/$1/unstack" \
           --jq '[.pull_requests[] | select(.state == "open") | "#\(.number)"] | join(" ")') \
    || { echo "jpr: could not unstack stack #$1" >&2; return 1; }
  [ -n "$left" ] && echo "jpr: stack #$1 still holds $left (queued or auto-merge)" >&2
  return 0
}

jpr() {
  local top="@" want_draft="${JPR_DRAFT:-0}" base="${JPR_BASE:-main}" assume_yes="${JPR_YES:-0}" \
        no_footer="${JPR_NO_FOOTER:-0}" no_footer_for="${JPR_NO_FOOTER_FOR:-}" no_reuse="${JPR_NO_REUSE:-0}" \
        no_stack="${JPR_NO_STACK:-0}"
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--draft)  want_draft=1 ;;
      -y|--yes)    assume_yes=1 ;;
      --base)      shift; base="$1" ;;
      --base=*)    base="${1#--base=}" ;;
      --no-footer) no_footer=1 ;;
      --no-footer-for)   shift; no_footer_for="$1" ;;
      --no-footer-for=*) no_footer_for="${1#--no-footer-for=}" ;;
      --no-reuse)  no_reuse=1 ;;
      --no-stack)  no_stack=1 ;;
      -h|--help)   echo "usage: jpr [TOP] [-d|--draft] [-y|--yes] [--base BRANCH] [--no-footer] [--no-footer-for REVSET] [--no-reuse] [--no-stack]"; return 0 ;;
      -*)          echo "jpr: unknown option: $1" >&2; return 2 ;;
      *)           top="$1" ;;
    esac
    shift
  done

  # `base` is the trunk branch and is never reassigned: each change computes its
  # own base from its parent, so it must not leak into the next iteration.
  # `description("")` is jj's special-case for "no description set", so the range
  # also drops undescribed changes — there's nothing to title/body a PR with, and
  # `jj git push` refuses them anyway. A child whose nearest in-range ancestor is
  # undescribed re-points its base past it, exactly as for empty changes.
  local range="(trunk()..$top) ~ empty() ~ description(\"\")" tmpl
  local tab=$'\t' nl=$'\n'
  tmpl=$(jj config get templates.git_push_bookmark)

  local -a plan nums display exec_seen vis fmap heads_seen push_args chains tmp \
           stk_seen stack_plan stacks_done
  plan=(); nums=(); display=(); exec_seen=(); heads_seen=(); push_args=()
  chains=(); stk_seen=(); stack_plan=(); stacks_done=()
  # Declare every scalar local ONCE, here. Re-running `local NAME` on a name
  # that already holds a value makes zsh echo it (NAME=$'...'); declared once,
  # never again below — assign (without `local`) wherever needed.
  local cid title head base_change cur_base existing_num tag pline preview \
        fstate reply entry rest s body num cur enum ebase etitle line header \
        block num2 url n excluded_cids excluded_marks any_parent_vis \
        bc nbc ecid e fbase_num reuse bmk existing gh_base stacks_ok snum \
        sopen touched stale unstack live r row rcids linear toks hit lbls tok \
        lbl act c csv delta out hidden_marks stack_preview

  # Resolve --no-footer-for to a "|cid|cid|" lookup over the range (empty set
  # when unset, or when --no-footer drops the whole map anyway). Intersecting
  # with $range keeps it bounded and matches the change_id.short() used below.
  excluded_marks="||"
  if [ "$no_footer" -ne 1 ] && [ -n "$no_footer_for" ]; then
    excluded_cids=$(jj log --no-graph --no-pager -r "($no_footer_for) & ($range)" \
                      -T 'change_id.short() ++ "\n"') \
      || { echo "jpr: invalid --no-footer-for revset: $no_footer_for" >&2; return 2; }
    excluded_marks="|${excluded_cids//$nl/|}|"
  fi

  # Stacked PRs are a per-repo feature; the stacks endpoints 404 where it's off.
  # Stack sets below are ",num,num," strings.
  stacks_ok=0; touched=","; stale=","; unstack=","
  if [ "$no_stack" -ne 1 ] && gh api 'repos/{owner}/{repo}/stacks?per_page=1' >/dev/null 2>&1; then
    stacks_ok=1
  fi

  # PLANNING (read-only): no push, no PR or stack create/edit. Walk the changes
  # in topological order and resolve, per change: its branch, its PR base, and
  # whether a PR already exists (update) or not (create). `plan` is built
  # bottom -> top (execution order); `preview` is built top -> bottom for the
  # human. base/branch resolution is pure jj, so it needs neither the push nor
  # any existing PR — only the PR and stack lookups hit the network.
  while IFS="$tab" read -r cid title; do
    [ -z "$cid" ] && continue
    head=$(jj log --no-graph --no-pager -r "$cid" -T "$tmpl")
    reuse=0
    existing=$(_jpr_open_pr "$head")
    # The change may already live on a differently-named upstream bookmark with
    # an open PR (local bookmarks follow rewrites, so they sit on the current
    # commit even after amends). Adopt the first such bookmark as the head
    # instead of minting a duplicate branch + PR.
    if [ -z "$existing" ] && [ "$no_reuse" -ne 1 ]; then
      while IFS= read -r bmk; do
        { [ -z "$bmk" ] || [ "$bmk" = "$head" ] || [ "$bmk" = "$base" ]; } && continue
        existing=$(_jpr_open_pr "$bmk")
        [ -n "$existing" ] && { head="$bmk"; reuse=1; break; }
      done < <(jj log --no-graph --no-pager -r "$cid" \
                 -T 'local_bookmarks.map(|b| b.name() ++ "\n").join("")')
    fi
    existing_num=${existing%%${tab}*}; gh_base=${existing#*${tab}}
    # Base = the nearest ancestor that is itself a pushable change in the range;
    # none -> trunk. heads() picks the closest; first line covers the (rare)
    # merge-of-two-stacks case where GitHub still needs a single base.
    base_change=$(jj log --no-graph --no-pager \
                    -r "heads((::${cid}-) & ($range))" \
                    -T 'change_id.short() ++ "\n"' | head -n1)
    if [ -n "$base_change" ]; then
      # The ancestor was already planned (bottom -> top walk), so take its
      # resolved head — it may be an adopted bookmark, not the templated name.
      cur_base=""
      for s in "${heads_seen[@]}"; do
        [ "${s%%${tab}*}" = "$base_change" ] && { cur_base=${s#*${tab}}; break; }
      done
      [ -z "$cur_base" ] && cur_base=$(jj log --no-graph --no-pager -r "$base_change" -T "$tmpl")
    else
      cur_base="$base"
    fi
    # Stack membership, as "<stack>\t,<open PRs bottom -> top>," in stk_seen. A
    # stacked PR whose base must move marks its stack stale.
    snum=""
    if [ "$stacks_ok" -eq 1 ] && [ -n "$existing_num" ]; then
      for s in "${stk_seen[@]}"; do
        case "${s#*${tab}}" in *",$existing_num,"*) snum=${s%%${tab}*}; break ;; esac
      done
      if [ -z "$snum" ]; then
        s=$(gh api "repos/{owner}/{repo}/stacks?pull_request=$existing_num" \
              --jq '.[0] | select(.) | "\(.number)\t,\([.pull_requests[] | select(.state == "open") | .number | tostring] | join(",")),"') \
          || s=""
        [ -n "$s" ] && { snum=${s%%${tab}*}; stk_seen+=("$s"); }
      fi
      if [ -n "$snum" ]; then
        case "$touched" in *",$snum,"*) ;; *) touched="$touched$snum," ;; esac
        [ "$gh_base" != "$cur_base" ] && case "$stale" in *",$snum,"*) ;; *) stale="$stale$snum," ;; esac
      fi
    fi
    # Chain grouping, since GitHub stacks are strictly linear: a change joins
    # the chain holding its base change, and joining anywhere but that chain's
    # tail marks it branched. Row, bottom -> top: ,cids, TAB linear(1|0) TAB
    # ,PR numbers ("new" until created), TAB ,stacks touched, TAB labels.
    if [ "$stacks_ok" -eq 1 ]; then
      if [ -n "$existing_num" ]; then tok=$existing_num lbl="#$existing_num"; else tok=new lbl=$head; fi
      row=",$cid,${tab}1${tab},$tok,${tab},${snum:+$snum,}${tab}$lbl"
      tmp=()
      for r in "${chains[@]}"; do
        case "${r%%${tab}*}" in
          *",$base_change,"*)
            rcids=${r%%${tab}*};     rest=${r#*${tab}}
            linear=${rest%%${tab}*}; rest=${rest#*${tab}}
            toks=${rest%%${tab}*};   rest=${rest#*${tab}}
            hit=${rest%%${tab}*};    lbls=${rest#*${tab}}
            case "$rcids" in *",$base_change,") ;; *) linear=0 ;; esac
            [ -n "$snum" ] && case "$hit" in *",$snum,"*) ;; *) hit="$hit$snum," ;; esac
            row="$rcids$cid,$tab$linear$tab$toks$tok,$tab$hit$tab$lbls $lbl" ;;
          *) tmp+=("$r") ;;
        esac
      done
      chains=("${tmp[@]}" "$row")
    fi
    if [ -n "$existing_num" ]; then tag="update #$existing_num"; else tag="create"; fi
    heads_seen+=("$cid$tab$head")
    if [ "$reuse" -eq 1 ]; then push_args+=(-b "$head"); else push_args+=(-c "$cid"); fi
    plan+=("$cid$tab$head$tab$cur_base$tab$base_change$tab$existing_num$tab$gh_base$tab$reuse$tab$title")
    pline=$(printf '  %-15s %-22s → %-14s %s' "$tag" "$head" "$cur_base" "$title")
    [ "$reuse" -eq 1 ] && pline="${pline}  [existing bookmark]"
    preview="${pline}${nl}${preview}"
  done < <(jj log --no-graph --no-pager --reversed -r "$range" \
             -T 'change_id.short() ++ "\t" ++ description.first_line() ++ "\n"')

  if [ "${#plan[@]}" -eq 0 ]; then
    echo "jpr: no pushable changes in $range" >&2
    return 1
  fi

  # Stack actions per linear chain, against the one live (non-stale) stack it
  # touches, compared on open PRs (merged layers stay in a stack): keep when
  # the stack starts with the chain, add when the chain extends the stack.
  # Otherwise a chain of 2+ PRs gets a new stack and the live stacks it touches
  # are dissolved. Stale stacks are always dissolved.
  if [ "$stacks_ok" -eq 1 ]; then
    unstack=$stale
    for r in "${chains[@]}"; do
      rcids=${r%%${tab}*};     rest=${r#*${tab}}
      linear=${rest%%${tab}*}; rest=${rest#*${tab}}
      toks=${rest%%${tab}*};   rest=${rest#*${tab}}
      hit=${rest%%${tab}*};    lbls=${rest#*${tab}}
      if [ "$linear" -ne 1 ]; then
        stack_preview="$stack_preview$(printf '  %-15s %s' "none (branched)" "$lbls")$nl"
        continue
      fi
      live=","; rest=${hit#,}
      while [ -n "$rest" ]; do
        s=${rest%%,*}; rest=${rest#*,}
        case "$stale" in *",$s,"*) ;; *) live="$live$s," ;; esac
      done
      act=""; snum=""; sopen=""
      case "$live" in
        ,|,*,*,) ;;
        *)
          snum=${live#,}; snum=${snum%,}
          for s in "${stk_seen[@]}"; do
            [ "${s%%${tab}*}" = "$snum" ] && { sopen=${s#*${tab}}; break; }
          done
          case "$sopen" in "$toks"*) act=keep ;; esac
          [ -z "$act" ] && case "$toks" in "$sopen"*) act=add ;; esac ;;
      esac
      if [ -z "$act" ]; then
        case "$rcids" in ,*,*,) ;; *) continue ;; esac
        act=create
        rest=${live#,}
        while [ -n "$rest" ]; do
          s=${rest%%,*}; rest=${rest#*,}
          case "$unstack" in *",$s,"*) ;; *) unstack="$unstack$s," ;; esac
        done
      fi
      case "$act" in
        keep)
          pline="keep #$snum"
          rest=${sopen#"$toks"}; rest=${rest%,}
          [ -n "$rest" ] && lbls="$lbls (+#${rest//,/ #} above)" ;;
        add) pline="add to #$snum" ;;
        *)   pline="create" ;;
      esac
      stack_preview="$stack_preview$(printf '  %-15s %s' "$pline" "$lbls")$nl"
      stack_plan+=("$act$tab$snum$tab$rcids$tab$sopen")
    done
    rest=${unstack#,}
    while [ -n "$rest" ]; do
      snum=${rest%%,*}; rest=${rest#*,}; sopen=""
      for s in "${stk_seen[@]}"; do
        [ "${s%%${tab}*}" = "$snum" ] && { sopen=${s#*${tab}}; break; }
      done
      sopen=${sopen#,}; sopen=${sopen%,}
      stack_preview="$(printf '  %-15s #%s' "unstack #$snum" "${sopen//,/ #}")$nl$stack_preview"
    done
  fi

  # PREVIEW + CONFIRM, before anything touches the remote.
  if [ "$want_draft" -eq 1 ]; then fstate="draft"; else fstate="ready for review"; fi
  {
    printf 'jpr plan — top=%s, trunk base=%s, final state=%s\n' "$top" "$base" "$fstate"
    printf 'push %d branch(es), then create/update %d PR(s):\n' "${#plan[@]}" "${#plan[@]}"
    if [ "$no_footer" -eq 1 ]; then
      printf 'footer: suppressed (--no-footer)\n'
    elif [ "$excluded_marks" != "||" ]; then
      printf 'footer: excluding changes matching %s\n' "$no_footer_for"
    fi
    if [ "$no_stack" -eq 1 ]; then
      printf 'stacks: skipped (--no-stack)\n'
    elif [ "$stacks_ok" -ne 1 ] && [ "${#plan[@]}" -ge 2 ]; then
      printf 'stacks: unavailable for this repo\n'
    fi
    printf '%s' "$preview"
    if [ -n "$stack_preview" ]; then
      printf 'stacks (bottom → top):\n%s' "$stack_preview"
    fi
  } >&2
  if [ "$assume_yes" -ne 1 ]; then
    # Probe whether /dev/tty is actually openable (a bare `-r` test passes even
    # when there is no controlling terminal to open); only then prompt.
    if ( : </dev/tty ) 2>/dev/null; then
      printf 'Proceed? [y/N] ' >&2
      read -r reply </dev/tty || reply=""
    else
      echo "jpr: no TTY for confirmation; re-run with -y/--yes to proceed" >&2
      return 1
    fi
    case "$reply" in
      [yY]|[yY][eE][sS]) ;;
      *) echo "jpr: aborted" >&2; return 1 ;;
    esac
  fi

  # EXECUTION. Draft every already-existing PR *before* the push, so the new
  # commits land on a draft branch and can't notify reviewers (new PRs don't
  # exist until after the push, so they stay quiet either way). JPR_KEEP_READY
  # opts out, leaving ready PRs ready. Then push, then ensure a DRAFT PR per
  # change (bottom -> top, so a change's in-range parent already has a PR number
  # by the time we need it). `exec_seen` maps cid -> PR number for resolving each
  # child's base PR in the annotation; `display` records each PR's number, cid,
  # in-range base change, and title (top -> bottom).
  if [ -z "$JPR_KEEP_READY" ]; then
    for entry in "${plan[@]}"; do
      rest=${entry#*${tab}}; rest=${rest#*${tab}}   # drop cid, head
      rest=${rest#*${tab}}; rest=${rest#*${tab}}    # drop cur_base, base_change
      existing_num=${rest%%${tab}*}
      [ -n "$existing_num" ] && _pr_set_draft "$existing_num" 1
    done
  fi
  jj git push "${push_args[@]}" || return 1
  # GitHub won't retarget a stacked PR, so unstack before the PR pass.
  rest=${unstack#,}
  while [ -n "$rest" ]; do
    _jpr_unstack "${rest%%,*}"; rest=${rest#*,}
  done
  for entry in "${plan[@]}"; do
    cid=${entry%%${tab}*};         rest=${entry#*${tab}}
    head=${rest%%${tab}*};         rest=${rest#*${tab}}
    cur_base=${rest%%${tab}*};     rest=${rest#*${tab}}
    base_change=${rest%%${tab}*};  rest=${rest#*${tab}}
    existing_num=${rest%%${tab}*}; rest=${rest#*${tab}}
    gh_base=${rest%%${tab}*};      rest=${rest#*${tab}}
    reuse=${rest%%${tab}*};        title=${rest#*${tab}}
    # PR body = the change description minus its first line (the title) and the
    # blank lines that follow it. Recomputed every run so the PR tracks the
    # current `jj describe` text rather than whatever was filled at create time.
    body=$(jj log --no-graph --no-pager -r "$cid" -T 'description' \
             | sed -e '1d' -e '/./,$!d')
    if [ -n "$existing_num" ]; then
      num="$existing_num"
      # Already drafted in the pre-push pass (unless JPR_KEEP_READY), so this
      # edit's churn is quiet too. --base only when it moves: a PR still in a
      # (kept) stack rejects base edits.
      if [ "$gh_base" = "$cur_base" ]; then
        gh pr edit "$num" --title "$title" --body "$body" >/dev/null
      else
        gh pr edit "$num" --title "$title" --body "$body" --base "$cur_base" >/dev/null
      fi
    else
      gh pr create --draft --title "$title" --body "$body" --head "$head" --base "$cur_base" >/dev/null
      num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    fi
    nums+=("$num")
    display=("$num$tab$cid$tab$base_change$tab$title" "${display[@]}")
    exec_seen+=("$cid$tab$num")
  done

  # Link the planned stacks now that every PR exists. A rejected add (e.g. a
  # merged layer's branch is gone) falls back to unstack + create. Stacked
  # changes drop out of the footer map.
  hidden_marks=$excluded_marks
  for r in "${stack_plan[@]}"; do
    act=${r%%${tab}*};      rest=${r#*${tab}}
    snum=${rest%%${tab}*};  rest=${rest#*${tab}}
    rcids=${rest%%${tab}*}; sopen=${rest#*${tab}}
    csv=""; delta=""; rest=${rcids#,}
    while [ -n "$rest" ]; do
      c=${rest%%,*}; rest=${rest#*,}; n=""
      for s in "${exec_seen[@]}"; do
        [ "${s%%${tab}*}" = "$c" ] && { n=${s#*${tab}}; break; }
      done
      csv="$csv${csv:+,}$n"
      case "$sopen" in *",$n,"*) ;; *) delta="$delta${delta:+,}$n" ;; esac
    done
    case ",$csv," in *",,"*) echo "jpr: a PR is missing; not stacking $rcids" >&2; continue ;; esac
    if [ "$act" = add ] && ! gh api -X POST "repos/{owner}/{repo}/stacks/$snum/add" \
                               --input - >/dev/null <<<"{\"pull_requests\":[$delta]}"; then
      _jpr_unstack "$snum"; act=create
    fi
    if [ "$act" = create ]; then
      if out=$(gh api -X POST "repos/{owner}/{repo}/stacks" --input - --jq .number \
                 <<<"{\"pull_requests\":[$csv]}"); then
        snum=$out
      else
        echo "jpr: could not stack #${csv//,/ #}; falling back to the footer map" >&2
        continue
      fi
    fi
    hidden_marks="$hidden_marks${rcids//,/|}"
    stacks_done+=("$snum$tab#${csv//,/ #}")
  done

  # Annotate bodies with the relationship map, unless --no-footer drops it
  # wholesale (bodies then keep only the description; any stale map is already
  # gone, since the exec pass rewrote every body). Changes matched by
  # --no-footer-for, and stacked ones, are dropped from the map: each keeps its
  # own PR but gets no map of its own and is omitted from the others'. Matched
  # by PR number (no array indexing) so it is zsh/bash portable. A chain renders
  # as a stack with each PR's base; independent branches render as a related-PR
  # group.
  if [ "$no_footer" -ne 1 ]; then
    # First pass: collect the visible (non-excluded) PRs and, per visible change,
    # the PR number of its footer base — the nearest *visible* in-range ancestor,
    # empty meaning trunk. The walk hops over excluded ancestors using each
    # change's stored base change, so a child re-points past a hidden parent.
    vis=(); fmap=(); any_parent_vis=0
    for entry in "${display[@]}"; do
      num=${entry%%${tab}*};        rest=${entry#*${tab}}
      cid=${rest%%${tab}*};         rest=${rest#*${tab}}
      base_change=${rest%%${tab}*}
      case "$hidden_marks" in *"|$cid|"*) continue ;; esac
      vis+=("$num")
      bc="$base_change"
      while [ -n "$bc" ]; do
        case "$hidden_marks" in *"|$bc|"*) ;; *) break ;; esac
        nbc=""
        for e in "${display[@]}"; do
          ecid=${e#*${tab}}; ecid=${ecid%%${tab}*}            # field 2: cid
          if [ "$ecid" = "$bc" ]; then
            nbc=${e#*${tab}}; nbc=${nbc#*${tab}}; nbc=${nbc%%${tab}*}  # field 3: base change
            break
          fi
        done
        bc="$nbc"
      done
      fbase_num=""
      if [ -n "$bc" ]; then
        for s in "${exec_seen[@]}"; do
          [ "${s%%${tab}*}" = "$bc" ] && { fbase_num=${s#*${tab}}; break; }
        done
        [ -n "$fbase_num" ] && any_parent_vis=1
      fi
      fmap+=("$num$tab$fbase_num")
    done

    if [ "${#vis[@]}" -ge 2 ]; then
      if [ "$any_parent_vis" -eq 1 ]; then
        header="📚 **Stack** (top → bottom):"
      else
        header="📚 **Related PRs** (independent, based on \`$base\`):"
      fi
      for cur in "${vis[@]}"; do
        block="<!-- jstack -->${nl}---${nl}${header}${nl}"
        for entry in "${vis[@]}"; do
          # GitHub renders #<id> as the PR's (live) title, so the bare ref is enough.
          enum=$entry
          line="- #${enum}"
          if [ "$any_parent_vis" -eq 1 ]; then
            ebase=""
            for s in "${fmap[@]}"; do
              [ "${s%%${tab}*}" = "$enum" ] && { ebase=${s#*${tab}}; break; }
            done
            if [ -n "$ebase" ]; then line="${line} → #${ebase}"; else line="${line} → \`${base}\`"; fi
          fi
          [ "$enum" = "$cur" ] && line="${line} 👈"
          block="${block}${line}${nl}"
        done
        block="${block}<!-- /jstack -->"
        body=$(gh pr view "$cur" --json body --jq '.body // ""' \
                 | sed '/<!-- jstack -->/,/<!-- \/jstack -->/d')
        gh pr edit "$cur" --body "${body%$nl}${nl}${nl}${block}" >/dev/null
      done
    fi
  fi

  # Finalize: the one (possibly) notifying step, after the stack is consistent.
  for n in "${nums[@]}"; do
    _pr_set_draft "$n" "$want_draft"
  done
  for entry in "${display[@]}"; do
    num2=${entry%%${tab}*}
    etitle=${entry##*${tab}}               # title is the last field
    url=$(gh pr view "$num2" --json url --jq .url)
    printf '%s  #%s  %s\n' "$url" "$num2" "$etitle"
  done
  for s in "${stacks_done[@]}"; do
    printf 'stack #%s  %s\n' "${s%%${tab}*}" "${s#*${tab}}"
  done
}
