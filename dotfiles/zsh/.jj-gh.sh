# jj + gh pull-request helper.  Stowed to ~/.jj-gh.sh, sourced from .zshrc.
#
# Built for colocated jj checkouts, where git is permanently detached and
# `gh` therefore can't infer --head from a current branch. Branch names come
# from jj's own `templates.git_push_bookmark`, so they track that config.
#
#   jpr [TOP] [-d|--draft] [-y|--yes] [--base BRANCH] [--no-footer] [--no-footer-for REVSET]
#       Create/refresh one draft PR per non-empty change in (trunk()..TOP)
#       (default TOP=@). Each PR is based on its *actual* parent: a change's
#       base is the branch of its nearest ancestor that is itself a pushable
#       change in the range, or the trunk branch (--base / JPR_BASE, default
#       main) when it has no such ancestor. So a linear stack chains, and
#       parallel branches each target trunk — e.g. three sibling changes joined
#       by an empty merge produce three independent PRs against main, not a fake
#       linear chain. Empty changes (the working copy, merge nodes) are dropped,
#       so a lone real change just makes one PR. Every run resyncs each PR's
#       title and body from its jj change description, so re-running after
#       `jj describe` keeps the PR text current (jpr owns the description; edits
#       made on GitHub are overwritten). With 2+ changes, every PR body is then
#       annotated with the relationship map (a stack when changes chain, a
#       related-PR group when they are independent).
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
#       jpr first prints the plan (which branches it will push, and which PRs it
#       will create vs update, with their bases) and asks for confirmation
#       before touching the remote. Nothing is pushed or edited until you
#       confirm. -y/--yes (or JPR_YES=1) skips the prompt; with no TTY and no
#       -y, jpr refuses to proceed.
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
# --no-footer-for revset. Written to run under both zsh and bash.

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

