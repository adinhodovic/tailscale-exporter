package headscale

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const preAuthKeysSubsystem = "preauthkeys"

var (
	preAuthKeysInfoDesc = newDesc(
		preAuthKeysSubsystem,
		"info",
		"Pre-auth key metadata",
		[]string{
			"id",
			"user",
			"reusable",
			"ephemeral",
			"used",
			"acl_tags",
		},
	)
	preAuthKeysCreatedDesc = newDesc(
		preAuthKeysSubsystem,
		"created_timestamp",
		"Unix timestamp when the pre-auth key was created",
		[]string{"id", "user"},
	)
	preAuthKeysExpirationDesc = newDesc(
		preAuthKeysSubsystem,
		"expiration_timestamp",
		"Unix timestamp when the pre-auth key expires",
		[]string{"id", "user"},
	)
)

type HeadscalePreAuthKeysCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(preAuthKeysSubsystem, NewHeadscalePreAuthKeysCollector)
}

func NewHeadscalePreAuthKeysCollector(config collectorConfig) (Collector, error) {
	return &HeadscalePreAuthKeysCollector{
		log: config.logger,
	}, nil
}

func (c HeadscalePreAuthKeysCollector) Update(
	ctx context.Context,
	client HeadscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting pre-auth keys metrics")

	keys, err := client.ListPreAuthKeys(ctx)
	if err != nil {
		c.log.ErrorContext(ctx, "Error getting Headscale pre-auth keys", "error", err)
		return err
	}

	for _, key := range keys {
		userName := ""
		if key.GetUser() != nil {
			userName = key.GetUser().GetName()
		}
		keyID := formatUint(key.GetId())

		ch <- prometheus.MustNewConstMetric(
			preAuthKeysInfoDesc, prometheus.GaugeValue, 1,
			keyID,
			userName,
			formatBoolLabel(key.GetReusable()),
			formatBoolLabel(key.GetEphemeral()),
			formatBoolLabel(key.GetUsed()),
			formatStringSliceLabel(key.GetAclTags()),
		)

		if ts := key.GetCreatedAt(); ts != nil {
			ch <- prometheus.MustNewConstMetric(preAuthKeysCreatedDesc, prometheus.GaugeValue, timestampToFloat(ts),
				keyID, userName,
			)
		}
		if ts := key.GetExpiration(); ts != nil {
			ch <- prometheus.MustNewConstMetric(preAuthKeysExpirationDesc, prometheus.GaugeValue, timestampToFloat(ts),
				keyID, userName,
			)
		}
	}

	return nil
}
