.PHONY: build run clean test stop restart help install uninstall

# Installation directories
PREFIX ?= /usr/local
HOME_DIR := $(HOME)/.ai-agent-shogun

build:
	go build -o ai-agent-shogun .

install: build
	@echo "📦 Installing AI Agent Shogun..."
	@mkdir -p $(HOME_DIR)/instructions
	@cp -r instructions/* $(HOME_DIR)/instructions/
	@cp start.zsh $(HOME_DIR)/
	@cp stop.zsh $(HOME_DIR)/
	@cp CLAUDE.md $(HOME_DIR)/
	@mkdir -p $(PREFIX)/bin
	@cp ai-agent-shogun $(PREFIX)/bin/
	@chmod +x $(PREFIX)/bin/ai-agent-shogun
	@chmod +x $(HOME_DIR)/start.zsh
	@chmod +x $(HOME_DIR)/stop.zsh
	@echo ""
	@echo "✅ Installation complete!"
	@echo ""
	@echo "Files installed:"
	@echo "  $(PREFIX)/bin/ai-agent-shogun"
	@echo "  $(HOME_DIR)/"
	@echo "    ├── instructions/"
	@echo "    ├── start.zsh"
	@echo "    ├── stop.zsh"
	@echo "    └── CLAUDE.md"
	@echo ""
	@echo "Usage:"
	@echo "  cd /path/to/your/project"
	@echo "  ai-agent-shogun start"
	@echo "  ai-agent-shogun stop"

uninstall:
	@echo "🗑️  Uninstalling AI Agent Shogun..."
	@rm -f $(PREFIX)/bin/ai-agent-shogun
	@rm -rf $(HOME_DIR)
	@echo "✅ Uninstalled"

run: build
	zsh start.zsh

stop:
	zsh stop.zsh

restart: stop
	sleep 1
	zsh start.zsh

clean:
	zsh stop.zsh || true
	rm -f ai-agent-shogun
	rm -rf .ai-agent-shogun/

test: build
	@mkdir -p .ai-agent-shogun/queue/inbox
	./ai-agent-shogun write shogun "テストメッセージ" cmd lord
	@cat .ai-agent-shogun/queue/inbox/shogun.yaml

help:
	@echo "AI Agent Shogun - 利用可能なターゲット:"
	@echo ""
	@echo "  install   - グローバルインストール (~/.ai-agent-shogun, /usr/local/bin)"
	@echo "  uninstall - アンインストール"
	@echo "  build     - Go実行ファイルのビルド"
	@echo "  run       - ビルド後に起動 (6 agents)"
	@echo "  stop      - 停止"
	@echo "  restart   - 再起動"
	@echo "  clean     - クリーンアップ"
	@echo "  test      - テスト実行"
	@echo "  help      - このヘルプを表示"
	@echo ""
	@echo "インストール後の使い方:"
	@echo "  cd /path/to/project && ai-agent-shogun start"
	@echo ""
	@echo "階層: 殿(Lord) → 将軍(Shogun) → 家老(Karo) → 足軽1-4(Ashigaru)"
