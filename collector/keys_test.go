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


func TestTailscaleKeysCollector_Update(t *testing.T) {
	logger := slog.Default()

	tests := []struct {
		name            string
		mockClient      *MockTailscaleClient
		expectedMetrics string
		expectError     bool
	}{
		{
			name: "successful collection with keys",
			mockClient: &MockTailscaleClient{
				keysClient: &MockKeysClient{
					keys: []tailscale.Key{
						{
							ID:      "key-123",
							KeyType: "auth",
							UserID:  "user-456",
							Created: time.Time{},
							Expires: time.Time{},
						},
					},
				},
			},
			expectedMetrics: `
# HELP tailscale_keys_info Key information.
# TYPE tailscale_keys_info gauge
tailscale_keys_info{id="key-123",key_type="auth",user_id="user-456"} 1
# HELP tailscale_keys_created_timestamp Timestamp when the key was created.
# TYPE tailscale_keys_created_timestamp gauge
tailscale_keys_created_timestamp{id="key-123",key_type="auth",user_id="user-456"} -62135596800
# HELP tailscale_keys_expires_timestamp Timestamp when the key expires.
# TYPE tailscale_keys_expires_timestamp gauge
tailscale_keys_expires_timestamp{id="key-123",key_type="auth",user_id="user-456"} -62135596800
`,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			collector := &TailscaleKeysCollector{
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
