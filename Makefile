.PHONY: build run clean test stop restart help

build:
	go build -o mini-shogun .

run: build
	zsh start.zsh

stop:
	zsh stop.zsh

restart: stop
	sleep 1
	zsh start.zsh

clean:
	zsh stop.zsh || true
	rm -f mini-shogun
	rm -f queue/inbox/*.yaml queue/tasks/*.yaml
	rm -f .pane_ids .agent_id_*
	rm -rf logs/
	echo "messages: []" > queue/inbox/shogun.yaml
	echo "messages: []" > queue/inbox/karo.yaml
	for i in 1 2 3 4 5 6 7 8; do echo "messages: []" > queue/inbox/ashigaru$$i.yaml; done

test: build
	./mini-shogun write shogun "テストメッセージ" cmd lord
	cat queue/inbox/shogun.yaml

help:
	@echo "Mini Shogun - 利用可能なターゲット:"
	@echo "  build    - Go実行ファイルのビルド"
	@echo "  run      - ビルド後に起動 (10 agents)"
	@echo "  stop     - 停止"
	@echo "  restart  - 再起動"
	@echo "  clean    - クリーンアップ"
	@echo "  test     - テスト実行"
	@echo "  help     - このヘルプを表示"
	@echo ""
	@echo "階層: 殿(Lord) → 将軍(Shogun) → 家老(Karo) → 足軽1-8(Ashigaru)"
