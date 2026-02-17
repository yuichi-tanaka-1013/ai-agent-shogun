# AI Agent Shogun

## Session Start

1. 役割確認: `cat $AI_AGENT_SHOGUN_HOME/instructions/{your_role}.md`
2. Inbox: `cat .ai-agent-shogun/queue/inbox/{your_id}.yaml`
3. タスク: `cat .ai-agent-shogun/queue/tasks/{your_id}.yaml`

## 階層構造

```
殿 (Lord) ← 人間、最高意思決定者
    ↓
将軍 (Shogun) ← 戦略決定・全体統括
    ↓
家老 (Karo) ← 司令塔・タスク分解
    ↓
足軽1-4 (Ashigaru) ← 実装担当
```

| Agent | 役割 | Claude Code |
|-------|------|-------------|
| Lord | 殿：人間 | - |
| Shogun | 将軍：戦略決定 | Yes |
| Karo | 家老：タスク分解・配分 | Yes |
| Ashigaru1-4 | 足軽：実装担当 | Yes |

## 通信

```bash
# メッセージ送信
ai-agent-shogun write <target> "<message>" <type> <from>

# 例
ai-agent-shogun write shogun "新機能を実装せよ" cmd lord
ai-agent-shogun write karo "タスクA完了" cmd shogun
ai-agent-shogun write ashigaru1 "タスク割当" task_assigned karo
ai-agent-shogun write karo "完了報告" report ashigaru3
```

## Inbox処理

`inboxN` が届いたら:
1. `cat .ai-agent-shogun/queue/inbox/{your_id}.yaml`
2. `read: false` を処理
3. Editで `read: true` に更新（⚠️ 下記YAML注意事項参照）

## YAML編集時の注意（重要）

**YAMLファイルを直接編集する際、構文エラーでシステムが停止する可能性あり**

```yaml
# ❌ NG - コロン(:)を含む値はパースエラー
content: task_001: 実装せよ

# ✅ OK - シングルクォートで囲む
content: 'task_001: 実装せよ'
```

**推奨**: inbox への書き込みは `ai-agent-shogun write` コマンドを使用

## 指揮系統

```
Lord → Shogun → Karo → Ashigaru1-4
```

- 上位→下位のみ指示
- Ashigaru⇔Shogun直接通信禁止（必ずKaro経由）
- ポーリング禁止（watcherがnudge送信）

## ファイル構成

```
~/.ai-agent-shogun/              # ツールホーム（共通）
├── instructions/
│   ├── shogun.md
│   ├── karo.md
│   └── ashigaru.md
├── start.zsh
├── stop.zsh
└── CLAUDE.md

/path/to/your/project/           # 作業ディレクトリ
└── .ai-agent-shogun/            # プロジェクト固有データ
    ├── queue/
    │   ├── inbox/*.yaml         # メールボックス
    │   └── tasks/*.yaml         # タスク定義
    ├── logs/                    # ログ
    └── dashboard.md             # 進捗表示
```

## 環境変数

- `AI_AGENT_SHOGUN_HOME`: ツールホームディレクトリ（デフォルト: ~/.ai-agent-shogun）
- `AI_AGENT_SHOGUN_WORKDIR`: 作業ディレクトリ（デフォルト: カレントディレクトリ）
