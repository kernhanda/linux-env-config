# Shared helpers for wt-spaces plugin commands.
#
# The wt workspace lives in its own repo (~/.work on this machine); the plugin
# is installed from the dotfiles repo, hence the WT_WORKSPACE_ROOT indirection.

WT_ROOT="${WT_WORKSPACE_ROOT:-$HOME/work}"
herdr_bin="${HERDR_BIN_PATH:-herdr}"
group="${WT_SPACES_GROUP:-herdr}"
: "${HERDR_PLUGIN_STATE_DIR:?HERDR_PLUGIN_STATE_DIR not set — run as a herdr plugin command}"
STATE="$HERDR_PLUGIN_STATE_DIR"

trees_root() {
    local raw
    raw="$(yq -r '.trees // "~/.work/trees"' "$WT_ROOT/workspace.yaml" 2>/dev/null || echo '~/.work/trees')"
    case "$raw" in
        '~'/*) echo "${HOME}/${raw#\~/}" ;;
        /*)    echo "$raw" ;;
        *)     echo "$WT_ROOT/$raw" ;;
    esac
}

# Workspace ids repeat across herdr sessions; scope the id->tree mapping by
# the session socket so a w1 in one session can't delete another session's tree.
session_key() {
    printf '%s' "${HERDR_SOCKET_PATH:-}" | sha256sum | cut -c1-16
}
