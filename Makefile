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
	echo "messages: []" > queue/inbox/ashigaru1.yaml

test: build
	./mini-shogun write karo "テストメッセージ" test shogun
	cat queue/inbox/karo.yaml

help:
	@echo "Mini Shogun - 利用可能なターゲット:"
	@echo "  build    - Go実行ファイルのビルド"
	@echo "  run      - ビルド後に起動"
	@echo "  stop     - 停止"
	@echo "  restart  - 再起動"
	@echo "  clean    - クリーンアップ"
	@echo "  test     - テスト実行"
	@echo "  help     - このヘルプを表示"
