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

func TestTailnetSettingsCollector_Update(t *testing.T) {
	logger := slog.Default()

	tests := []struct {
		name            string
		mockClient      *MockTailscaleClient
		expectedMetrics string
		expectError     bool
	}{
		{
			name: "successful collection with tailnet settings",
			mockClient: &MockTailscaleClient{
				tailnetSettingsClient: &MockTailnetSettingsClient{
					settings: &tailscale.TailnetSettings{
						ACLsExternallyManagedOn:                true,
						ACLsExternalLink:                       "https://example.com/acls",
						DevicesApprovalOn:                      true,
						DevicesAutoUpdatesOn:                   true,
						DevicesKeyDurationDays:                 90,
						UsersApprovalOn:                        true,
						UsersRoleAllowedToJoinExternalTailnets: "admin",
						NetworkFlowLoggingOn:                   true,
						RegionalRoutingOn:                      false,
						PostureIdentityCollectionOn:            true,
					},
				},
			},
			expectedMetrics: `
# HELP tailscale_tailnet_settings_devices_key_duration_days Number of days before device key expiry.
# TYPE tailscale_tailnet_settings_devices_key_duration_days gauge
tailscale_tailnet_settings_devices_key_duration_days 90
# HELP tailscale_tailnet_settings_info Information about the Tailscale Tailnet settings.
# TYPE tailscale_tailnet_settings_info gauge
tailscale_tailnet_settings_info{acls_external_link="https://example.com/acls",acls_externally_managed_on="true",devices_approval_on="true",devices_auto_updates_on="true",network_flow_logging_on="true",posture_identity_collection_on="true",regional_routing_on="false",users_approval_on="true",users_role_allowed_to_join_external_tailnets="admin"} 1
`,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			collector := &TailscaleTailnetSettingsCollector{
				log: logger,
			}

			// Buffer must be >= number of metrics emitted per device (currently 12) to avoid blocking Update.
			// Using a generous buffer to be resilient to future additions.
			ch := make(chan prometheus.Metric, 32)
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
