package collector

import (
	"context"

	"github.com/prometheus/client_golang/prometheus"
	"tailscale.com/client/tailscale/v2"
)

// testMetricCollector is a helper collector that holds pre-collected metrics for testing
type TestMetricCollector struct {
	metrics []prometheus.Metric
}

func (c *TestMetricCollector) Describe(ch chan<- *prometheus.Desc) {
	// We don't need to describe since we're using pre-collected metrics
}

func (c *TestMetricCollector) Collect(ch chan<- prometheus.Metric) {
	for _, metric := range c.metrics {
		ch <- metric
	}
}

// MockKeysClient implements the KeysAPI interface for testing
type MockKeysClient struct {
	keys    []tailscale.Key
	keysErr error
}

func (m *MockKeysClient) List(ctx context.Context, all bool) ([]tailscale.Key, error) {
	if m.keysErr != nil {
		return nil, m.keysErr
	}
	return m.keys, nil
}

// MockDNSClient implements the DNSAPI interface for testing
type MockDNSClient struct {
	nameservers    []string
	nameserversErr error
	preferences    *tailscale.DNSPreferences
	preferencesErr error
}

func (m *MockDNSClient) Nameservers(ctx context.Context) ([]string, error) {
	if m.nameserversErr != nil {
		return nil, m.nameserversErr
	}
	return m.nameservers, nil
}

func (m *MockDNSClient) Preferences(ctx context.Context) (*tailscale.DNSPreferences, error) {
	if m.preferencesErr != nil {
		return nil, m.preferencesErr
	}
	return m.preferences, nil
}

// MockDevicesClient implements the DevicesAPI interface for testing
type MockDevicesClient struct {
	devices    []tailscale.Device
	devicesErr error
}

func (m *MockDevicesClient) List(ctx context.Context) ([]tailscale.Device, error) {
	if m.devicesErr != nil {
		return nil, m.devicesErr
	}
	return m.devices, nil
}

// MockUsersClient implements the UsersAPI interface for testing
type MockUsersClient struct {
	users    []tailscale.User
	usersErr error
}

func (m *MockUsersClient) List(
	ctx context.Context,
	userType *tailscale.UserType,
	role *tailscale.UserRole,
) ([]tailscale.User, error) {
	if m.usersErr != nil {
		return nil, m.usersErr
	}
	return m.users, nil
}

// MockTailnetSettingsClient implements the TailnetSettingsAPI interface for testing
type MockTailnetSettingsClient struct {
	settings    *tailscale.TailnetSettings
	settingsErr error
}

func (m *MockTailnetSettingsClient) Get(ctx context.Context) (*tailscale.TailnetSettings, error) {
	if m.settingsErr != nil {
		return nil, m.settingsErr
	}
	return m.settings, nil
}

// MockTailscaleClient implements the TailscaleClient interface for testing
type MockTailscaleClient struct {
	dnsClient             *MockDNSClient
	keysClient            *MockKeysClient
	devicesClient         *MockDevicesClient
	usersClient           *MockUsersClient
	tailnetSettingsClient *MockTailnetSettingsClient
}

func (m *MockTailscaleClient) DNS() DNSAPI {
	return m.dnsClient
}

func (m *MockTailscaleClient) Keys() KeysAPI {
	return m.keysClient
}

func (m *MockTailscaleClient) Devices() DevicesAPI {
	return m.devicesClient
}

func (m *MockTailscaleClient) Users() UsersAPI {
	return m.usersClient
}

func (m *MockTailscaleClient) TailnetSettings() TailnetSettingsAPI {
	return m.tailnetSettingsClient
}
