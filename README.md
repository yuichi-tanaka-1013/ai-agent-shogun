# Mini Shogun

複数のClaude Codeエージェントを階層的に連携させるマルチエージェントシステム。

## 概要

Mini Shogunは、将軍（Shogun）・家老（Karo）・足軽（Ashigaru）の3層構造でClaude Codeエージェントを統率するシステムです。YAMLベースのメッセージキューとファイル監視により、エージェント間の非同期通信を実現します。

### エージェント構成

| エージェント | 役割 |
|-------------|------|
| **Shogun** | 戦略決定。ユーザーからの指示を受け、Karoにコマンドを発行 |
| **Karo** | 司令塔。タスクを分解し、Ashigaruに割り当て。進捗管理 |
| **Ashigaru** | 実装担当。割り当てられたタスクを実行し、Karoに報告 |

### 指揮系統

```
Shogun → Karo → Ashigaru
```

- Shogun⇔Ashigaru間の直接通信は禁止
- 全ての指示はKaroを経由

## 必要要件

- Go 1.21+
- [WezTerm](https://wezfurlong.org/wezterm/) ターミナル
- [Claude Code CLI](https://docs.anthropic.com/claude-code)
- fswatch (`brew install fswatch`)

## セットアップ

```bash
# リポジトリをクローン
git clone <repository-url>
cd ai-agent-shogun

# バイナリをビルド
make build

# または直接ビルド
go build -o ai-agent-shogun .
```

## 使い方

### システム起動

```bash
make run
# または
zsh start.zsh
```

起動すると、WezTermが3ペインに分割され、各エージェントのClaude Codeが自動起動します。

### メッセージ送信

```bash
# 基本構文
./ai-agent-shogun write <target> "<message>" <type> <from>

# 例: ShogunからKaroへコマンド送信
./ai-agent-shogun write karo "README.mdを作成せよ" cmd shogun

# 例: AshigaruからKaroへ完了報告
./ai-agent-shogun write karo "task_001完了" report ashigaru1
```

### システム停止

```bash
make stop
# または
pkill -f 'ai-agent-shogun watch'
```

### クリーンアップ

```bash
make clean
```

## ファイル構成

```
ai-agent-shogun/
├── ai-agent-shogun          # CLIバイナリ
├── main.go              # CLIソースコード
├── start.zsh            # 起動スクリプト
├── Makefile
├── CLAUDE.md            # エージェント共通指示
├── instructions/
│   ├── karo.md          # Karo用指示書
│   └── ashigaru.md      # Ashigaru用指示書
├── queue/
│   ├── inbox/           # エージェント別受信箱
│   │   ├── shogun.yaml
│   │   ├── karo.yaml
│   │   └── ashigaru1.yaml
│   └── tasks/           # タスク定義
│       └── ashigaru1.yaml
├── dashboard.md         # 進捗管理ダッシュボード
└── logs/                # Watcherログ
```

## 動作の仕組み

1. **メッセージ送信**: `ai-agent-shogun write`コマンドでYAMLファイルにメッセージを追加
2. **ファイル監視**: `ai-agent-shogun watch`がfswatch経由でinboxファイルの変更を検知
3. **通知送信**: 未読メッセージがあれば、WezTerm CLIで対象ペインに`inboxN`を送信
4. **処理実行**: エージェントがinboxを確認し、タスクを実行

## ライセンス

MIT
