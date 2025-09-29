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

func TestTailscaleDevicesCollector_Update(t *testing.T) {
	logger := slog.Default()

	tests := []struct {
		name            string
		mockClient      *MockTailscaleClient
		expectedMetrics string
		expectError     bool
	}{
		{
			name: "successful collection with devices",
			mockClient: &MockTailscaleClient{
				devicesClient: &MockDevicesClient{
					devices: []tailscale.Device{
						{
							ID:                        "device-123",
							NodeID:                    "node-456",
							Name:                      "Device One",
							Hostname:                  "device-one",
							User:                      "user-456",
							OS:                        "linux",
							ClientVersion:             "1.32.0",
							Authorized:                true,
							IsExternal:                false,
							UpdateAvailable:           false,
							KeyExpiryDisabled:         false,
							BlocksIncomingConnections: false,
							Addresses:                 []string{"100.64.0.1", "fd7a:115c:a1e0:ab12:4843:cd96:6255:6a6a"},
							Created:                   tailscale.Time{Time: time.Unix(1609459200, 0)},
							LastSeen:                  tailscale.Time{Time: time.Unix(1612137600, 0)},
							Expires:                   tailscale.Time{Time: time.Unix(1640995200, 0)},
							MachineKey:                "mkey:abcd1234",
							NodeKey:                   "nodekey:efgh5678",
							AdvertisedRoutes:          []string{"192.168.1.0/24"},
							EnabledRoutes:             []string{"192.168.1.0/24"},
							ClientConnectivity: &tailscale.ClientConnectivity{
								DERPLatency: map[string]tailscale.DERPRegion{
									"nyc": {LatencyMilliseconds: 50},
									"lax": {LatencyMilliseconds: 100},
								},
							},
						},
					},
				},
			},
			expectedMetrics: `
# HELP tailscale_devices_info Device information
# TYPE tailscale_devices_info gauge
tailscale_devices_info{client_version="1.32.0",hostname="device-one",id="device-123",machine_key="mkey:abcd1234",name="Device One",node_key="nodekey:efgh5678",os="linux",tailscale_ip="100.64.0.1",user="user-456"} 1
# HELP tailscale_devices_online Whether device is online (last seen within 5 minutes)
# TYPE tailscale_devices_online gauge
tailscale_devices_online{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 0
# HELP tailscale_devices_authorized Whether device is authorized
# TYPE tailscale_devices_authorized gauge
tailscale_devices_authorized{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 1
# HELP tailscale_devices_external Whether device is external
# TYPE tailscale_devices_external gauge
tailscale_devices_external{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 0
# HELP tailscale_devices_update_available Whether device has update available
# TYPE tailscale_devices_update_available gauge
tailscale_devices_update_available{client_version="1.32.0",hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 0
# HELP tailscale_devices_key_expiry_disabled Whether device key expiry is disabled
# TYPE tailscale_devices_key_expiry_disabled gauge
tailscale_devices_key_expiry_disabled{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 0
# HELP tailscale_devices_blocks_incoming Whether device blocks incoming connections
# TYPE tailscale_devices_blocks_incoming gauge
tailscale_devices_blocks_incoming{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 0
# HELP tailscale_devices_last_seen_timestamp Unix timestamp when device was last seen
# TYPE tailscale_devices_last_seen_timestamp gauge
tailscale_devices_last_seen_timestamp{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 1.6121376e+09
# HELP tailscale_devices_latency_ms Device latency in milliseconds
# TYPE tailscale_devices_latency_ms gauge
tailscale_devices_latency_ms{derp_region="lax",hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 100
tailscale_devices_latency_ms{derp_region="nyc",hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 50
# HELP tailscale_devices_expires_timestamp Unix timestamp when device key expires
# TYPE tailscale_devices_expires_timestamp gauge
tailscale_devices_expires_timestamp{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 1.6409952e+09
# HELP tailscale_devices_created_timestamp Unix timestamp when device was created
# TYPE tailscale_devices_created_timestamp gauge
tailscale_devices_created_timestamp{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 1.6094592e+09
# HELP tailscale_devices_routes_advertised Number of routes advertised by device
# TYPE tailscale_devices_routes_advertised gauge
tailscale_devices_routes_advertised{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 1
# HELP tailscale_devices_routes_enabled Number of routes enabled for device
# TYPE tailscale_devices_routes_enabled gauge
tailscale_devices_routes_enabled{hostname="device-one",id="device-123",name="Device One",os="linux",user="user-456"} 1
`,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			collector := &TailscaleDevicesCollector{
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
