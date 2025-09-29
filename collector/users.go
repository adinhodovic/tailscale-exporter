package collector

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
		"Users information and status",
		[]string{"id", "login_name", "display_name", "role", "status", "type"},
	)
	usersCurrentlyLoggedInDesc = newDesc(
		usersSubsystem,
		"currently_logged_in",
		"Whether user is currently logged in",
		[]string{"id", "login_name", "display_name"},
	)
	usersLastSeenDesc = newDesc(
		usersSubsystem,
		"last_seen_timestamp",
		"Unix timestamp when user was last seen",
		[]string{"id", "login_name", "display_name"},
	)
	usersCreatedDesc = newDesc(
		usersSubsystem,
		"created_timestamp",
		"Unix timestamp when user was created",
		[]string{"id", "login_name", "display_name"},
	)
)

type TailscaleUsersCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(usersSubsystem, NewTailscaleUsersCollector)
}

func NewTailscaleUsersCollector(config collectorConfig) (Collector, error) {
	return &TailscaleUsersCollector{
		log: config.logger,
	}, nil
}

func (c TailscaleUsersCollector) Update(
	ctx context.Context,
	client TailscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting users metrics")

	users, err := client.Users().List(ctx, nil, nil)
	if err != nil {
		c.log.ErrorContext(
			ctx,
			"Error getting Tailscale users",
			"error",
			err.Error(),
		)
		return err
	}

	// User metrics
	for _, user := range users {
		ch <- prometheus.MustNewConstMetric(
			usersInfoDesc, prometheus.GaugeValue, 1,
			user.ID,
			user.LoginName,
			user.DisplayName,
			string(user.Type),
			string(user.Role),
			string(user.Status),
		)

		ch <- prometheus.MustNewConstMetric(
			usersCurrentlyLoggedInDesc, prometheus.GaugeValue, boolAsFloat(user.CurrentlyConnected),
			user.ID, user.LoginName, user.DisplayName,
		)

		if !user.Created.IsZero() {
			ch <- prometheus.MustNewConstMetric(usersCreatedDesc, prometheus.GaugeValue, float64(user.Created.Unix()),
				user.ID, user.LoginName, user.DisplayName)
		}
		if !user.LastSeen.IsZero() {
			ch <- prometheus.MustNewConstMetric(usersLastSeenDesc, prometheus.GaugeValue, float64(user.LastSeen.Unix()),
				user.ID, user.LoginName, user.DisplayName)
		}
	}

	return nil
}
