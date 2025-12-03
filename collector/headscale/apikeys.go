package headscale

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const apiKeysSubsystem = "apikeys"

var (
	apiKeysInfoDesc = newDesc(
		apiKeysSubsystem,
		"info",
		"API key metadata",
		[]string{"id", "prefix"},
	)
	apiKeysCreatedDesc = newDesc(
		apiKeysSubsystem,
		"created_timestamp",
		"Unix timestamp when the API key was created",
		[]string{"id", "prefix"},
	)
	apiKeysExpirationDesc = newDesc(
		apiKeysSubsystem,
		"expiration_timestamp",
		"Unix timestamp when the API key expires",
		[]string{"id", "prefix"},
	)
	apiKeysLastSeenDesc = newDesc(
		apiKeysSubsystem,
		"last_seen_timestamp",
		"Unix timestamp when the API key was last used",
		[]string{"id", "prefix"},
	)
)

type HeadscaleAPIKeysCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(apiKeysSubsystem, NewHeadscaleAPIKeysCollector)
}

func NewHeadscaleAPIKeysCollector(config collectorConfig) (Collector, error) {
	return &HeadscaleAPIKeysCollector{
		log: config.logger,
	}, nil
}

func (c HeadscaleAPIKeysCollector) Update(
	ctx context.Context,
	client HeadscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting API keys metrics")

	apiKeys, err := client.ListAPIKeys(ctx)
	if err != nil {
		c.log.ErrorContext(ctx, "Error getting Headscale API keys", "error", err)
		return err
	}

	for _, key := range apiKeys {
		keyID := formatUint(key.GetId())
		ch <- prometheus.MustNewConstMetric(apiKeysInfoDesc, prometheus.GaugeValue, 1, keyID, key.GetPrefix())

		if ts := key.GetCreatedAt(); ts != nil {
			ch <- prometheus.MustNewConstMetric(apiKeysCreatedDesc, prometheus.GaugeValue, timestampToFloat(ts),
				keyID, key.GetPrefix(),
			)
		}

		if ts := key.GetExpiration(); ts != nil {
			ch <- prometheus.MustNewConstMetric(apiKeysExpirationDesc, prometheus.GaugeValue, timestampToFloat(ts),
				keyID, key.GetPrefix(),
			)
		}

		if ts := key.GetLastSeen(); ts != nil {
			ch <- prometheus.MustNewConstMetric(apiKeysLastSeenDesc, prometheus.GaugeValue, timestampToFloat(ts),
				keyID, key.GetPrefix(),
			)
		}
	}

	return nil
}
