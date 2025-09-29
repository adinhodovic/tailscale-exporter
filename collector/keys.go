package collector

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const keysSubsystem = "keys"

var (
	keysInfoDesc = newDesc(
		keysSubsystem,
		"info",
		"Key information.",
		[]string{"id", "key_type", "user_id"},
	)

	keysCreatedDesc = newDesc(
		keysSubsystem,
		"created_timestamp",
		"Timestamp when the key was created.",
		[]string{"id", "key_type", "user_id"},
	)

	keysExpiresDesc = newDesc(
		keysSubsystem,
		"expires_timestamp",
		"Timestamp when the key expires.",
		[]string{"id", "key_type", "user_id"},
	)
)

type TailscaleKeysCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(keysSubsystem, NewTailscaleKeysCollector)
}

func NewTailscaleKeysCollector(config collectorConfig) (Collector, error) {
	return &TailscaleKeysCollector{
		log: config.logger,
	}, nil
}

func (c TailscaleKeysCollector) Update(
	ctx context.Context,
	client TailscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.Debug("Collecting keys metrics")

	keys, err := client.Keys().List(ctx, true)
	if err != nil {
		c.log.Error("Error getting Tailscale keys", "error", err.Error())
		return err
	}

	for _, key := range keys {
		ch <- prometheus.MustNewConstMetric(
			keysInfoDesc, prometheus.GaugeValue, 1,
			key.ID, key.KeyType, key.UserID,
		)

		ch <- prometheus.MustNewConstMetric(
			keysCreatedDesc, prometheus.GaugeValue, float64(key.Created.Unix()),
			key.ID, key.KeyType, key.UserID,
		)

		ch <- prometheus.MustNewConstMetric(
			keysExpiresDesc, prometheus.GaugeValue, float64(key.Expires.Unix()),
			key.ID, key.KeyType, key.UserID,
		)
	}

	return nil
}
