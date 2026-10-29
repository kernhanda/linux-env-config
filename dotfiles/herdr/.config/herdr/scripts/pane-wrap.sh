#!/bin/sh
# Wraparound directional focus for prefix+h / prefix+l. herdr's focus_pane_*
# stop at the tab edge; this script jumps to the opposite edge column instead.
# The ctrl+alt chords stay unwrapped.
#
# Custom command keybindings provide $HERDR_ACTIVE_PANE_ID and
# $HERDR_BIN_PATH; jq is required.
set -eu

dir=${1:?left|right}
case $dir in left|right) ;; *) echo "usage: $0 left|right" >&2; exit 2 ;; esac

h=${HERDR_BIN_PATH:-herdr}
cur=${HERDR_ACTIVE_PANE_ID:?not set}

touches=$("$h" pane edges --pane "$cur" | jq -r ".result.edges.$dir")
if [ "$touches" != true ]; then
    exec "$h" pane focus --direction "$dir" --pane "$cur"
fi

# At the tab edge: wrap to the opposite edge column (topmost on ties).
case $dir in
left)  pick='sort_by(-(.rect.x + .rect.width), .rect.y) | .[0].pane_id' ;;
right) pick='sort_by(.rect.x, .rect.y) | .[0].pane_id' ;;
esac
target=$("$h" pane layout --pane "$cur" | jq -r --arg cur "$cur" \
    "[.result.layout.panes[] | select(.pane_id != \$cur)] | $pick // empty")
[ -n "$target" ] || exit 0

# pane focus has no focus-by-id mode: step onto the target from its
# inward neighbor.
inward=$("$h" pane neighbor --pane "$target" --direction "$dir" \
    | jq -r '.result.neighbor.neighbor_pane_id // empty')
[ -n "$inward" ] || exit 0
opp=left; [ "$dir" = left ] && opp=right
exec "$h" pane focus --direction "$opp" --pane "$inward"