jpr() {
  local top="@" want_draft="${JPR_DRAFT:-0}" base="${JPR_BASE:-main}" assume_yes="${JPR_YES:-0}" \
        no_footer="${JPR_NO_FOOTER:-0}" no_footer_for="${JPR_NO_FOOTER_FOR:-}"
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--draft)  want_draft=1 ;;
      -y|--yes)    assume_yes=1 ;;
      --base)      shift; base="$1" ;;
      --base=*)    base="${1#--base=}" ;;
      --no-footer) no_footer=1 ;;
      --no-footer-for)   shift; no_footer_for="$1" ;;
      --no-footer-for=*) no_footer_for="${1#--no-footer-for=}" ;;
      -h|--help)   echo "usage: jpr [TOP] [-d|--draft] [-y|--yes] [--base BRANCH] [--no-footer] [--no-footer-for REVSET]"; return 0 ;;
      -*)          echo "jpr: unknown option: $1" >&2; return 2 ;;
      *)           top="$1" ;;
    esac
    shift
  done

  # `base` is the trunk branch and is never reassigned: each change computes its
  # own base from its parent, so it must not leak into the next iteration.
  local range="(trunk()..$top) ~ empty()" tmpl
  local tab=$'\t' nl=$'\n'
  tmpl=$(jj config get templates.git_push_bookmark)

  local -a plan nums display exec_seen vis fmap
  plan=(); nums=(); display=(); exec_seen=()
  # Declare every scalar local ONCE, here. Re-running `local NAME` on a name
  # that already holds a value makes zsh echo it (NAME=$'...'); declared once,
  # never again below — assign (without `local`) wherever needed.
  local cid title head base_change cur_base existing_num tag pline preview \
        fstate reply entry rest s body num cur enum ebase etitle line header \
        block num2 url n excluded excluded_cids excluded_marks any_parent_vis \
        bc nbc ecid e fbase_num

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

  # PLANNING (read-only): no push, no PR create/edit. Walk the changes in
  # topological order and resolve, per change: its branch, its PR base, and
  # whether a PR already exists (update) or not (create). `plan` is built
  # bottom -> top (execution order); `preview` is built top -> bottom for the
  # human. base/branch resolution is pure jj, so it needs neither the push nor
  # any existing PR — only the create-vs-update check hits the network.
  while IFS="$tab" read -r cid title; do
    [ -z "$cid" ] && continue
    head=$(jj log --no-graph --no-pager -r "$cid" -T "$tmpl")
    # Base = the nearest ancestor that is itself a pushable change in the range;
    # none -> trunk. heads() picks the closest; first line covers the (rare)
    # merge-of-two-stacks case where GitHub still needs a single base.
    base_change=$(jj log --no-graph --no-pager \
                    -r "heads((::${cid}-) & ($range))" \
                    -T 'change_id.short() ++ "\n"' | head -n1)
    if [ -n "$base_change" ]; then
      cur_base=$(jj log --no-graph --no-pager -r "$base_change" -T "$tmpl")
    else
      cur_base="$base"
    fi
    existing_num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    if [ -n "$existing_num" ]; then tag="update #$existing_num"; else tag="create"; fi
    plan+=("$cid$tab$head$tab$cur_base$tab$base_change$tab$existing_num$tab$title")
    pline=$(printf '  %-15s %-22s → %-14s %s' "$tag" "$head" "$cur_base" "$title")
    preview="${pline}${nl}${preview}"
  done < <(jj log --no-graph --no-pager --reversed -r "$range" \
             -T 'change_id.short() ++ "\t" ++ description.first_line() ++ "\n"')

  if [ "${#plan[@]}" -eq 0 ]; then
    echo "jpr: no pushable changes in $range" >&2
    return 1
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
    printf '%s' "$preview"
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
  # in-range base change, footer-excluded flag, and title (top -> bottom).
  if [ -z "$JPR_KEEP_READY" ]; then
    for entry in "${plan[@]}"; do
      rest=${entry#*${tab}}; rest=${rest#*${tab}}   # drop cid, head
      rest=${rest#*${tab}}; rest=${rest#*${tab}}    # drop cur_base, base_change
      existing_num=${rest%%${tab}*}
      [ -n "$existing_num" ] && _pr_set_draft "$existing_num" 1
    done
  fi
  jj git push -c "$range" || return 1
  for entry in "${plan[@]}"; do
    cid=${entry%%${tab}*};         rest=${entry#*${tab}}
    head=${rest%%${tab}*};         rest=${rest#*${tab}}
    cur_base=${rest%%${tab}*};     rest=${rest#*${tab}}
    base_change=${rest%%${tab}*};  rest=${rest#*${tab}}
    existing_num=${rest%%${tab}*}; title=${rest#*${tab}}
    case "$excluded_marks" in *"|$cid|"*) excluded=1 ;; *) excluded=0 ;; esac
    # PR body = the change description minus its first line (the title) and the
    # blank lines that follow it. Recomputed every run so the PR tracks the
    # current `jj describe` text rather than whatever was filled at create time.
    body=$(jj log --no-graph --no-pager -r "$cid" -T 'description' \
             | sed -e '1d' -e '/./,$!d')
    if [ -n "$existing_num" ]; then
      num="$existing_num"
      # Already drafted in the pre-push pass (unless JPR_KEEP_READY), so this
      # edit's churn is quiet too.
      gh pr edit "$num" --title "$title" --body "$body" --base "$cur_base" >/dev/null
    else
      gh pr create --draft --title "$title" --body "$body" --head "$head" --base "$cur_base" >/dev/null
      num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    fi
    nums+=("$num")
    display=("$num$tab$cid$tab$base_change$tab$excluded$tab$title" "${display[@]}")
    exec_seen+=("$cid$tab$num")
  done

  # Annotate bodies with the relationship map, unless --no-footer drops it
  # wholesale (bodies then keep only the description; any stale map is already
  # gone, since the exec pass rewrote every body). Changes matched by
  # --no-footer-for are dropped from the map: each keeps its own PR but gets no
  # map of its own and is omitted from the others'. Matched by PR number (no
  # array indexing) so it is zsh/bash portable. A chain renders as a stack with
  # each PR's base; independent branches render as a related-PR group.
  if [ "$no_footer" -ne 1 ]; then
    # First pass: collect the visible (non-excluded) PRs and, per visible change,
    # the PR number of its footer base — the nearest *visible* in-range ancestor,
    # empty meaning trunk. The walk hops over excluded ancestors using each
    # change's stored base change, so a child re-points past a hidden parent.
    vis=(); fmap=(); any_parent_vis=0
    for entry in "${display[@]}"; do
      num=${entry%%${tab}*};        rest=${entry#*${tab}}
      cid=${rest%%${tab}*};         rest=${rest#*${tab}}
      base_change=${rest%%${tab}*}; rest=${rest#*${tab}}
      excluded=${rest%%${tab}*}
      [ "$excluded" = "1" ] && continue
      vis+=("$num")
      bc="$base_change"
      while [ -n "$bc" ]; do
        case "$excluded_marks" in *"|$bc|"*) ;; *) break ;; esac
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
}
