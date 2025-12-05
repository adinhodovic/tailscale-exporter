package headscale

import (
	"testing"
	"time"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func TestHeadscaleAPIKeysCollector_Update(t *testing.T) {
	collector, err := NewHeadscaleAPIKeysCollector(collectorConfig{logger: testLogger(t)})
	if err != nil {
		t.Fatalf("failed to create API keys collector: %v", err)
	}

	apiKey := &headscalev1.ApiKey{
		Id:         7,
		Prefix:     "abcd",
		CreatedAt:  timestamppb.New(time.Unix(1_600_000_000, 0)),
		Expiration: timestamppb.New(time.Unix(1_650_000_000, 0)),
		LastSeen:   timestamppb.New(time.Unix(1_640_000_000, 0)),
	}

	client := &mockHeadscaleClient{
		apiKeys: []*headscalev1.ApiKey{apiKey},
	}

	metrics := collectFromCollector(t, collector, client)
	expected := `
# HELP headscale_apikeys_info API key metadata
# TYPE headscale_apikeys_info gauge
headscale_apikeys_info{id="7",prefix="abcd"} 1
# HELP headscale_apikeys_created_timestamp Unix timestamp when the API key was created
# TYPE headscale_apikeys_created_timestamp gauge
headscale_apikeys_created_timestamp{id="7",prefix="abcd"} 1.6e+09
# HELP headscale_apikeys_expiration_timestamp Unix timestamp when the API key expires
# TYPE headscale_apikeys_expiration_timestamp gauge
headscale_apikeys_expiration_timestamp{id="7",prefix="abcd"} 1.65e+09
# HELP headscale_apikeys_last_seen_timestamp Unix timestamp when the API key was last used
# TYPE headscale_apikeys_last_seen_timestamp gauge
headscale_apikeys_last_seen_timestamp{id="7",prefix="abcd"} 1.64e+09
`
	gatherMetrics(t, metrics, expected)
}
