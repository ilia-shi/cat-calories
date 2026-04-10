.PHONY: server server-dev server-init server-stop server-logs create-user init-db ip firewall test test-schema test-server test-web test-dart web-server start emulator

emulator:
	flutter emulators --launch Pixel_9
	flutter run

build:
	flutter build apk --release

web-build:
	cd web && npm run build

web-dev:
	cd web && npm run dev

web-server:
	cd web && API_URL=http://localhost:8080 npm run dev

server:
	docker compose up -d --build
	@echo "Server running at http://0.0.0.0:8080"

server-dev:
	docker compose up -d --build --watch
	@echo "Server running at http://0.0.0.0:8080 (watching for changes)"

server-init: init-db
	docker compose up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories Server"
	@echo " URL:      http://0.0.0.0:8080"
	@echo " Email:    test@localhost"
	@echo " Password: password"
	@echo "-----------------------------------"
	@echo ""
	xdg-open http://0.0.0.0:8080 2>/dev/null || open http://0.0.0.0:8080 2>/dev/null || true

start: init-db
	docker compose --profile web up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories"
	@echo " Frontend: http://localhost:3000"
	@echo " API:      http://localhost:8080"
	@echo " Email:    test@localhost"
	@echo " Password: password"
	@echo "-----------------------------------"
	@echo ""
	xdg-open http://localhost:3000 2>/dev/null || open http://localhost:3000 2>/dev/null || true

server-stop:
	docker compose --profile web down

server-logs:
	docker compose logs -f server

create-user:
	docker compose run --rm --entrypoint /bin/createuser server

init-db:
	docker compose --profile web down -v
	docker compose build
	docker compose run --rm --entrypoint "/bin/initdb -email test@localhost -password password" server

ip:
	@echo "Local IP addresses:"
	@hostname -I | tr ' ' '\n' | grep -v '^$$'
	@echo ""
	@echo "Server URL for mobile app:"
	@echo "http://$$(hostname -I | awk '{print $$1}'):8080"

firewall:
	sudo firewall-cmd --add-port=8080/tcp
	@echo "Port 8080 opened in firewall"

test: test-dart test-web test-server

test-schema: test-dart test-web test-server

test-dart:
	flutter test test/api_schema_test.dart

test-web:
	cd web && npm run generate:api-types && npx tsc --noEmit

test-server:
	cd server && go test ./...
