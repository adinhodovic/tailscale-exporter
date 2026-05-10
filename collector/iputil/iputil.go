package iputil

import (
	"net/netip"
	"strings"
)

// SplitIPs separates a mixed list of IP addresses into the first IPv4 and first
// IPv6 address, returning empty strings for any that are not present. Unparseable
// entries are skipped. IPv4-in-IPv6 mapped addresses are normalised to IPv4.
func SplitIPs(ips []string) (ipv4, ipv6 string) {
	for _, raw := range ips {
		addr, err := netip.ParseAddr(strings.TrimSpace(raw))
		if err != nil {
			continue
		}
		addr = addr.Unmap()
		if addr.Is4() && ipv4 == "" {
			ipv4 = addr.String()
		} else if addr.Is6() && ipv6 == "" {
			ipv6 = addr.String()
		}
		if ipv4 != "" && ipv6 != "" {
			break
		}
	}
	return ipv4, ipv6
}
