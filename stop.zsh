#!/bin/zsh
set -eu

SCRIPT_DIR="${0:A:h}"
PANE_FILE="$SCRIPT_DIR/.pane_ids"

echo "🛑 Mini Shogun 停止中..."

# Stop watchers
pkill -f 'ai-agent-shogun watch' 2>/dev/null && echo "✅ Watchers stopped" || echo "⚠️ No watchers running"

# Kill agent panes
if [[ -f "$PANE_FILE" ]]; then
    source "$PANE_FILE"

    # Kill Shogun pane
    [[ -n "${shogun:-}" ]] && wezterm cli kill-pane --pane-id "$shogun" 2>/dev/null && echo "✅ Shogun pane closed"

    # Kill Karo pane
    [[ -n "${karo:-}" ]] && wezterm cli kill-pane --pane-id "$karo" 2>/dev/null && echo "✅ Karo pane closed"

    # Kill Ashigaru panes 1-8
    for i in {1..8}; do
        var="ashigaru$i"
        [[ -n "${(P)var:-}" ]] && wezterm cli kill-pane --pane-id "${(P)var}" 2>/dev/null && echo "✅ Ashigaru$i pane closed"
    done

    rm -f "$PANE_FILE"
fi

# Cleanup temp files
rm -f "$SCRIPT_DIR"/.agent_id_* 2>/dev/null || true

echo "🏯 Mini Shogun 停止完了"
