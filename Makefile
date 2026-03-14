build:
	flutter build apk --release

web-build:
	cd web && npm run build

web-dev:
	cd web && npm run dev