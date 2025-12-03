package headscale

import (
	"testing"
	"time"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func TestHeadscaleUsersCollector_Update(t *testing.T) {
	collector, err := NewHeadscaleUsersCollector(collectorConfig{logger: testLogger(t)})
	if err != nil {
		t.Fatalf("failed to create users collector: %v", err)
	}

	user := &headscalev1.User{
		Id:          42,
		Name:        "alice",
		DisplayName: "Alice Example",
		Email:       "alice@example.com",
		Provider:    "oidc",
		ProviderId:  "provider-123",
		CreatedAt:   timestamppb.New(time.Unix(1_680_000_000, 0)),
	}

	client := &mockHeadscaleClient{
		users: []*headscalev1.User{user},
	}

	metrics := collectFromCollector(t, collector, client)
	expected := `
# HELP headscale_users_info User information and metadata
# TYPE headscale_users_info gauge
headscale_users_info{display_name="Alice Example",email="alice@example.com",id="42",name="alice",provider="oidc",provider_id="provider-123"} 1
# HELP headscale_users_created_timestamp Unix timestamp when the user was created
# TYPE headscale_users_created_timestamp gauge
headscale_users_created_timestamp{id="42",name="alice"} 1.68e+09
`
	gatherMetrics(t, metrics, expected)
}
