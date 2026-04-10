FROM dart:stable AS build

WORKDIR /app

# Copy core package first (dependency)
COPY packages/core/pubspec.yaml packages/core/pubspec.yaml
COPY packages/core/lib packages/core/lib

# Copy server package
COPY packages/server/pubspec.yaml packages/server/pubspec.yaml
COPY packages/server/lib packages/server/lib
COPY packages/server/bin packages/server/bin

WORKDIR /app/packages/server

RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

# --- Runtime ---
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/packages/server/bin/server /usr/local/bin/server

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/server"]
