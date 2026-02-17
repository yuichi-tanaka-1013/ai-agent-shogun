#!/bin/zsh
set -eu

# HOME_DIR: Tool installation directory
# WORK_DIR: Project directory where agents work
HOME_DIR="${AI_AGENT_SHOGUN_HOME:-${0:A:h}}"
WORK_DIR="${AI_AGENT_SHOGUN_WORKDIR:-${PWD}}"
DATA_DIR="$WORK_DIR/.ai-agent-shogun"
PANE_FILE="$DATA_DIR/.pane_ids"

echo "🛑 AI Agent Shogun 停止中..."
echo "📂 作業ディレクトリ: $WORK_DIR"

# Stop watchers using PID file
WATCHER_PID_FILE="$DATA_DIR/.watcher_pids"
if [[ -f "$WATCHER_PID_FILE" ]]; then
    while read -r pid; do
        [[ -n "$pid" ]] && kill "$pid" 2>/dev/null
    done < "$WATCHER_PID_FILE"
    rm -f "$WATCHER_PID_FILE"
    echo "✅ Watchers stopped (PID file)"
else
    # Fallback: pkill if PID file is missing
    pkill -f 'ai-agent-shogun watch' 2>/dev/null && echo "✅ Watchers stopped (pkill fallback)" || echo "⚠️ No watchers running"
fi

# Kill agent panes
if [[ -f "$PANE_FILE" ]]; then
    source "$PANE_FILE"

    # Kill Shogun pane
    [[ -n "${shogun:-}" ]] && wezterm cli kill-pane --pane-id "$shogun" 2>/dev/null && echo "✅ Shogun pane closed"

    # Kill Karo pane
    [[ -n "${karo:-}" ]] && wezterm cli kill-pane --pane-id "$karo" 2>/dev/null && echo "✅ Karo pane closed"

    # Kill Ashigaru panes 1-4
    for i in {1..4}; do
        var="ashigaru$i"
        [[ -n "${(P)var:-}" ]] && wezterm cli kill-pane --pane-id "${(P)var}" 2>/dev/null && echo "✅ Ashigaru$i pane closed"
    done

    rm -f "$PANE_FILE"
fi

# Cleanup temp files
rm -f "$DATA_DIR"/.agent_id_* 2>/dev/null || true

echo "🏯 AI Agent Shogun 停止完了"
