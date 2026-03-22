FROM golang:1.23-alpine AS build
RUN apk add --no-cache gcc musl-dev
WORKDIR /src
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=1 go build -o /bin/server ./cmd/server

FROM build AS build-dev
RUN CGO_ENABLED=1 go build -o /bin/createuser ./cmd/createuser
RUN CGO_ENABLED=1 go build -o /bin/initdb ./cmd/initdb

FROM alpine:3.20 AS production
RUN apk add --no-cache ca-certificates
COPY --from=build /bin/server /bin/server
EXPOSE 8080
ENTRYPOINT ["/bin/server"]

FROM production AS dev
COPY --from=build-dev /bin/createuser /bin/createuser
COPY --from=build-dev /bin/initdb /bin/initdb
