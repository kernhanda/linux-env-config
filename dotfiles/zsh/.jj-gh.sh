# jj + gh pull-request helper.  Stowed to ~/.jj-gh.sh, sourced from .zshrc.
#
# Built for colocated jj checkouts, where git is permanently detached and
# `gh` therefore can't infer --head from a current branch. Branch names come
# from jj's own `templates.git_push_bookmark`, so they track that config.
#
#   jpr [TOP] [-d|--draft] [--base BRANCH]
#       Create/refresh one draft PR per change in (trunk()..TOP) ~ empty()
#       (default TOP=@), each based on the one below it. The empty working-copy
#       change is dropped automatically, so a lone real change just makes one
#       PR. Every run resyncs each PR's title and body from its jj change
#       description, so re-running after `jj describe` keeps the PR text current
#       (jpr owns the description; edits made on GitHub are overwritten). With
#       2+ changes, every PR body is then annotated with the stack map.
#
# There is no separate single-PR vs stacked-PR command: in jj a single PR is
# just a one-deep stack, so jpr is the only verb.
#
# Notifications: all create/base/body churn happens in draft; PRs are flipped
# to "ready for review" only once at the very end (unless -d), so reviewers get
# at most one notification per PR. Final state defaults to ready; export
# JPR_DRAFT=1 to default to draft (matches the "all PRs are drafts" house rule).
# JPR_BASE overrides the bottom base branch (default main). JPR_KEEP_READY=1
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
  local top="@" want_draft="${JPR_DRAFT:-0}" base="${JPR_BASE:-main}"
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--draft)  want_draft=1 ;;
      --base)      shift; base="$1" ;;
      --base=*)    base="${1#--base=}" ;;
      -h|--help)   echo "usage: jpr [TOP] [-d|--draft] [--base BRANCH]"; return 0 ;;
      -*)          echo "jpr: unknown option: $1" >&2; return 2 ;;
      *)           top="$1" ;;
    esac
    shift
  done

  local range="(trunk()..$top) ~ empty()" tmpl
  local tab=$'\t' nl=$'\n'
  jj git push -c "$range" || return 1
  tmpl=$(jj config get templates.git_push_bookmark)

  # Pass 1: ensure a DRAFT PR per change (bottom -> top). `display` pairs each
  # PR number with its title and is built top -> bottom by prepending.
  local -a nums display
  nums=(); display=()
  # Declare every scalar local ONCE, here. Re-running `local NAME` on a name
  # that already holds a value makes zsh echo it (NAME=$'...'); only declared
  # once, never again below. `entry` lives here (not by its uses) because one
  # use is conditional and one is not — a lone `local entry` would either leak
  # to global or re-declare.
  local cid title head num body entry cur enum etitle block num2 url n
  while IFS="$tab" read -r cid title; do
    [ -z "$cid" ] && continue
    head=$(jj log --no-graph --no-pager -r "$cid" -T "$tmpl")
    # PR body = the change description minus its first line (the title) and the
    # blank lines that follow it. Recomputed every run so the PR tracks the
    # current `jj describe` text rather than whatever was filled at create time.
    body=$(jj log --no-graph --no-pager -r "$cid" -T 'description' \
             | sed -e '1d' -e '/./,$!d')
    num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    if [ -n "$num" ]; then
      [ -z "$JPR_KEEP_READY" ] && _pr_set_draft "$num" 1   # quiet the churn
      gh pr edit "$num" --title "$title" --body "$body" --base "$base" >/dev/null
    else
      gh pr create --draft --title "$title" --body "$body" --head "$head" --base "$base" >/dev/null
      num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    fi
    nums+=("$num")
    display=("$num$tab$title" "${display[@]}")
    base="$head"
  done < <(jj log --no-graph --no-pager --reversed -r "$range" \
             -T 'change_id.short() ++ "\t" ++ description.first_line() ++ "\n"')

  if [ "${#nums[@]}" -eq 0 ]; then
    echo "jpr: no pushable changes in $range" >&2
    return 1
  fi

  # Annotate bodies with the stack map only when it is actually a stack.
  # Matched by PR number (no array indexing) so it is zsh/bash portable.
  if [ "${#nums[@]}" -ge 2 ]; then
    for cur in "${nums[@]}"; do
      block="<!-- jstack -->${nl}---${nl}📚 **Stack** (top → bottom):${nl}"
      for entry in "${display[@]}"; do
        enum=${entry%%${tab}*}
        etitle=${entry#*${tab}}
        if [ "$enum" = "$cur" ]; then
          block="${block}- #${enum} ${etitle} 👈${nl}"
        else
          block="${block}- #${enum} ${etitle}${nl}"
        fi
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
    url=$(gh pr view "$num2" --json url --jq .url)
    printf '%s  #%s  %s\n' "$url" "$num2" "${entry#*${tab}}"
  done
}
