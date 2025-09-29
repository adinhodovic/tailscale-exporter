package collector

import (
	"context"
	"log/slog"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"tailscale.com/client/tailscale/v2"
)


func TestTailscaleDNSCollector_Update(t *testing.T) {
	logger := slog.Default()

	tests := []struct {
		name            string
		mockClient      *MockTailscaleClient
		expectedMetrics string
		expectError     bool
	}{
		{
			name: "successful collection with nameservers and magic DNS enabled",
			mockClient: &MockTailscaleClient{
				dnsClient: &MockDNSClient{
					nameservers: []string{"8.8.8.8", "1.1.1.1", "100.100.100.100"},
					preferences: &tailscale.DNSPreferences{
						MagicDNS: true,
					},
				},
			},
			expectedMetrics: `
# HELP tailscale_dns_nameservers_info Tailscale DNS nameservers configuration.
# TYPE tailscale_dns_nameservers_info gauge
tailscale_dns_nameservers_info{nameserver="1.1.1.1"} 1
tailscale_dns_nameservers_info{nameserver="100.100.100.100"} 1
tailscale_dns_nameservers_info{nameserver="8.8.8.8"} 1
# HELP tailscale_dns_magic_dns Tailscale Magic DNS configuration.
# TYPE tailscale_dns_magic_dns gauge
tailscale_dns_magic_dns 1
`,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			collector := &TailscaleDNSCollector{
				log: logger,
			}

			ch := make(chan prometheus.Metric, 10)
			ctx := context.Background()

			err := collector.Update(ctx, tt.mockClient, ch)
			close(ch)

			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}

			// Collect all metrics from the channel
			var metrics []prometheus.Metric
			for metric := range ch {
				metrics = append(metrics, metric)
			}

			// Create a registry and register our metrics
			reg := prometheus.NewRegistry()

			// Create a temporary collector to hold our metrics for comparison
			tempCollector := &TestMetricCollector{metrics: metrics}
			reg.MustRegister(tempCollector)

			// Compare the metrics
			if err := testutil.GatherAndCompare(reg, strings.NewReader(tt.expectedMetrics)); err != nil {
				t.Errorf("metrics mismatch: %v", err)
			}
		})
	}
}
