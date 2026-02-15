#!/bin/zsh
set -eu

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

echo "🏯 Mini Shogun 起動中..."

# Check dependencies
command -v fswatch &>/dev/null || { echo "❌ fswatch not found. brew install fswatch"; exit 1; }
command -v wezterm &>/dev/null || { echo "❌ wezterm CLI not found."; exit 1; }
command -v claude &>/dev/null || { echo "❌ claude CLI not found."; exit 1; }
[[ -f "./mini-shogun" ]] || { echo "❌ mini-shogun binary not found. Run: go build -o mini-shogun ."; exit 1; }

# Initialize inbox files
mkdir -p queue/inbox queue/tasks logs
for agent in shogun karo ashigaru1; do
    [[ -f "queue/inbox/${agent}.yaml" ]] || echo "messages: []" > "queue/inbox/${agent}.yaml"
done

# Store pane IDs
PANE_FILE="$SCRIPT_DIR/.pane_ids"
SHOGUN_PANE="${WEZTERM_PANE:-0}"
echo "shogun=$SHOGUN_PANE" > "$PANE_FILE"
echo "✅ Shogun pane: $SHOGUN_PANE"

# Create Karo pane
KARO_PANE=$(wezterm cli split-pane --right --percent 50)
echo "karo=$KARO_PANE" >> "$PANE_FILE"
echo "✅ Karo pane: $KARO_PANE"

# Create Ashigaru pane
ASHIGARU_PANE=$(wezterm cli split-pane --bottom --percent 50 --pane-id "$KARO_PANE")
echo "ashigaru1=$ASHIGARU_PANE" >> "$PANE_FILE"
echo "✅ Ashigaru1 pane: $ASHIGARU_PANE"

# Write agent ID files (for self-identification)
echo "karo" > "$SCRIPT_DIR/.agent_id_$KARO_PANE"
echo "ashigaru1" > "$SCRIPT_DIR/.agent_id_$ASHIGARU_PANE"

# Start Claude Code in Karo pane (skip permission prompts)
sleep 0.5
echo -e "cd $SCRIPT_DIR && claude --dangerously-skip-permissions\n" | wezterm cli send-text --no-paste --pane-id "$KARO_PANE"
echo "⏳ Karo Claude Code 起動待ち..."
sleep 5

# Send initial prompt to Karo
KARO_INIT="私はkaroです。cat instructions/karo.mdを実行して内容を確認し、家老として待機してください。"
wezterm cli send-text --pane-id "$KARO_PANE" "$KARO_INIT"
sleep 0.2
printf '\r' | wezterm cli send-text --no-paste --pane-id "$KARO_PANE"
echo "✅ Karo 初期化完了"

# Start Claude Code in Ashigaru pane (skip permission prompts)
sleep 1
echo -e "cd $SCRIPT_DIR && claude --dangerously-skip-permissions\n" | wezterm cli send-text --no-paste --pane-id "$ASHIGARU_PANE"
echo "⏳ Ashigaru Claude Code 起動待ち..."
sleep 5

# Send initial prompt to Ashigaru
ASHIGARU_INIT="私はashigaru1です。cat instructions/ashigaru.mdを実行して内容を確認し、足軽として待機してください。"
wezterm cli send-text --pane-id "$ASHIGARU_PANE" "$ASHIGARU_INIT"
sleep 0.2
printf '\r' | wezterm cli send-text --no-paste --pane-id "$ASHIGARU_PANE"
echo "✅ Ashigaru 初期化完了"

# Start watchers
sleep 2
nohup "$SCRIPT_DIR/mini-shogun" watch karo "$KARO_PANE" >> logs/watcher_karo.log 2>&1 &
nohup "$SCRIPT_DIR/mini-shogun" watch ashigaru1 "$ASHIGARU_PANE" >> logs/watcher_ashigaru1.log 2>&1 &
echo "👁️ Watchers started"

echo ""
echo "═══════════════════════════════════════════════"
echo "🏯 Mini Shogun 起動完了!"
echo "  Shogun: $SHOGUN_PANE | Karo: $KARO_PANE | Ashigaru1: $ASHIGARU_PANE"
echo ""
echo "📬 ./mini-shogun write karo \"メッセージ\" cmd shogun"
echo "🛑 pkill -f 'mini-shogun watch'"
echo "═══════════════════════════════════════════════"
