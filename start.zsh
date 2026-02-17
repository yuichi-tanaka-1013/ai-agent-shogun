#!/bin/zsh
set -eu

# HOME_DIR: Tool installation directory (instructions, binary)
# WORK_DIR: Project directory where agents work
HOME_DIR="${AI_AGENT_SHOGUN_HOME:-${0:A:h}}"
WORK_DIR="${AI_AGENT_SHOGUN_WORKDIR:-${PWD}}"
DATA_DIR="$WORK_DIR/.ai-agent-shogun"

echo "🏯 AI Agent Shogun 起動中..."
echo "📂 作業ディレクトリ: $WORK_DIR"
echo "📦 ホームディレクトリ: $HOME_DIR"

# Check dependencies
command -v fswatch &>/dev/null || { echo "❌ fswatch not found. brew install fswatch"; exit 1; }
command -v wezterm &>/dev/null || { echo "❌ wezterm CLI not found."; exit 1; }
command -v claude &>/dev/null || { echo "❌ claude CLI not found."; exit 1; }
command -v ai-agent-shogun &>/dev/null || { echo "❌ ai-agent-shogun not found in PATH. Run: make install"; exit 1; }

# Initialize data directory in work dir
mkdir -p "$DATA_DIR/queue/inbox" "$DATA_DIR/queue/tasks" "$DATA_DIR/logs"
AGENTS=(shogun karo ashigaru1 ashigaru2 ashigaru3 ashigaru4)
for agent in "${AGENTS[@]}"; do
    [[ -f "$DATA_DIR/queue/inbox/${agent}.yaml" ]] || echo "messages: []" > "$DATA_DIR/queue/inbox/${agent}.yaml"
done

# Initialize dashboard
if [[ ! -f "$DATA_DIR/dashboard.md" ]]; then
    cat > "$DATA_DIR/dashboard.md" << 'EOF'
# Dashboard

## 進捗状況

| タスク | 担当 | 状態 | 更新日時 |
|--------|------|------|----------|
| — | — | — | — |

## アクション待ち

なし

## 完了タスク

| タスク | 担当 | 完了日時 |
|--------|------|----------|
EOF
fi

# Save work directory for agents
echo "$WORK_DIR" > "$DATA_DIR/.work_dir"

# Store pane IDs
PANE_FILE="$DATA_DIR/.pane_ids"
LORD_PANE="${WEZTERM_PANE:-0}"
echo "lord=$LORD_PANE" > "$PANE_FILE"
echo "✅ Lord (殿) pane: $LORD_PANE"

# Function to start Claude Code agent
start_agent() {
    local pane_id=$1
    local agent_name=$2
    local instruction_file=$3

    # Write agent ID file
    echo "$agent_name" > "$DATA_DIR/.agent_id_$pane_id"

    # Start Claude Code in work directory
    echo -e "cd $WORK_DIR && export AI_AGENT_SHOGUN_HOME=$HOME_DIR && export AI_AGENT_SHOGUN_WORKDIR=$WORK_DIR && claude --dangerously-skip-permissions\n" | wezterm cli send-text --no-paste --pane-id "$pane_id"
    sleep 3

    # Auto-pass permission confirmation screen
    printf '\x1b[B' | wezterm cli send-text --no-paste --pane-id "$pane_id"
    sleep 0.3
    printf '\r' | wezterm cli send-text --no-paste --pane-id "$pane_id"
    sleep 3

    # Send initial prompt (instruction file is in HOME_DIR)
    local init_msg="私は${agent_name}です。cat ${HOME_DIR}/${instruction_file}を実行して内容を確認し、役割に従って待機してください。"
    wezterm cli send-text --pane-id "$pane_id" "$init_msg"
    sleep 0.2
    printf '\r' | wezterm cli send-text --no-paste --pane-id "$pane_id"

    echo "✅ $agent_name 初期化完了"
}

# Create panes layout:
# Lord | TOP:    Shogun | Ashigaru1 | Ashigaru2
#      | BOTTOM: Karo   | Ashigaru3 | Ashigaru4

# Create TOP pane (right of Lord, will hold Shogun + Ashigaru 1,2)
TOP_PANE=$(wezterm cli split-pane --right --percent 80)

# Create BOTTOM pane (below TOP, will hold Karo + Ashigaru 3,4)
BOTTOM_PANE=$(wezterm cli split-pane --bottom --percent 50 --pane-id "$TOP_PANE")

