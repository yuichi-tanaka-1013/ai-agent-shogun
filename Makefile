.PHONY: build run clean test stop restart

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
