package collector

import (
	"context"
	"log/slog"
	"strconv"

	"github.com/prometheus/client_golang/prometheus"
)

const tailnetSettingsSubsystem = "tailnet_settings"

var (
	tailnetSettingsInfoDesc = newDesc(
		tailnetSettingsSubsystem,
		"info",
		"Information about the Tailscale Tailnet settings.",
		[]string{
			"acls_externally_managed_on",
			"acls_external_link",
			"devices_approval_on",
			"devices_auto_updates_on",
			"users_approval_on",
			"users_role_allowed_to_join_external_tailnets",
			"network_flow_logging_on",
			"regional_routing_on",
			"posture_identity_collection_on",
		},
	)
	tailnetSettingsDevicesKeyDurationDaysDesc = newDesc(
		tailnetSettingsSubsystem,
		"devices_key_duration_days",
		"Number of days before device key expiry.",
		[]string{},
	)
)

type TailscaleTailnetSettingsCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(tailnetSettingsSubsystem, NewTailscaleSettingsCollector)
}

func NewTailscaleSettingsCollector(config collectorConfig) (Collector, error) {
	return &TailscaleTailnetSettingsCollector{
		log: config.logger,
	}, nil
}

func (c TailscaleTailnetSettingsCollector) Update(
	ctx context.Context,
	client TailscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.Debug("Collecting Tailscale Tailnet settings metrics")

	settings, err := client.TailnetSettings().Get(ctx)
	if err != nil {
		c.log.Error(
			"Error getting Tailscale Tailnet settings",
			"error",
			err.Error(),
		)
		return err
	}

	ch <- prometheus.MustNewConstMetric(
		tailnetSettingsInfoDesc,
		prometheus.GaugeValue,
		1,
		strconv.FormatBool(settings.ACLsExternallyManagedOn),
		settings.ACLsExternalLink,
		strconv.FormatBool(settings.DevicesApprovalOn),
		strconv.FormatBool(settings.DevicesAutoUpdatesOn),
		strconv.FormatBool(settings.UsersApprovalOn),
		string(settings.UsersRoleAllowedToJoinExternalTailnets),
		strconv.FormatBool(settings.NetworkFlowLoggingOn),
		strconv.FormatBool(settings.RegionalRoutingOn),
		strconv.FormatBool(settings.PostureIdentityCollectionOn),
	)
	ch <- prometheus.MustNewConstMetric(
		tailnetSettingsDevicesKeyDurationDaysDesc,
		prometheus.GaugeValue,
		float64(settings.DevicesKeyDurationDays),
	)
	return nil
}
