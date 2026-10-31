# workspace.closed hook: remove the tree of workspaces created by
# new-space.sh. The mapping is dropped on every close, so ids can never be
# confused with a later workspace; a guarded (unpushed) tree must be removed
# manually. Only unpushed commits reachable from the working copy are
# checked; abandoned local work outside ::@ is not.
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib.sh"

event="${HERDR_PLUGIN_EVENT_JSON:-}"
ws_id="$(printf '%s' "$event" | jq -r '.data.workspace_id // empty' 2>/dev/null || true)"
[[ -n "$ws_id" ]] || exit 0

mapping="$STATE/workspaces/$(session_key)/$ws_id"
[[ -f "$mapping" ]] || exit 0
name="$(<"$mapping")"
tree="$(trees_root)/$name"

rm -f "$mapping"

if [[ ! -d "$tree" ]]; then
    exit 0
fi

for repo_dir in "$tree"/*/; do
    repo="${repo_dir%/}"
    [[ -d "$repo/.jj" ]] || continue
    if ! unpushed="$(jj -R "$repo" log --no-graph -T 'commit_id.short() ++ "\n"' \
            -r '((::@ ~ ::remote_bookmarks()) ~ @) | (@ & ~empty())' 2>/dev/null)"; then
        "$herdr_bin" notification show "wt-spaces: kept '$name'" \
            --body "jj status check failed in ${repo##*/} — remove manually with: wt remove $name" \
            >/dev/null || true
        exit 0
    fi
    if [[ -n "$unpushed" ]]; then
        "$herdr_bin" notification show "wt-spaces: kept '$name'" \
            --body "unpushed commits in ${repo##*/} — push them, or remove the tree with: wt remove $name" \
            >/dev/null || true
        exit 0
    fi
done

bash "$WT_ROOT/scripts/wt.sh" remove "$name"
