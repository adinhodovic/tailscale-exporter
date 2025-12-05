package headscale

import (
	"strconv"

	"google.golang.org/protobuf/types/known/timestamppb"
)

func boolAsFloat(b bool) float64 {
	if b {
		return 1
	}
	return 0
}

func timestampToFloat(ts *timestamppb.Timestamp) float64 {
	if ts == nil {
		return 0
	}
	return float64(ts.AsTime().Unix())
}

func formatUint(v uint64) string {
	return strconv.FormatUint(v, 10)
}

func formatBoolLabel(v bool) string {
	if v {
		return "true"
	}
	return "false"
}

func formatStringSliceLabel(v []string) string {
	if len(v) == 0 {
		return ""
	}
	result := v[0]
	for _, s := range v[1:] {
		result += "," + s
	}
	return result
}
