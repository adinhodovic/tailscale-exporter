package collector

import (
	"context"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"tailscale.com/client/tailscale/v2"
)

func TestTailscaleUsersCollector_Update(t *testing.T) {
	logger := slog.Default()

	tests := []struct {
		name            string
		mockClient      *MockTailscaleClient
		expectedMetrics string
		expectError     bool
	}{
		{
			name: "successful collection with users",
			mockClient: &MockTailscaleClient{
				usersClient: &MockUsersClient{
					users: []tailscale.User{
						{
							ID:                 "user-456",
							DisplayName:        "User One",
							LoginName:          "user",
							ProfilePicURL:      "https://example.com/pic.jpg",
							TailnetID:          "tailnet-789",
							Created:            time.Unix(1610000000, 0),
							Type:               "member",
							Role:               "admin",
							Status:             "active",
							DeviceCount:        2,
							LastSeen:           time.Unix(1620000000, 0),
							CurrentlyConnected: true,
						},
					},
				},
			},
			expectedMetrics: `
# HELP tailscale_users_created_timestamp Unix timestamp when user was created
# TYPE tailscale_users_created_timestamp gauge
tailscale_users_created_timestamp{display_name="User One",id="user-456",login_name="user"} 1.61e+09
# HELP tailscale_users_currently_logged_in Whether user is currently logged in
# TYPE tailscale_users_currently_logged_in gauge
tailscale_users_currently_logged_in{display_name="User One",id="user-456",login_name="user"} 1
# HELP tailscale_users_info Users information and status
# TYPE tailscale_users_info gauge
tailscale_users_info{display_name="User One",id="user-456",login_name="user",role="member",status="admin",type="active"} 1
# HELP tailscale_users_last_seen_timestamp Unix timestamp when user was last seen
# TYPE tailscale_users_last_seen_timestamp gauge
tailscale_users_last_seen_timestamp{display_name="User One",id="user-456",login_name="user"} 1.62e+09
`,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			collector := &TailscaleUsersCollector{
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
