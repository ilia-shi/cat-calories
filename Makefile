.PHONY: server server-dev server-init server-stop server-logs create-user init-db ip firewall test test-schema test-server test-web test-dart web-server start dev dev-stop dev-logs

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
	@echo "Server running at http://server.localhost:8080 (also http://localhost:8080)"

server-dev:
	docker compose up -d --build --watch
	@echo "Server running at http://server.localhost:8080 (watching for changes)"

server-init: init-db
	docker compose up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories Server"
	@echo " URL:      http://server.localhost:8080"
	@echo " Email:    test@localhost"
	@echo " Password: password"
	@echo "-----------------------------------"
	@echo ""
	xdg-open http://server.localhost:8080 2>/dev/null || open http://server.localhost:8080 2>/dev/null || true

start: init-db
	docker compose --profile web up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories"
	@echo " Frontend: http://app.localhost:8080"
	@echo " API:      http://server.localhost:8080"
	@echo " Email:    test@localhost"
	@echo " Password: password"
	@echo "-----------------------------------"
	@echo ""
	xdg-open http://app.localhost:8080 2>/dev/null || open http://app.localhost:8080 2>/dev/null || true

dev: init-dev-db
	docker compose --profile web --profile auth up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories — Full Dev Environment"
	@echo ""
	@echo " Frontend: http://app.localhost:8080"
	@echo " API:      http://server.localhost:8080"
	@echo " OAuth:    http://oauth.localhost:8080"
	@echo " Traefik:  http://traefik.localhost:8080"
	@echo ""
	@echo " Email:    test@localhost"
	@echo " Password: password"
	@echo "-----------------------------------"
	@echo ""
	@echo "Waiting for server to be healthy..."
	@timeout 60 bash -c 'until curl -sf http://server.localhost:8080/health > /dev/null 2>&1; do sleep 1; done' && echo "Server is ready." || echo "Warning: server health check timed out."
	@echo ""
	@echo "Sync config: http://server.localhost:8080/.well-known/sync-config"
	@echo ""
	@LOCAL_IP=$$(hostname -I | awk '{print $$1}'); \
	echo "Mobile app server address: http://$$LOCAL_IP:8080"; \
	if ss -tlnp 2>/dev/null | grep -q ':8080 '; then \
		echo "Port 8080: listening"; \
	else \
		echo "Port 8080: NOT listening"; \
	fi; \
	if command -v firewall-cmd > /dev/null 2>&1; then \
		if firewall-cmd --query-port=8080/tcp 2>/dev/null; then \
			echo "Firewall: port 8080 is open"; \
		else \
			echo "Firewall: port 8080 is BLOCKED — run 'make firewall' to open it"; \
		fi; \
	fi

init-dev-db:
	docker compose --profile web --profile auth down -v
	docker compose --profile auth build
	docker compose --profile auth up -d casdoor-db casdoor traefik
	@echo "Waiting for Casdoor to be healthy..."
	@timeout 90 bash -c 'until curl -sf http://oauth.localhost:8080/api/health > /dev/null 2>&1; do sleep 2; done' && echo "Casdoor is ready." || (echo "Error: Casdoor health check timed out."; exit 1)
	docker compose build server
	docker compose run --rm --entrypoint "/bin/initdb -email test@localhost -password password" server
	docker compose --profile auth down

dev-stop:
	docker compose --profile web --profile auth down

dev-logs:
	docker compose --profile web --profile auth logs -f

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
