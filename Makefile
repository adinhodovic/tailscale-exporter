TAILSCALE_EXPORTER := $(shell git describe --tags)
LDFLAGS += -X "main.BuildTimestamp=$(shell date -u "+%Y-%m-%d %H:%M:%S")"
LDFLAGS += -X "main.tailscaleExporterVersion=$(TAILSCALE_EXPORTER)"
LDFLAGS += -X "main.goVersion=$(shell go version | sed -r 's/go version go(.*)\ .*/\1/')"

GO := GO111MODULE=on CGO_ENABLED=0 go

.PHONY: build
build:
	$(GO) build -ldflags '$(LDFLAGS)' -o tailscale-exporter ./cmd/tailscale-exporter

.PHONY: build-all
build-all: ## Build binaries for linux/amd64 and linux/arm64
	@echo "Building linux/amd64..."
	GOOS=linux GOARCH=amd64 $(GO) build -ldflags '$(LDFLAGS)' \
		-o tailscale-exporter-linux-amd64 ./cmd/tailscale-exporter
	@echo "Building linux/arm64..."
	GOOS=linux GOARCH=arm64 $(GO) build -ldflags '$(LDFLAGS)' \
		-o tailscale-exporter-linux-arm64 ./cmd/tailscale-exporter
