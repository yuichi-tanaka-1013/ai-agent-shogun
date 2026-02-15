#!/bin/zsh
set -eu

SCRIPT_DIR="${0:A:h}"
PANE_FILE="$SCRIPT_DIR/.pane_ids"

echo "🛑 Mini Shogun 停止中..."

# Stop watchers
pkill -f 'mini-shogun watch' 2>/dev/null && echo "✅ Watchers stopped" || echo "⚠️ No watchers running"

# Kill agent panes
if [[ -f "$PANE_FILE" ]]; then
    source "$PANE_FILE"
    [[ -n "${karo:-}" ]] && wezterm cli kill-pane --pane-id "$karo" 2>/dev/null && echo "✅ Karo pane closed"
    [[ -n "${ashigaru1:-}" ]] && wezterm cli kill-pane --pane-id "$ashigaru1" 2>/dev/null && echo "✅ Ashigaru pane closed"
    rm -f "$PANE_FILE"
fi

# Cleanup temp files
rm -f "$SCRIPT_DIR"/.agent_id_* 2>/dev/null || true

echo "🏯 Mini Shogun 停止完了"
