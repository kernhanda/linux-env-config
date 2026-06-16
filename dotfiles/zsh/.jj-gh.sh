# jj + gh pull-request helpers.  Stowed to ~/.jj-gh.sh, sourced from .zshrc.
#
# Built for colocated jj checkouts, where git is permanently detached and
# `gh` therefore can't infer --head from a current branch. Branch names come
# from jj's own `templates.git_push_bookmark`, so they track that config.
#
#   jpr [REV] [-d|--draft] [extra gh pr create args...]
#       Single-commit PR for REV (default @). Idempotent: re-run after an
#       amend to re-push and re-sync state.
#
#   jstack [TOP] [-d|--draft]
#       One PR per commit in trunk()..TOP (default @), each based on the one
#       below it, and every PR body annotated with the stack map.
#
# Notifications: all create/base/body churn happens in draft; PRs are flipped
# to "ready for review" only once at the very end (unless -d), so reviewers
# get at most one notification per PR. Final state defaults to ready; export
# JPR_DRAFT=1 / JSTACK_DRAFT=1 to default to draft instead (matches the
# "all PRs are drafts" house rule). Written to run under both zsh and bash.

# Render the bookmark name jj would create for a revision, reusing the
# configured push template so this never drifts from jj config.
_jj_bookmark_for() {
  jj log --no-graph --no-pager -r "$1" \
    -T "$(jj config get templates.git_push_bookmark)"
}

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
  local rev="@" want_draft="${JPR_DRAFT:-0}"
  local -a gh_args
  gh_args=()
  [ $# -gt 0 ] && [ "${1#-}" = "$1" ] && { rev="$1"; shift; }
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--draft) want_draft=1 ;;
      *) gh_args+=("$1") ;;
    esac
    shift
  done

  jj git push -c "$rev" || return 1
  local head num
  head=$(_jj_bookmark_for "$rev")
  num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
  if [ -z "$num" ]; then                       # born as a draft
    gh pr create --draft --fill --head "$head" "${gh_args[@]}" >/dev/null || return 1
    num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
  fi
  _pr_set_draft "$num" "$want_draft"
  gh pr view "$num" --json url,isDraft --jq '"\(.url)  (draft: \(.isDraft))"'
}

jstack() {
  local top="@" want_draft="${JSTACK_DRAFT:-0}"
  [ $# -gt 0 ] && [ "${1#-}" = "$1" ] && { top="$1"; shift; }
  while [ $# -gt 0 ]; do
    case "$1" in -d|--draft) want_draft=1 ;; esac
    shift
  done

  local range="trunk()..$top" base="${JSTACK_BASE:-main}" tmpl
  local tab=$'\t' nl=$'\n'
  jj git push -c "$range" || return 1
  tmpl=$(jj config get templates.git_push_bookmark)

  # Pass 1: ensure a DRAFT PR per commit (bottom -> top). `display` pairs each
  # PR number with its title and is built top -> bottom by prepending.
  local -a nums display
  nums=(); display=()
  local cid title head num
  while IFS="$tab" read -r cid title; do
    [ -z "$cid" ] && continue
    head=$(jj log --no-graph --no-pager -r "$cid" -T "$tmpl")
    num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    if [ -n "$num" ]; then
      [ -z "$JSTACK_KEEP_READY" ] && _pr_set_draft "$num" 1   # quiet the churn
      gh pr edit "$num" --base "$base" >/dev/null
    else
      gh pr create --draft --fill --head "$head" --base "$base" >/dev/null
      num=$(gh pr list --head "$head" --state open --json number --jq '.[0].number // empty')
    fi
    nums+=("$num")
    display=("$num$tab$title" "${display[@]}")
    base="$head"
  done < <(jj log --no-graph --no-pager --reversed -r "$range" \
             -T 'change_id.short() ++ "\t" ++ description.first_line() ++ "\n"')

  # Pass 2: rewrite each body with the stack map, marking the current PR.
  # Matched by PR number (no array indexing) so it is zsh/bash portable.
  if [ "${#nums[@]}" -ge 2 ]; then
    local cur entry enum etitle body block
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
  local n
  for n in "${nums[@]}"; do
    _pr_set_draft "$n" "$want_draft"
  done
  local entry
  for entry in "${display[@]}"; do
    printf '#%s  %s\n' "${entry%%${tab}*}" "${entry#*${tab}}"
  done
}
