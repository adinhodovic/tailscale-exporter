package collector

import (
	"context"
	"log/slog"

	"github.com/prometheus/client_golang/prometheus"
)

const dnsSubsystem = "dns"

var (
	dnsNameserversDesc = newDesc(
		dnsSubsystem,
		"nameservers_info",
		"Tailscale DNS nameservers configuration.",
		[]string{"nameserver"},
	)
	dnsMagicDNSDesc = newDesc(
		dnsSubsystem,
		"magic_dns",
		"Tailscale Magic DNS configuration.",
		[]string{},
	)
)

type TailscaleDNSCollector struct {
	log *slog.Logger
}

func init() {
	registerCollector(dnsSubsystem, NewTailscaleDNSCollector)
}

func NewTailscaleDNSCollector(config collectorConfig) (Collector, error) {
	return &TailscaleDNSCollector{
		log: config.logger,
	}, nil
}

func (c TailscaleDNSCollector) Update(
	ctx context.Context,
	client TailscaleClient,
	ch chan<- prometheus.Metric,
) error {
	c.log.DebugContext(ctx, "Collecting dns metrics")

	nameservers, err := client.DNS().Nameservers(ctx)
	if err != nil {
		c.log.ErrorContext(
			ctx,
			"Error getting Tailscale dns nameservers",
			"error",
			err.Error(),
		)
		return err
	}

	// Nameserver metrics
	for _, ns := range nameservers {
		ch <- prometheus.MustNewConstMetric(
			dnsNameserversDesc,
			prometheus.GaugeValue,
			1,
			ns,
		)
	}

	magicDns, err := client.DNS().Preferences(ctx)
	if err != nil {
		c.log.ErrorContext(
			ctx,
			"Error getting Tailscale magic dns",
			"error",
			err.Error(),
		)
		return err
	}

	ch <- prometheus.MustNewConstMetric(
		dnsMagicDNSDesc,
		prometheus.GaugeValue,
		boolAsFloat(magicDns.MagicDNS),
	)

	return nil
}
