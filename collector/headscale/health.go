package headscale

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const healthSubsystem = "health"

var (
	healthDatabaseConnectivityDesc = newDesc(
		healthSubsystem,
		"database_connectivity",
		"Whether Headscale reports healthy database connectivity",
		nil,
	)
)

type HeadscaleHealthCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(healthSubsystem, NewHeadscaleHealthCollector)
}

func NewHeadscaleHealthCollector(config collectorConfig) (Collector, error) {
	return &HeadscaleHealthCollector{
		log: config.logger,
	}, nil
}

func (c HeadscaleHealthCollector) Update(
	ctx context.Context,
	client HeadscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting health metrics")

	resp, err := client.Health(ctx)
	if err != nil {
		c.log.ErrorContext(ctx, "Error getting Headscale health status", "error", err)
		return err
	}

	ch <- prometheus.MustNewConstMetric(
		healthDatabaseConnectivityDesc, prometheus.GaugeValue, boolAsFloat(resp.GetDatabaseConnectivity()),
	)

	return nil
}
