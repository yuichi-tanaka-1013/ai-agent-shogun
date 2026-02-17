# AI Agent Shogun

複数のClaude Codeエージェントを階層的に連携させるマルチエージェントシステム。

## 概要

AI Agent Shogunは、将軍（Shogun）・家老（Karo）・足軽（Ashigaru）の3層構造でClaude Codeエージェントを統率するシステムです。YAMLベースのメッセージキューとファイル監視により、エージェント間の非同期通信を実現します。

### エージェント構成（6エージェント）

| エージェント | 役割 |
|-------------|------|
| **Shogun** | 戦略決定。ユーザー（殿）からの指示を受け、Karoにコマンドを発行 |
| **Karo** | 司令塔。タスクを分解し、Ashigaru1-4に割り当て。進捗管理 |
| **Ashigaru1-4** | 実装担当。割り当てられたタスクを実行し、Karoに報告 |

### 指揮系統

```
殿（Lord/ユーザー） → Shogun → Karo → Ashigaru1-4
```

- Shogun⇔Ashigaru間の直接通信は禁止
- 全ての指示はKaroを経由

## 必要要件

- Go 1.21+
- [WezTerm](https://wezfurlong.org/wezterm/) ターミナル
- [Claude Code CLI](https://docs.anthropic.com/claude-code)
- fswatch (`brew install fswatch`)

## インストール

```bash
# リポジトリをクローン
git clone <repository-url>
cd ai-agent-shogun

# グローバルインストール
make install
```

インストール先:
- `~/.ai-agent-shogun/` - instructions, scripts
- `/usr/local/bin/ai-agent-shogun` - CLI バイナリ

## 使い方

### システム起動

任意のプロジェクトディレクトリで:

```bash
cd /path/to/your/project
ai-agent-shogun start
```

起動すると、WezTermが複数ペインに分割され、6エージェントのClaude Codeが自動起動します。

### メッセージ送信

```bash
# 基本構文
ai-agent-shogun write <target> "<message>" <type> <from>

# 例: ShogunへLord（殿）から指示
ai-agent-shogun write shogun "新機能を実装せよ" cmd lord

# 例: KaroからAshigaruへタスク割り当て
ai-agent-shogun write ashigaru1 "タスクを割り当てた" task_assigned karo

# 例: AshigaruからKaroへ完了報告
ai-agent-shogun write karo "task_001完了" report ashigaru1
```

### システム停止

```bash
ai-agent-shogun stop
```

### アンインストール

```bash
make uninstall
```

## ディレクトリ構成

### インストール後

```
~/.ai-agent-shogun/              # ツールホーム（共通）
├── instructions/
│   ├── shogun.md
│   ├── karo.md
│   └── ashigaru.md
├── start.zsh
├── stop.zsh
└── CLAUDE.md

/usr/local/bin/
└── ai-agent-shogun              # CLIバイナリ
```

### プロジェクト起動後

```
/path/to/your/project/
└── .ai-agent-shogun/            # プロジェクト固有データ
    ├── queue/
    │   ├── inbox/               # エージェント別受信箱
    │   │   ├── shogun.yaml
    │   │   ├── karo.yaml
    │   │   └── ashigaru1-4.yaml
    │   └── tasks/               # タスク定義
    ├── logs/                    # Watcherログ
    └── dashboard.md             # 進捗管理ダッシュボード
```

## 動作の仕組み

1. **メッセージ送信**: `ai-agent-shogun write`コマンドでYAMLファイルにメッセージを追加
2. **ファイル監視**: `ai-agent-shogun watch`がfswatch経由でinboxファイルの変更を検知
3. **通知送信**: 未読メッセージがあれば、WezTerm CLIで対象ペインに`inboxN`を送信
4. **処理実行**: エージェントがinboxを確認し、タスクを実行

## 環境変数

| 変数名 | 説明 | デフォルト |
|--------|------|-----------|
| `AI_AGENT_SHOGUN_HOME` | ツールホームディレクトリ | `~/.ai-agent-shogun` |
| `AI_AGENT_SHOGUN_WORKDIR` | 作業ディレクトリ | カレントディレクトリ |

## コマンド一覧

```bash
ai-agent-shogun start                              # エージェント起動
ai-agent-shogun stop                               # エージェント停止
ai-agent-shogun write <target> <msg> [type] [from] # メッセージ送信
ai-agent-shogun watch <agent_id> <pane_id>         # inbox監視（内部用）
```

## ライセンス

MIT
