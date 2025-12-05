package headscale

import (
	"testing"
	"time"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func TestHeadscalePreAuthKeysCollector_Update(t *testing.T) {
	collector, err := NewHeadscalePreAuthKeysCollector(collectorConfig{logger: testLogger(t)})
	if err != nil {
		t.Fatalf("failed to create pre-auth keys collector: %v", err)
	}

	key := &headscalev1.PreAuthKey{
		User:      &headscalev1.User{Id: 42, Name: "alice"},
		Id:        9,
		Key:       "tskey-xyz",
		Reusable:  true,
		Ephemeral: false,
		Used:      false,
		CreatedAt: timestamppb.New(time.Unix(1_550_000_000, 0)),
		Expiration: timestamppb.New(
			time.Unix(1_560_000_000, 0),
		),
	}

	client := &mockHeadscaleClient{
		preAuthKeys: []*headscalev1.PreAuthKey{key},
	}

	metrics := collectFromCollector(t, collector, client)
	expected := `
# HELP headscale_preauthkeys_info Pre-auth key metadata
# TYPE headscale_preauthkeys_info gauge
headscale_preauthkeys_info{acl_tags="",ephemeral="false",id="9",reusable="true",used="false",user="alice"} 1
# HELP headscale_preauthkeys_created_timestamp Unix timestamp when the pre-auth key was created
# TYPE headscale_preauthkeys_created_timestamp gauge
headscale_preauthkeys_created_timestamp{id="9",user="alice"} 1.55e+09
# HELP headscale_preauthkeys_expiration_timestamp Unix timestamp when the pre-auth key expires
# TYPE headscale_preauthkeys_expiration_timestamp gauge
headscale_preauthkeys_expiration_timestamp{id="9",user="alice"} 1.56e+09
`
	gatherMetrics(t, metrics, expected)
}
