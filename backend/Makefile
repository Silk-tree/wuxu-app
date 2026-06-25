.PHONY: run build test migrate tidy swag clean

APP_NAME := wuxu-server
CMD_PATH := ./cmd/server
MIGRATE_CMD := ./cmd/migrate
CONFIG_PATH := configs/config.yaml

run:
	@CONFIG_PATH=$(CONFIG_PATH) go run $(CMD_PATH)

build:
	@go build -o bin/$(APP_NAME) $(CMD_PATH)
	@echo "Build complete: bin/$(APP_NAME)"

test:
	@go test -v ./...

migrate:
	@CONFIG_PATH=$(CONFIG_PATH) go run $(MIGRATE_CMD)
	@echo "Migration complete"

tidy:
	@go mod tidy
	@echo "Dependencies tidied"

swag:
	@swag init -g $(CMD_PATH)/main.go -o ./docs
	@echo "Swagger docs generated"

clean:
	@rm -rf bin/
	@rm -rf docs/
	@echo "Cleaned build artifacts"

fmt:
	@gofmt -s -w .
	@echo "Formatted all Go files"

lint:
	@golangci-lint run ./...
	@echo "Lint complete"
