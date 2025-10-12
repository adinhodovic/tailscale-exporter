FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build for target platform (amd64 or arm64 passed automatically by Buildx)
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-s -w" \
  -o tailscale-exporter ./cmd/tailscale-exporter

# Final stage
FROM alpine:3.20

RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 1001 -S tailscale-exporter && \
  adduser -u 1001 -S tailscale-exporter -G tailscale-exporter

WORKDIR /app
COPY --from=builder /app/tailscale-exporter .

USER tailscale-exporter

EXPOSE 9250

CMD ["./tailscale-exporter"]