# TOP_PANE becomes Shogun (left side of TOP)
SHOGUN_PANE="$TOP_PANE"
echo "shogun=$SHOGUN_PANE" >> "$PANE_FILE"
echo "✅ Shogun pane: $SHOGUN_PANE"

# BOTTOM_PANE becomes Karo (left side of BOTTOM)
KARO_PANE="$BOTTOM_PANE"
echo "karo=$KARO_PANE" >> "$PANE_FILE"
echo "✅ Karo pane: $KARO_PANE"

# Create Ashigaru panes
ASHIGARU_PANES=()

# TOP-RIGHT: Ashigaru 1,2
A1_PANE=$(wezterm cli split-pane --right --percent 67 --pane-id "$SHOGUN_PANE")
A2_PANE=$(wezterm cli split-pane --right --percent 50 --pane-id "$A1_PANE")
ASHIGARU_PANES[1]="$A1_PANE"
ASHIGARU_PANES[2]="$A2_PANE"
echo "ashigaru1=$A1_PANE" >> "$PANE_FILE"
echo "ashigaru2=$A2_PANE" >> "$PANE_FILE"
echo "✅ TOP-RIGHT: Ashigaru1=$A1_PANE, Ashigaru2=$A2_PANE"

# BOTTOM-RIGHT: Ashigaru 3,4
A3_PANE=$(wezterm cli split-pane --right --percent 67 --pane-id "$KARO_PANE")
A4_PANE=$(wezterm cli split-pane --right --percent 50 --pane-id "$A3_PANE")
ASHIGARU_PANES[3]="$A3_PANE"
ASHIGARU_PANES[4]="$A4_PANE"
echo "ashigaru3=$A3_PANE" >> "$PANE_FILE"
echo "ashigaru4=$A4_PANE" >> "$PANE_FILE"
echo "✅ BOTTOM-RIGHT: Ashigaru3=$A3_PANE, Ashigaru4=$A4_PANE"

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

# Start Ashigaru 1-4
for i in {1..4}; do
    echo "⏳ Ashigaru$i 起動中..."
    start_agent "${ASHIGARU_PANES[$i]}" "ashigaru$i" "instructions/ashigaru.md"
    sleep 1
done

# Start watchers with environment variables
sleep 2
export AI_AGENT_SHOGUN_HOME="$HOME_DIR"
export AI_AGENT_SHOGUN_WORKDIR="$WORK_DIR"
WATCHER_PID_FILE="$DATA_DIR/.watcher_pids"
> "$WATCHER_PID_FILE"

# Rotate old watcher logs (keep previous as .prev)
for logfile in "$DATA_DIR"/logs/watcher_*.log; do
    [[ -f "$logfile" ]] || continue
    mv "$logfile" "${logfile}.prev"
done

nohup ai-agent-shogun watch shogun "$SHOGUN_PANE" >> "$DATA_DIR/logs/watcher_shogun.log" 2>&1 &
echo $! >> "$WATCHER_PID_FILE"
nohup ai-agent-shogun watch karo "$KARO_PANE" >> "$DATA_DIR/logs/watcher_karo.log" 2>&1 &
echo $! >> "$WATCHER_PID_FILE"
for i in {1..4}; do
    nohup ai-agent-shogun watch "ashigaru$i" "${ASHIGARU_PANES[$i]}" >> "$DATA_DIR/logs/watcher_ashigaru$i.log" 2>&1 &
    echo $! >> "$WATCHER_PID_FILE"
done
echo "👁️ Watchers started (6 agents, PIDs saved to $WATCHER_PID_FILE)"

echo ""
echo "═══════════════════════════════════════════════"
echo "🏯 AI Agent Shogun 起動完了! (6 Claude Code agents)"
echo ""
echo "階層構造:"
echo "  殿 (Lord): $LORD_PANE ← あなた"
echo "  将軍 (Shogun): $SHOGUN_PANE"
echo "  家老 (Karo): $KARO_PANE"
echo "  足軽 (Ashigaru): 1-4"
echo ""
echo "📬 Shogunに指示: ai-agent-shogun write shogun \"命令\" cmd lord"
echo "🛑 停止: ai-agent-shogun stop"
echo "═══════════════════════════════════════════════"
