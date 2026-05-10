package iputil

import "testing"

func TestSplitIPs(t *testing.T) {
	tests := []struct {
		name     string
		input    []string
		wantV4   string
		wantV6   string
	}{
		{
			name: "empty",
		},
		{
			name:   "only ipv4",
			input:  []string{"100.64.0.1"},
			wantV4: "100.64.0.1",
		},
		{
			name:   "only ipv6",
			input:  []string{"fd7a:115c:a1e0::1"},
			wantV6: "fd7a:115c:a1e0::1",
		},
		{
			name:   "v4 then v6",
			input:  []string{"100.64.0.1", "fd7a:115c:a1e0::1"},
			wantV4: "100.64.0.1",
			wantV6: "fd7a:115c:a1e0::1",
		},
		{
			name:   "v6 then v4",
			input:  []string{"fd7a:115c:a1e0::1", "100.64.0.1"},
			wantV4: "100.64.0.1",
			wantV6: "fd7a:115c:a1e0::1",
		},
		{
			name:   "first of each family wins",
			input:  []string{"100.64.0.1", "100.64.0.2", "fd7a:115c:a1e0::1", "fd7a:115c:a1e0::2"},
			wantV4: "100.64.0.1",
			wantV6: "fd7a:115c:a1e0::1",
		},
		{
			name:   "skips invalid entries",
			input:  []string{"not-an-ip", "100.64.0.1", "also-bad", "fd7a:115c:a1e0::1"},
			wantV4: "100.64.0.1",
			wantV6: "fd7a:115c:a1e0::1",
		},
		{
			name:   "trims whitespace",
			input:  []string{"  100.64.0.1  ", "\tfd7a:115c:a1e0::1\n"},
			wantV4: "100.64.0.1",
			wantV6: "fd7a:115c:a1e0::1",
		},
		{
			name:   "ipv4-mapped ipv6 normalised to ipv4",
			input:  []string{"::ffff:100.64.0.1"},
			wantV4: "100.64.0.1",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotV4, gotV6 := SplitIPs(tt.input)
			if gotV4 != tt.wantV4 {
				t.Errorf("ipv4: got %q, want %q", gotV4, tt.wantV4)
			}
			if gotV6 != tt.wantV6 {
				t.Errorf("ipv6: got %q, want %q", gotV6, tt.wantV6)
			}
		})
	}
}
