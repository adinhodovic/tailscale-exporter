package collector

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/Masterminds/semver/v3"
)

// normalizeVersion normalizes Tailscale client versions to proper semver format without v prefix.
// Examples:
//   - "1.86.2-td72494bac" -> "1.86.2"
//   - "1.86.4-t3149aad97-g320ff0bef" -> "1.86.4"
//   - "1.86" -> "1.86.0"
//   - "v1.86.2" -> "1.86.2" (v prefix removed)
func normalizeVersion(version string) string {
	if version == "" {
		return ""
	}

	// Remove v prefix if present
	v := strings.TrimPrefix(version, "v")

	// Extract base version (everything before first dash or plus)
	// This handles cases like "1.86.2-td72494bac" or "1.86.4-t3149aad97-g320ff0bef"
	baseVersionRegex := regexp.MustCompile(`^(\d+\.\d+(?:\.\d+)?)`)
	matches := baseVersionRegex.FindStringSubmatch(v)
	if len(matches) >= 2 {
		baseVersion := matches[1]
		// Try to parse the base version
		parsed, err := semver.NewVersion(baseVersion)
		if err == nil {
			return parsed.String()
		}
	}

	// If regex extraction failed, try to parse directly and extract core version
	parsed, err := semver.NewVersion(v)
	if err == nil {
		// Extract just the major.minor.patch, ignoring prerelease and metadata
		coreVersion := fmt.Sprintf("%d.%d.%d", parsed.Major(), parsed.Minor(), parsed.Patch())
		return coreVersion
	}

	// If we can't parse at all, return empty string
	return ""
}
