package headscale

import (
	"testing"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
)

func TestHeadscaleHealthCollector_Update(t *testing.T) {
	collector, err := NewHeadscaleHealthCollector(collectorConfig{logger: testLogger(t)})
	if err != nil {
		t.Fatalf("failed to create health collector: %v", err)
	}

	client := &mockHeadscaleClient{
		healthResp: &headscalev1.HealthResponse{
			DatabaseConnectivity: true,
		},
	}

	metrics := collectFromCollector(t, collector, client)
	expected := `
# HELP headscale_health_database_connectivity Whether Headscale reports healthy database connectivity
# TYPE headscale_health_database_connectivity gauge
headscale_health_database_connectivity 1
`
	gatherMetrics(t, metrics, expected)
}
