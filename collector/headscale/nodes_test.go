package headscale

import (
	"testing"
	"time"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func TestHeadscaleNodesCollector_Update(t *testing.T) {
	collector, err := NewHeadscaleNodesCollector(collectorConfig{logger: testLogger(t)})
	if err != nil {
		t.Fatalf("failed to create nodes collector: %v", err)
	}

	node := &headscalev1.Node{
		Id:             1,
		Name:           "node-one",
		User:           &headscalev1.User{Id: 42, Name: "alice"},
		GivenName:      "server-01",
		RegisterMethod: headscalev1.RegisterMethod_REGISTER_METHOD_AUTH_KEY,
		MachineKey:     "mkey:123",
		NodeKey:        "nodekey:abc",
		DiscoKey:       "discokey:def",
		LastSeen:       timestamppb.New(time.Unix(1_700_000_000, 0)),
		CreatedAt:      timestamppb.New(time.Unix(1_690_000_000, 0)),
		Expiry:         timestamppb.New(time.Unix(1_710_000_000, 0)),
		Online:         true,
		ApprovedRoutes: []string{"10.0.0.0/24", "10.0.1.0/24"},
		AvailableRoutes: []string{
			"10.0.0.0/24",
		},
		SubnetRoutes: []string{"0.0.0.0/0"},
		ForcedTags:   []string{"tag:forced"},
		ValidTags:    []string{"tag:valid"},
		InvalidTags:  []string{"tag:invalid"},
	}

	client := &mockHeadscaleClient{
		nodes: []*headscalev1.Node{node},
	}

	metrics := collectFromCollector(t, collector, client)
	expected := `
# HELP headscale_nodes_info Node information
# TYPE headscale_nodes_info gauge
headscale_nodes_info{disco_key="discokey:def",given_name="server-01",id="1",machine_key="mkey:123",name="node-one",node_key="nodekey:abc",register_method="REGISTER_METHOD_AUTH_KEY",user="alice",user_id="42"} 1
# HELP headscale_nodes_last_seen_timestamp Unix timestamp when node was last seen
# TYPE headscale_nodes_last_seen_timestamp gauge
headscale_nodes_last_seen_timestamp{id="1",name="node-one",user="alice"} 1.7e+09
# HELP headscale_nodes_created_timestamp Unix timestamp when node was created
# TYPE headscale_nodes_created_timestamp gauge
headscale_nodes_created_timestamp{id="1",name="node-one",user="alice"} 1.69e+09
# HELP headscale_nodes_expiry_timestamp Unix timestamp when node expires
# TYPE headscale_nodes_expiry_timestamp gauge
headscale_nodes_expiry_timestamp{id="1",name="node-one",user="alice"} 1.71e+09
# HELP headscale_nodes_online Whether node is currently online
# TYPE headscale_nodes_online gauge
headscale_nodes_online{id="1",name="node-one",user="alice"} 1
# HELP headscale_nodes_approved_routes Number of approved routes for the node
# TYPE headscale_nodes_approved_routes gauge
headscale_nodes_approved_routes{id="1",name="node-one",user="alice"} 2
# HELP headscale_nodes_available_routes Number of available routes for the node
# TYPE headscale_nodes_available_routes gauge
headscale_nodes_available_routes{id="1",name="node-one",user="alice"} 1
# HELP headscale_nodes_subnet_routes Number of subnet routes advertised by the node
# TYPE headscale_nodes_subnet_routes gauge
headscale_nodes_subnet_routes{id="1",name="node-one",user="alice"} 1
# HELP headscale_nodes_tags Number of tags grouped by category (forced, valid, invalid)
# TYPE headscale_nodes_tags gauge
headscale_nodes_tags{category="forced",id="1",name="node-one",user="alice"} 1
headscale_nodes_tags{category="invalid",id="1",name="node-one",user="alice"} 1
headscale_nodes_tags{category="valid",id="1",name="node-one",user="alice"} 1
`
	gatherMetrics(t, metrics, expected)
}
