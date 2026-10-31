# wt-spaces.new action: open the new-space popup (manifest placement).
set -euo pipefail
exec "${HERDR_BIN_PATH:-herdr}" plugin pane open --plugin wt-spaces --entrypoint new
