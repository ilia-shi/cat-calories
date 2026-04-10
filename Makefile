.PHONY: server server-dev server-init server-stop server-logs server-run ip firewall test test-dart test-web test-server web-server start dev dev-stop dev-logs

build:
	flutter build apk --release

web-build:
	cd web && npm run build

web-dev:
	cd web && npm run dev

web-server:
	cd web && API_URL=http://localhost:8080 npm run dev

# Run server locally (without Docker)
server-run:
	cd packages/server && dart run bin/server.dart

server:
	docker compose up -d --build
	@echo "Server running at http://server.localhost:8080 (also http://localhost:8080)"

server-dev:
	docker compose up -d --build --watch
	@echo "Server running at http://server.localhost:8080 (watching for changes)"

server-init:
	docker compose down -v
	docker compose up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories Server (Dart)"
	@echo " URL: http://server.localhost:8080"
	@echo "-----------------------------------"
	@echo ""
	@echo "Register a user: curl -X POST http://server.localhost:8080/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"test@localhost\",\"password\":\"password\"}'"
	@echo ""
	xdg-open http://server.localhost:8080 2>/dev/null || open http://server.localhost:8080 2>/dev/null || true

start:
	docker compose --profile web up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories"
	@echo ""
	@echo " Server 1:"
	@echo "   Frontend: http://app.localhost:8080"
	@echo "   API:      http://server.localhost:8080"
	@echo ""
	@echo " Server 2:"
	@echo "   Frontend: http://app2.localhost:8080"
	@echo "   API:      http://server2.localhost:8080"
	@echo "-----------------------------------"
	@echo ""
	xdg-open http://app.localhost:8080 2>/dev/null || open http://app.localhost:8080 2>/dev/null || true

dev: init-dev-db
	docker compose --profile web --profile auth up -d --build
	@echo ""
	@echo "-----------------------------------"
	@echo " Cat Calories — Full Dev Environment"
	@echo ""
	@echo " Server 1:"
	@echo "   Frontend: http://app.localhost:8080"
	@echo "   API:      http://server.localhost:8080"
	@echo ""
	@echo " Server 2:"
	@echo "   Frontend: http://app2.localhost:8080"
	@echo "   API:      http://server2.localhost:8080"
	@echo ""
	@echo " OAuth:    http://oauth.localhost:8080"
	@echo " Traefik:  http://traefik.localhost:8080"
	@echo "-----------------------------------"
	@echo ""
	@echo "Waiting for servers to be healthy..."
	@timeout 60 bash -c 'until curl -sf http://server.localhost:8080/health > /dev/null 2>&1; do sleep 1; done' && echo "Server 1 is ready." || echo "Warning: server 1 health check timed out."
	@timeout 60 bash -c 'until curl -sf http://server2.localhost:8080/health > /dev/null 2>&1; do sleep 1; done' && echo "Server 2 is ready." || echo "Warning: server 2 health check timed out."
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
	docker compose --profile auth down

dev-stop:
	docker compose --profile web --profile auth down

dev-logs:
	docker compose --profile web --profile auth logs -f

server-stop:
	docker compose --profile web down

server-logs:
	docker compose logs -f server server2

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

test-dart:
	flutter test test/api_schema_test.dart

test-web:
	cd web && npm run generate:api-types && npx tsc --noEmit

test-server:
	cd packages/server && dart analyze
