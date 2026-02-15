# Mini Shogun

## Session Start

1. 役割確認: `cat instructions/{your_role}.md`
2. Inbox: `cat queue/inbox/{your_id}.yaml`
3. タスク: `cat queue/tasks/{your_id}.yaml`

## 階層構造

```
殿 (Lord) ← 人間、最高意思決定者
    ↓
将軍 (Shogun) ← 戦略決定・全体統括
    ↓
家老 (Karo) ← 司令塔・タスク分解
    ↓
足軽1-8 (Ashigaru) ← 実装担当
```

| Agent | 役割 | Claude Code |
|-------|------|-------------|
| Lord | 殿：人間 | ❌ |
| Shogun | 将軍：戦略決定 | ✅ |
| Karo | 家老：タスク分解・配分 | ✅ |
| Ashigaru1-8 | 足軽：実装担当 | ✅ |

## 通信

```bash
# メッセージ送信
./ai-agent-shogun write <target> "<message>" <type> <from>

# 例
./ai-agent-shogun write shogun "新機能を実装せよ" cmd lord
./ai-agent-shogun write karo "タスクA完了" cmd shogun
./ai-agent-shogun write ashigaru1 "タスク割当" task_assigned karo
./ai-agent-shogun write karo "完了報告" report ashigaru3
```

## Inbox処理

`inboxN` が届いたら:
1. `cat queue/inbox/{your_id}.yaml`
2. `read: false` を処理
3. Editで `read: true` に更新

## 指揮系統

```
Lord → Shogun → Karo → Ashigaru1-8
```

- 上位→下位のみ指示
- Ashigaru⇔Shogun直接通信禁止（必ずKaro経由）
- ポーリング禁止（watcherがnudge送信）

## ファイル構成

```
ai-agent-shogun/
├── ai-agent-shogun          # CLI binary
├── start.zsh            # 起動
├── stop.zsh             # 停止
├── CLAUDE.md
├── instructions/
│   ├── shogun.md
│   ├── karo.md
│   └── ashigaru.md
├── queue/
│   ├── inbox/*.yaml     # メールボックス
│   └── tasks/*.yaml     # タスク定義
└── dashboard.md         # 進捗表示
```
