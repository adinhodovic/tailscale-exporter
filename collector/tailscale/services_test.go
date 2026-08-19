package tailscale

import (
	"context"
	"log/slog"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"tailscale.com/client/tailscale/v2"
)

func TestTailscaleServicesCollector_Update(t *testing.T) {
	collector := &TailscaleServicesCollector{log: slog.Default()}
	ch := make(chan prometheus.Metric, 16)

	err := collector.Update(context.Background(), &MockTailscaleClient{
		servicesClient: &MockServicesClient{
			services: []tailscale.Service{
				{
					Name:    "svc:web",
					Comment: "Web service",
					Tags:    []string{"tag:prod", "tag:web"},
					Addrs:   []string{"100.100.100.1"},
					Ports:   []string{"tcp:443", "tcp:80"},
				},
			},
		},
	}, ch)
	close(ch)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var metrics []prometheus.Metric
	for metric := range ch {
		metrics = append(metrics, metric)
	}

	reg := prometheus.NewRegistry()
	reg.MustRegister(&TestMetricCollector{metrics: metrics})
	if err := testutil.GatherAndCompare(reg, strings.NewReader(`
# HELP tailscale_services_address Whether a Tailscale Service has an advertised address
# TYPE tailscale_services_address gauge
tailscale_services_address{address="100.100.100.1",service="svc:web"} 1
# HELP tailscale_services_info Tailscale Service information
# TYPE tailscale_services_info gauge
tailscale_services_info{comment="Web service",name="svc:web",tags="tag:prod,tag:web"} 1
# HELP tailscale_services_port Whether a Tailscale Service advertises a port
# TYPE tailscale_services_port gauge
tailscale_services_port{port="tcp:443",service="svc:web"} 1
tailscale_services_port{port="tcp:80",service="svc:web"} 1
`)); err != nil {
		t.Errorf("metrics mismatch: %v", err)
	}
}
