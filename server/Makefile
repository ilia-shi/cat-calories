.PHONY: build run dev

build:
	go build -o bin/server ./cmd/server

run: build
	./bin/server

dev:
	go run ./cmd/server
