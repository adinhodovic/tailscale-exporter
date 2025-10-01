TAILSCALE_EXPORTER := $(shell git describe --tags)
LDFLAGS += -X "main.BuildTimestamp=$(shell date -u "+%Y-%m-%d %H:%M:%S")"
LDFLAGS += -X "main.tailscaleExporterVersion=$(TAILSCALE_EXPORTER)"
LDFLAGS += -X "main.goVersion=$(shell go version | sed -r 's/go version go(.*)\ .*/\1/')"

GO := GO111MODULE=on CGO_ENABLED=0 go

.PHONY: build
build:
	$(GO) build -ldflags '$(LDFLAGS)' -o tailscale-exporter ./cmd/tailscale-exporter

build-linux-amd64:
	$(GO) build -ldflags '$(LDFLAGS)' -o tailscale-exporter-linux-amd64 ./cmd/tailscale-exporter
