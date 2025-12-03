package headscale

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const nodesSubsystem = "nodes"

var (
	nodesInfoDesc = newDesc(
		nodesSubsystem,
		"info",
		"Node information",
		[]string{
			"id",
			"name",
			"user",
			"user_id",
			"given_name",
			"register_method",
			"machine_key",
			"node_key",
			"disco_key",
		},
	)
	nodesLastSeenDesc = newDesc(
		nodesSubsystem,
		"last_seen_timestamp",
		"Unix timestamp when node was last seen",
		[]string{"id", "name", "user"},
	)
	nodesCreatedDesc = newDesc(
		nodesSubsystem,
		"created_timestamp",
		"Unix timestamp when node was created",
		[]string{"id", "name", "user"},
	)
	nodesExpiryDesc = newDesc(
		nodesSubsystem,
		"expiry_timestamp",
		"Unix timestamp when node expires",
		[]string{"id", "name", "user"},
	)
	nodesOnlineDesc = newDesc(
		nodesSubsystem,
		"online",
		"Whether node is currently online",
		[]string{"id", "name", "user"},
	)
	nodesApprovedRoutesDesc = newDesc(
		nodesSubsystem,
		"approved_routes",
		"Number of approved routes for the node",
		[]string{"id", "name", "user"},
	)
	nodesAvailableRoutesDesc = newDesc(
		nodesSubsystem,
		"available_routes",
		"Number of available routes for the node",
		[]string{"id", "name", "user"},
	)
	nodesSubnetRoutesDesc = newDesc(
		nodesSubsystem,
		"subnet_routes",
		"Number of subnet routes advertised by the node",
		[]string{"id", "name", "user"},
	)
	nodesTagsDesc = newDesc(
		nodesSubsystem,
		"tags",
		"Number of tags grouped by category (forced, valid, invalid)",
		[]string{"id", "name", "user", "category"},
	)
)

type HeadscaleNodesCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(nodesSubsystem, NewHeadscaleNodesCollector)
}

func NewHeadscaleNodesCollector(config collectorConfig) (Collector, error) {
	return &HeadscaleNodesCollector{
		log: config.logger,
	}, nil
}

func (c HeadscaleNodesCollector) Update(
	ctx context.Context,
	client HeadscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting nodes metrics")

	nodes, err := client.ListNodes(ctx)
	if err != nil {
		c.log.ErrorContext(ctx, "Error getting Headscale nodes", "error", err)
		return err
	}

	for _, node := range nodes {
		nodeID := formatUint(node.GetId())
		userName := ""
		userID := ""
		if node.GetUser() != nil {
			userName = node.GetUser().GetName()
			userID = formatUint(node.GetUser().GetId())
		}

		ch <- prometheus.MustNewConstMetric(nodesInfoDesc, prometheus.GaugeValue, 1,
			nodeID,
			node.GetName(),
			userName,
			userID,
			node.GetGivenName(),
			node.GetRegisterMethod().String(),
			node.GetMachineKey(),
			node.GetNodeKey(),
			node.GetDiscoKey(),
		)

		if ts := node.GetLastSeen(); ts != nil {
			ch <- prometheus.MustNewConstMetric(nodesLastSeenDesc, prometheus.GaugeValue, timestampToFloat(ts),
				nodeID, node.GetName(), userName,
			)
		}

		if ts := node.GetCreatedAt(); ts != nil {
			ch <- prometheus.MustNewConstMetric(nodesCreatedDesc, prometheus.GaugeValue, timestampToFloat(ts),
				nodeID, node.GetName(), userName,
			)
		}

		if ts := node.GetExpiry(); ts != nil {
			ch <- prometheus.MustNewConstMetric(nodesExpiryDesc, prometheus.GaugeValue, timestampToFloat(ts),
				nodeID, node.GetName(), userName,
			)
		}

		ch <- prometheus.MustNewConstMetric(nodesOnlineDesc, prometheus.GaugeValue, boolAsFloat(node.GetOnline()),
			nodeID, node.GetName(), userName,
		)

		ch <- prometheus.MustNewConstMetric(nodesApprovedRoutesDesc, prometheus.GaugeValue, float64(len(node.GetApprovedRoutes())),
			nodeID, node.GetName(), userName,
		)
		ch <- prometheus.MustNewConstMetric(nodesAvailableRoutesDesc, prometheus.GaugeValue, float64(len(node.GetAvailableRoutes())),
			nodeID, node.GetName(), userName,
		)
		ch <- prometheus.MustNewConstMetric(nodesSubnetRoutesDesc, prometheus.GaugeValue, float64(len(node.GetSubnetRoutes())),
			nodeID, node.GetName(), userName,
		)

		tagCategories := map[string]int{
			"forced":  len(node.GetForcedTags()),
			"valid":   len(node.GetValidTags()),
			"invalid": len(node.GetInvalidTags()),
		}

		for category, count := range tagCategories {
			ch <- prometheus.MustNewConstMetric(nodesTagsDesc, prometheus.GaugeValue, float64(count),
				nodeID, node.GetName(), userName, category,
			)
		}
	}

	return nil
}
