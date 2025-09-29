# Tailscale Exporter

A Prometheus exporter for Tailscale that provides tailnet-level metrics using the Tailscale API.

This repository also contains the `tailscale-mixin` that provides Prometheus alerts and rules and Grafana dashboard for tailnet-level metrics but also machine metrics.

## Features

- **Comprehensive Device Metrics**: Detailed per-device metrics including:
  - Device information with rich labels (name, hostname, OS, user, etc.)
  - Online/offline status and last seen timestamps
  - Authorization and external device status
  - Client version and update availability
  - Network connectivity and latency measurements
  - Route advertisement and enablement
  - Key expiry settings and timestamps
- **API Key Management**: Metrics for all API keys including:
  - Key information and descriptions
  - Expiration and creation timestamps
  - Revocation status
- **DNS Configuration**: DNS settings monitoring including:
  - MagicDNS configuration
  - Nameserver and search path counts
- **User Management**: User metrics including:
  - User information with roles and status
  - User activity timestamps
  - Aggregated counts by role and status
- **Tailnet Settings**: Configuration monitoring including:
  - Device and user approval settings
  - Network flow logging status
  - Regional routing configuration
  - Exit node role permissions
- **API Health**: Monitoring of Tailscale API accessibility

## Authentication Setup

### 1. Generate API Access Token

1. Go to the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys)
2. Navigate to **Settings** → **Oauth Client**
3. Click on **Create new OAuth client**
4. Add read access for DNS, Devices, Users, and Keys
5. Copy the generated token (it's only shown once)

## Installation

### Docker Image

There's a Docker image available on Docker Hub: [tailscale-exporter](https://hub.docker.com/r/adinhodovic/tailscale-exporter)

### Helm

A Helm chart is available in the `charts/tailscale-exporter` directory. You can install it using Helm:

```bash
helm install tailscale-exporter ./charts/tailscale-exporter \
  --set env.TAILSCALE_OAUTH_CLIENT_ID="your-client-id" \
  --set env.TAILSCALE_OAUTH_CLIENT_SECRET="your-client-secret" \
  --set env.TAILSCALE_TAILNET="your-tailnet-name"
```

## Usage

### Environment Variables

Set the required environment variables:

```bash
export TAILSCALE_OAUTH_CLIENT_ID="your-client-id"
export TAILSCALE_OAUTH_CLIENT_SECRET="your-client-secret"
export TAILSCALE_TAILNET="your-tailnet-name"
```

### Basic Usage

```bash
./tailscale-exporter
```

The exporter will start on port 9250 by default and expose metrics at `/metrics`.

### Command Line Options

```bash
./tailscale-exporter -h

Flags:
  -h, --help                         help for tailscale-exporter
  -l, --listen-address string        Address to listen on for web interface and telemetry (default ":9250")
  -m, --metrics-path string          Path under which to expose metrics (default "/metrics")
      --oauth-client-id string       OAuth client ID (can also be set via TAILSCALE_OAUTH_CLIENT_ID environment variable)
      --oauth-client-secret string   OAuth client secret (can also be set via TAILSCALE_OAUTH_CLIENT_SECRET environment variable)
  -t, --tailnet string               Tailscale tailnet (can also be set via TAILSCALE_TAILNET environment variable)
```


## Prometheus Configuration

Add the following to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'tailscale-exporter'
    static_configs:
      - targets: ['localhost:9250']
    scrape_interval: 30s
    metrics_path: /metrics
```

## Metrics

You can find the full list of metrics in the [METRICS.md](./docs/METRICS.md) file.
