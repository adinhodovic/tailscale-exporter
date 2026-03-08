package headscale

import (
	"testing"
	"time"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func TestHeadscalePreAuthKeysCollector_Update_MultipleUsers(t *testing.T) {
	collector, err := NewHeadscalePreAuthKeysCollector(collectorConfig{logger: testLogger(t)})
	if err != nil {
		t.Fatalf("failed to create pre-auth keys collector: %v", err)
	}

	client := &mockHeadscaleClient{
		preAuthKeys: []*headscalev1.PreAuthKey{
			{
				User:       &headscalev1.User{Id: 1, Name: "alice"},
				Id:         1,
				Reusable:   false,
				Ephemeral:  false,
				Used:       true,
				CreatedAt:  timestamppb.New(time.Unix(1_600_000_000, 0)),
				Expiration: timestamppb.New(time.Unix(1_600_003_600, 0)),
			},
			{
				User:       &headscalev1.User{Id: 2, Name: "bob"},
				Id:         2,
				Reusable:   true,
				Ephemeral:  true,
				Used:       false,
				CreatedAt:  timestamppb.New(time.Unix(1_700_000_000, 0)),
				Expiration: timestamppb.New(time.Unix(1_700_003_600, 0)),
			},
		},
	}

	metrics := collectFromCollector(t, collector, client)
	expected := `
# HELP headscale_preauthkeys_info Pre-auth key metadata
# TYPE headscale_preauthkeys_info gauge
headscale_preauthkeys_info{acl_tags="",ephemeral="false",id="1",reusable="false",used="true",user="alice"} 1
headscale_preauthkeys_info{acl_tags="",ephemeral="true",id="2",reusable="true",used="false",user="bob"} 1
# HELP headscale_preauthkeys_created_timestamp Unix timestamp when the pre-auth key was created
# TYPE headscale_preauthkeys_created_timestamp gauge
headscale_preauthkeys_created_timestamp{id="1",user="alice"} 1.6e+09
headscale_preauthkeys_created_timestamp{id="2",user="bob"} 1.7e+09
# HELP headscale_preauthkeys_expiration_timestamp Unix timestamp when the pre-auth key expires
# TYPE headscale_preauthkeys_expiration_timestamp gauge
headscale_preauthkeys_expiration_timestamp{id="1",user="alice"} 1.600003600e+09
headscale_preauthkeys_expiration_timestamp{id="2",user="bob"} 1.700003600e+09
`
	gatherMetrics(t, metrics, expected)
}

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
