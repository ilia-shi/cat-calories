.PHONY: build run dev proto

build:
	go build -o bin/server ./cmd/server

run: build
	./bin/server

dev:
	go run ./cmd/server

# Generate Go code from protobuf schemas (requires protoc + protoc-gen-go)
proto:
	protoc \
		--proto_path=../proto \
		--go_out=. --go_opt=paths=source_relative \
		../proto/sync/v1/models.proto \
		../proto/sync/v1/sync_service.proto
