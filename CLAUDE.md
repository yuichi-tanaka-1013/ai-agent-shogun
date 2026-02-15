# Mini Shogun

## Session Start

1. 役割確認: `cat instructions/{your_role}.md`
2. Inbox: `cat queue/inbox/{your_id}.yaml`
3. タスク: `cat queue/tasks/{your_id}.yaml`

## エージェント

| Agent | 役割 |
|-------|------|
| Shogun | 戦略決定（あなた） |
| Karo | 司令塔：タスク分解・配分 |
| Ashigaru1 | 実装担当 |

## 通信

```bash
# メッセージ送信
./mini-shogun write <target> "<message>" <type> <from>

# 例
./mini-shogun write karo "機能Xを実装せよ" cmd shogun
./mini-shogun write karo "完了" report ashigaru1
```

## Inbox処理

`inboxN` が届いたら:
1. `cat queue/inbox/{your_id}.yaml`
2. `read: false` を処理
3. Editで `read: true` に更新

## 指揮系統

```
Shogun → Karo → Ashigaru1
```

- Shogun⇔Ashigaru直接通信禁止
- ポーリング禁止（watcherがnudge送信）

## ファイル構成

```
mini-shogun/
├── mini-shogun          # CLI binary
├── start.zsh            # 起動
├── CLAUDE.md
├── instructions/
│   ├── karo.md
│   └── ashigaru.md
├── queue/
│   ├── inbox/*.yaml
│   └── tasks/*.yaml
└── dashboard.md
```
