# jj + gh pull-request helper.  Stowed to ~/.jj-gh.sh, sourced from .zshrc.
#
# Built for colocated jj checkouts, where git is permanently detached and
# `gh` therefore can't infer --head from a current branch. Branch names come
# from jj's own `templates.git_push_bookmark`, so they track that config.
#
#   jpr [TOP] [-d|--draft] [-y|--yes] [--base BRANCH]
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
#       jpr first prints the plan (which branches it will push, and which PRs it
#       will create vs update, with their bases) and asks for confirmation
#       before touching the remote. Nothing is pushed or edited until you
#       confirm. -y/--yes (or JPR_YES=1) skips the prompt; with no TTY and no
#       -y, jpr refuses to proceed.
#
# There is no separate single-PR vs stacked-PR command: in jj a single PR is
# just a one-deep stack, so jpr is the only verb.
#
# Notifications: all create/base/body churn happens in draft; PRs are flipped
# to "ready for review" only once at the very end (unless -d), so reviewers get
# at most one notification per PR. Final state defaults to ready; export
# JPR_DRAFT=1 to default to draft (matches the "all PRs are drafts" house rule).
# JPR_BASE overrides the trunk base branch (default main). JPR_KEEP_READY=1
# leaves already-ready PRs alone instead of force-drafting them during edits.
# Written to run under both zsh and bash.

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
  local top="@" want_draft="${JPR_DRAFT:-0}" base="${JPR_BASE:-main}" assume_yes="${JPR_YES:-0}"
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--draft)  want_draft=1 ;;
      -y|--yes)    assume_yes=1 ;;
      --base)      shift; base="$1" ;;
      --base=*)    base="${1#--base=}" ;;
      -h|--help)   echo "usage: jpr [TOP] [-d|--draft] [-y|--yes] [--base BRANCH]"; return 0 ;;
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

  local -a plan nums display exec_seen
  plan=(); nums=(); display=(); exec_seen=()
  # Declare every scalar local ONCE, here. Re-running `local NAME` on a name
  # that already holds a value makes zsh echo it (NAME=$'...'); declared once,
  # never again below. `any_parent` is initialized here (not later) so its
  # `local` doesn't reset it.
  local cid title head base_change cur_base existing_num tag pline preview \
        fstate reply entry rest s body base_num num cur enum ebase etitle \
        line header block num2 url n any_parent=0

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
      any_parent=1
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

  # EXECUTION. Push the bookmarks, then ensure a DRAFT PR per change (bottom ->
  # top, so a change's in-range parent already has a PR number by the time we
  # need it). `exec_seen` maps cid -> PR number for resolving each child's base
  # PR in the annotation; `display` pairs each PR with its base PR and title,
  # built top -> bottom by prepending.
  jj git push -c "$range" || return 1
  for entry in "${plan[@]}"; do
    cid=${entry%%${tab}*};         rest=${entry#*${tab}}
    head=${rest%%${tab}*};         rest=${rest#*${tab}}
    cur_base=${rest%%${tab}*};     rest=${rest#*${tab}}
    base_change=${rest%%${tab}*};  rest=${rest#*${tab}}
    existing_num=${rest%%${tab}*}; title=${rest#*${tab}}
    base_num=""
    if [ -n "$base_change" ]; then
      for s in "${exec_seen[@]}"; do
        [ "${s%%${tab}*}" = "$base_change" ] && { base_num=${s#*${tab}}; break; }
      done
    fi
    # PR body = the change description minus its first line (the title) and the
    # blank lines that follow it. Recomputed every run so the PR tracks the
    # current `jj describe` text rather than whatever was filled at create time.
    body=$(jj log --no-graph --no-pager -r "$cid" -T 'description' \
             | sed -e '1d' -e '/./,$!d')
    if [ -n "$existing_num" ]; then
      num="$existing_num"
      [ -z "$JPR_KEEP_READY" ] && _pr_set_draft "$num" 1   # quiet the churn
      gh pr edit "$num" --title "$title" --body "$body" --base "$cur_base" >/dev/null
    else
      gh pr create --draft --title "$title" --body "$body" --head "$head" --base "$cur_base" >/dev/null
      num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    fi
    nums+=("$num")
    display=("$num$tab$base_num$tab$title" "${display[@]}")
    exec_seen+=("$cid$tab$num")
  done

  # Annotate bodies with the relationship map only when there are 2+ PRs.
  # Matched by PR number (no array indexing) so it is zsh/bash portable. A chain
  # renders as a stack with each PR's base shown; independent branches render as
  # a related-PR group (all share the trunk base, so per-line bases are noise).
  if [ "${#nums[@]}" -ge 2 ]; then
    if [ "$any_parent" -eq 1 ]; then
      header="📚 **Stack** (top → bottom):"
    else
      header="📚 **Related PRs** (independent, based on \`$base\`):"
    fi
    for cur in "${nums[@]}"; do
      block="<!-- jstack -->${nl}---${nl}${header}${nl}"
      for entry in "${display[@]}"; do
        enum=${entry%%${tab}*}
        rest=${entry#*${tab}}              # base_num<TAB>title
        ebase=${rest%%${tab}*}
        etitle=${rest#*${tab}}
        line="- #${enum} ${etitle}"
        if [ "$any_parent" -eq 1 ]; then
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

  # Finalize: the one (possibly) notifying step, after the stack is consistent.
  for n in "${nums[@]}"; do
    _pr_set_draft "$n" "$want_draft"
  done
  for entry in "${display[@]}"; do
    num2=${entry%%${tab}*}
    rest=${entry#*${tab}}                  # base_num<TAB>title
    etitle=${rest#*${tab}}
    url=$(gh pr view "$num2" --json url --jq .url)
    printf '%s  #%s  %s\n' "$url" "$num2" "$etitle"
  done
}
