# Interactive popup: create a wt worktree space (workspace.yaml group
# $WT_SPACES_GROUP, default 'herdr') and open it as a Herdr workspace.
# Closing that workspace removes the tree via on-workspace-closed.sh,
# unless the tree has unpushed commits.
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib.sh"

wt_sh="$WT_ROOT/scripts/wt.sh"
trees="$(trees_root)"

echo "New wt worktree space"
echo "  group: $group"
echo "  trees: $trees/"
printf 'Name (lowercase, digits, dashes): '
IFS= read -r name
if [[ -z "$name" ]]; then
    echo "No name given."
    exit 0
fi
if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "Invalid name: '$name' (use lowercase, digits, dashes)."
    exit 1
fi
if [[ -e "$trees/$name" ]]; then
    echo "$trees/$name already exists — pick another name or remove it first."
    exit 1
fi

printf 'Base branch [repo default]: '
IFS= read -r base
base_args=()
[[ -n "$base" ]] && base_args=(--base "$base")

echo
if ! bash "$wt_sh" new "$name" --group "$group" "${base_args[@]}"; then
    echo
    echo "wt new failed. Clean up with: wt remove '$name'"
    exit 1
fi

resp="$("$herdr_bin" workspace create --cwd "$trees/$name" --label "$name" --focus)"
ws_id="$(printf '%s' "$resp" | jq -r '.result.workspace.workspace_id // empty')"
if [[ -z "$ws_id" ]]; then
    echo "Tree created, but workspace creation failed:"
    printf '%s\n' "$resp"
    echo "Clean up with: wt remove '$name'"
    exit 1
fi

mapping_dir="$STATE/workspaces/$(session_key)"
mkdir -p "$mapping_dir"
printf '%s\n' "$name" > "$mapping_dir/$ws_id"

echo
echo "Workspace '$name' created ($ws_id)."
echo "Closing it in herdr removes $trees/$name;"
echo "trees with unpushed commits are kept and reported instead."
printf 'Press Enter to close this window.'
IFS= read -r _
