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
AGENTS=(shogun karo ashigaru1 ashigaru2 ashigaru3 ashigaru4 ashigaru5 ashigaru6 ashigaru7 ashigaru8)
for agent in "${AGENTS[@]}"; do
    [[ -f "queue/inbox/${agent}.yaml" ]] || echo "messages: []" > "queue/inbox/${agent}.yaml"
done

# Store pane IDs
PANE_FILE="$SCRIPT_DIR/.pane_ids"
LORD_PANE="${WEZTERM_PANE:-0}"
echo "lord=$LORD_PANE" > "$PANE_FILE"
echo "✅ Lord (殿) pane: $LORD_PANE"

# Function to start Claude Code agent
start_agent() {
    local pane_id=$1
    local agent_name=$2
    local instruction_file=$3

    # Write agent ID file
    echo "$agent_name" > "$SCRIPT_DIR/.agent_id_$pane_id"

    # Start Claude Code
    echo -e "cd $SCRIPT_DIR && claude --dangerously-skip-permissions\n" | wezterm cli send-text --no-paste --pane-id "$pane_id"
    sleep 3

    # Auto-pass permission confirmation screen
    printf '\x1b[B' | wezterm cli send-text --no-paste --pane-id "$pane_id"
    sleep 0.3
    printf '\r' | wezterm cli send-text --no-paste --pane-id "$pane_id"
    sleep 3

    # Send initial prompt
    local init_msg="私は${agent_name}です。cat ${instruction_file}を実行して内容を確認し、役割に従って待機してください。"
    wezterm cli send-text --pane-id "$pane_id" "$init_msg"
    sleep 0.2
    printf '\r' | wezterm cli send-text --no-paste --pane-id "$pane_id"

    echo "✅ $agent_name 初期化完了"
}

# Create panes layout:
# Lord | Shogun | Karo
#      |        | Ashigaru1 | Ashigaru2
#      |        | Ashigaru3 | Ashigaru4
#      |        | Ashigaru5 | Ashigaru6
#      |        | Ashigaru7 | Ashigaru8

# Create Shogun pane (right of Lord)
SHOGUN_PANE=$(wezterm cli split-pane --right --percent 80)
echo "shogun=$SHOGUN_PANE" >> "$PANE_FILE"
echo "✅ Shogun pane: $SHOGUN_PANE"

# Create Karo pane (right of Shogun)
KARO_PANE=$(wezterm cli split-pane --right --percent 75 --pane-id "$SHOGUN_PANE")
echo "karo=$KARO_PANE" >> "$PANE_FILE"
echo "✅ Karo pane: $KARO_PANE"

# Create Ashigaru panes (below Karo, in pairs)
ASHIGARU_PANES=()

# Row 1: Ashigaru 1-2
A1_PANE=$(wezterm cli split-pane --bottom --percent 80 --pane-id "$KARO_PANE")
A2_PANE=$(wezterm cli split-pane --right --percent 50 --pane-id "$A1_PANE")
ASHIGARU_PANES+=("$A1_PANE" "$A2_PANE")
echo "ashigaru1=$A1_PANE" >> "$PANE_FILE"
echo "ashigaru2=$A2_PANE" >> "$PANE_FILE"
echo "✅ Ashigaru1 pane: $A1_PANE, Ashigaru2 pane: $A2_PANE"

# Row 2: Ashigaru 3-4
A3_PANE=$(wezterm cli split-pane --bottom --percent 75 --pane-id "$A1_PANE")
A4_PANE=$(wezterm cli split-pane --right --percent 50 --pane-id "$A3_PANE")
ASHIGARU_PANES+=("$A3_PANE" "$A4_PANE")
echo "ashigaru3=$A3_PANE" >> "$PANE_FILE"
echo "ashigaru4=$A4_PANE" >> "$PANE_FILE"
echo "✅ Ashigaru3 pane: $A3_PANE, Ashigaru4 pane: $A4_PANE"

# Row 3: Ashigaru 5-6
A5_PANE=$(wezterm cli split-pane --bottom --percent 66 --pane-id "$A3_PANE")
A6_PANE=$(wezterm cli split-pane --right --percent 50 --pane-id "$A5_PANE")
ASHIGARU_PANES+=("$A5_PANE" "$A6_PANE")
echo "ashigaru5=$A5_PANE" >> "$PANE_FILE"
echo "ashigaru6=$A6_PANE" >> "$PANE_FILE"
echo "✅ Ashigaru5 pane: $A5_PANE, Ashigaru6 pane: $A6_PANE"

# Row 4: Ashigaru 7-8
A7_PANE=$(wezterm cli split-pane --bottom --percent 50 --pane-id "$A5_PANE")
A8_PANE=$(wezterm cli split-pane --right --percent 50 --pane-id "$A7_PANE")
ASHIGARU_PANES+=("$A7_PANE" "$A8_PANE")
echo "ashigaru7=$A7_PANE" >> "$PANE_FILE"
echo "ashigaru8=$A8_PANE" >> "$PANE_FILE"
echo "✅ Ashigaru7 pane: $A7_PANE, Ashigaru8 pane: $A8_PANE"

echo ""
echo "🚀 Claude Code エージェント起動開始..."
echo ""

# Start Shogun
echo "⏳ Shogun 起動中..."
start_agent "$SHOGUN_PANE" "shogun" "instructions/shogun.md"
sleep 1

# Start Karo
echo "⏳ Karo 起動中..."
start_agent "$KARO_PANE" "karo" "instructions/karo.md"
sleep 1

# Start Ashigaru 1-8
for i in {1..8}; do
    echo "⏳ Ashigaru$i 起動中..."
    start_agent "${ASHIGARU_PANES[$i]}" "ashigaru$i" "instructions/ashigaru.md"
    sleep 1
done

# Start watchers
sleep 2
nohup "$SCRIPT_DIR/mini-shogun" watch shogun "$SHOGUN_PANE" >> logs/watcher_shogun.log 2>&1 &
nohup "$SCRIPT_DIR/mini-shogun" watch karo "$KARO_PANE" >> logs/watcher_karo.log 2>&1 &
for i in {1..8}; do
    nohup "$SCRIPT_DIR/mini-shogun" watch "ashigaru$i" "${ASHIGARU_PANES[$i]}" >> "logs/watcher_ashigaru$i.log" 2>&1 &
done
echo "👁️ Watchers started (10 agents)"

echo ""
echo "═══════════════════════════════════════════════"
echo "🏯 Mini Shogun 起動完了! (10 Claude Code agents)"
echo ""
echo "階層構造:"
echo "  殿 (Lord): $LORD_PANE ← あなた"
echo "  将軍 (Shogun): $SHOGUN_PANE"
echo "  家老 (Karo): $KARO_PANE"
echo "  足軽 (Ashigaru): 1-8"
echo ""
echo "📬 Shogunに指示: ./mini-shogun write shogun \"命令\" cmd lord"
echo "🛑 停止: make stop"
echo "═══════════════════════════════════════════════"
