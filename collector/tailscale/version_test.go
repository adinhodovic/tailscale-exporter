package tailscale

import (
	"testing"
)

func TestNormalizeVersion(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "tailscale version with build info",
			input:    "1.86.2-td72494bac",
			expected: "1.86.2",
		},
		{
			name:     "tailscale version with multiple build components",
			input:    "1.86.4-t3149aad97-g320ff0bef",
			expected: "1.86.4",
		},
		{
			name:     "major.minor only",
			input:    "1.86",
			expected: "1.86.0",
		},
		{
			name:     "already prefixed with v",
			input:    "v1.86.2",
			expected: "1.86.2",
		},
		{
			name:     "already normalized semver",
			input:    "v1.86.2-pre+build",
			expected: "1.86.2",
		},
		{
			name:     "standard semver",
			input:    "1.2.3",
			expected: "1.2.3",
		},
		{
			name:     "empty string",
			input:    "",
			expected: "",
		},
		{
			name:     "invalid version",
			input:    "not-a-version",
			expected: "",
		},
		{
			name:     "version with patch zero",
			input:    "1.86.0-td72494bac",
			expected: "1.86.0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := normalizeVersion(tt.input)
			if result != tt.expected {
				t.Errorf("normalizeVersion(%q) = %q, expected %q", tt.input, result, tt.expected)
			}
		})
	}
}
