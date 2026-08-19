package tailscale

import (
	"context"
	"log/slog"
	"strings"

	"github.com/prometheus/client_golang/prometheus"
)

const servicesSubsystem = "services"

var (
	servicesInfoDesc = newDesc(
		servicesSubsystem,
		"info",
		"Tailscale Service information",
		[]string{"name", "comment", "tags"},
	)
	servicesAddressDesc = newDesc(
		servicesSubsystem,
		"address",
		"Whether a Tailscale Service has an advertised address",
		[]string{"service", "address"},
	)
	servicesPortDesc = newDesc(
		servicesSubsystem,
		"port",
		"Whether a Tailscale Service advertises a port",
		[]string{"service", "port"},
	)
)

type TailscaleServicesCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(servicesSubsystem, NewTailscaleServicesCollector)
}

func NewTailscaleServicesCollector(config collectorConfig) (Collector, error) {
	return &TailscaleServicesCollector{log: config.logger}, nil
}

func (c TailscaleServicesCollector) Update(
	ctx context.Context,
	client TailscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting services metrics")

	services, err := client.Services().List(ctx)
	if err != nil {
		c.log.ErrorContext(ctx, "Error getting Tailscale services", "error", err.Error())
		return err
	}

	for _, service := range services {
		ch <- prometheus.MustNewConstMetric(
			servicesInfoDesc,
			prometheus.GaugeValue,
			1,
			service.Name,
			service.Comment,
			strings.Join(service.Tags, ","),
		)

		for _, address := range service.Addrs {
			ch <- prometheus.MustNewConstMetric(
				servicesAddressDesc,
				prometheus.GaugeValue,
				1,
				service.Name,
				address,
			)
		}

		for _, port := range service.Ports {
			ch <- prometheus.MustNewConstMetric(
				servicesPortDesc,
				prometheus.GaugeValue,
				1,
				service.Name,
				port,
			)
		}
	}

	return nil
}
