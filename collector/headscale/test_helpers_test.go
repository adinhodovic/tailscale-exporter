package headscale

import (
	"context"
	"io"
	"log/slog"
	"strings"
	"testing"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
)

type mockHeadscaleClient struct {
	users        []*headscalev1.User
	nodes        []*headscalev1.Node
	apiKeys      []*headscalev1.ApiKey
	preAuthKeys  []*headscalev1.PreAuthKey
	healthResp   *headscalev1.HealthResponse
	listUsersErr error
	listNodesErr error
	apiKeysErr   error
	preAuthErr   error
	healthErr    error
}

func (m *mockHeadscaleClient) ListUsers(ctx context.Context) ([]*headscalev1.User, error) {
	if m.listUsersErr != nil {
		return nil, m.listUsersErr
	}
	return m.users, nil
}

func (m *mockHeadscaleClient) ListNodes(ctx context.Context) ([]*headscalev1.Node, error) {
	if m.listNodesErr != nil {
		return nil, m.listNodesErr
	}
	return m.nodes, nil
}

func (m *mockHeadscaleClient) ListAPIKeys(ctx context.Context) ([]*headscalev1.ApiKey, error) {
	if m.apiKeysErr != nil {
		return nil, m.apiKeysErr
	}
	return m.apiKeys, nil
}

func (m *mockHeadscaleClient) ListPreAuthKeys(
	ctx context.Context,
) ([]*headscalev1.PreAuthKey, error) {
	if m.preAuthErr != nil {
		return nil, m.preAuthErr
	}
	return m.preAuthKeys, nil
}

func (m *mockHeadscaleClient) Health(ctx context.Context) (*headscalev1.HealthResponse, error) {
	if m.healthErr != nil {
		return nil, m.healthErr
	}
	return m.healthResp, nil
}

func gatherMetrics(t *testing.T, metrics []prometheus.Metric, expected string) {
	t.Helper()
	reg := prometheus.NewRegistry()
	reg.MustRegister(&testMetricCollector{metrics: metrics})
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Fatalf("metrics mismatch: %v", err)
	}
}

func collectFromCollector(
	t *testing.T,
	collector Collector,
	client HeadscaleClient,
) []prometheus.Metric {
	t.Helper()
	ch := make(chan prometheus.Metric, 64)
	if err := collector.Update(context.Background(), client, ch); err != nil {
		t.Fatalf("collector update failed: %v", err)
	}
	close(ch)
	var metrics []prometheus.Metric
	for metric := range ch {
		metrics = append(metrics, metric)
	}
	return metrics
}

func testLogger(t *testing.T) *slog.Logger {
	t.Helper()
	return slog.New(slog.NewTextHandler(io.Discard, &slog.HandlerOptions{}))
}

type testMetricCollector struct {
	metrics []prometheus.Metric
}

func (c *testMetricCollector) Describe(ch chan<- *prometheus.Desc) {}

func (c *testMetricCollector) Collect(ch chan<- prometheus.Metric) {
	for _, metric := range c.metrics {
		ch <- metric
	}
}
