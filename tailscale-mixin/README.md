# Prometheus Monitoring Mixin for the Tailscale

A set of Grafana dashboards and Prometheus alerts for the Tailscale using the metrics from the `tailscale-exporter`.

## How to use

This mixin is designed to be vendored into the repo with your infrastructure config. To do this, use [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler):

You then have three options for deploying your dashboards

1. Generate the config files and deploy them yourself
2. Use jsonnet to deploy this mixin along with Prometheus and Grafana
3. Use prometheus-operator to deploy this mixin

Or import the dashboard using json in `./dashboards_out`, alternatively import them from the `Grafana.com` dashboard page.

## Generate config files

Build the mixin:

```sh
make
```

The `prometheus_alerts.yaml` file then need to passed to your Prometheus server, and the files in `dashboards_out` need to be imported into you Grafana server. The exact details vary depending on how you deploy your monitoring stack.

## Alerts

The mixin follows the [monitoring-mixins guidelines](https://github.com/monitoring-mixins/docs#guidelines-for-alert-names-labels-and-annotations) for alerts.
