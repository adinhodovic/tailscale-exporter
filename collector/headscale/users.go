package headscale

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const usersSubsystem = "users"

var (
	usersInfoDesc = newDesc(
		usersSubsystem,
		"info",
		"User information and metadata",
		[]string{"id", "name", "display_name", "email", "provider", "provider_id"},
	)
	usersCreatedDesc = newDesc(
		usersSubsystem,
		"created_timestamp",
		"Unix timestamp when the user was created",
		[]string{"id", "name"},
	)
)

type HeadscaleUsersCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(usersSubsystem, NewHeadscaleUsersCollector)
}

func NewHeadscaleUsersCollector(config collectorConfig) (Collector, error) {
	return &HeadscaleUsersCollector{
		log: config.logger,
	}, nil
}

func (c HeadscaleUsersCollector) Update(
	ctx context.Context,
	client HeadscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting users metrics")

	users, err := client.ListUsers(ctx)
	if err != nil {
		c.log.ErrorContext(ctx, "Error getting Headscale users", "error", err)
		return err
	}

	for _, user := range users {
		userID := formatUint(user.GetId())
		ch <- prometheus.MustNewConstMetric(usersInfoDesc, prometheus.GaugeValue, 1,
			userID,
			user.GetName(),
			user.GetDisplayName(),
			user.GetEmail(),
			user.GetProvider(),
			user.GetProviderId(),
		)

		if ts := user.GetCreatedAt(); ts != nil {
			ch <- prometheus.MustNewConstMetric(usersCreatedDesc, prometheus.GaugeValue, timestampToFloat(ts),
				userID, user.GetName(),
			)
		}
	}

	return nil
}
