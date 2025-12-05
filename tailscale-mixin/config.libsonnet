{
  _config+:: {
    local this = self,

    tailscaleSelector: 'job="tailscale-exporter"',
    // This selector is anything for now as scraping machines can vary in label names.
    tailscaledSelector: 'job=~".*"',

    // Default datasource name
    datasourceName: 'default',

    // Opt-in to multiCluster dashboards by overriding this and the clusterLabel.
    showMultiCluster: false,
    clusterLabel: 'cluster',

    grafanaUrl: 'https://grafana.com',

    dashboardIds: {
      'headscale-overview': 'headscale-mixin-over-k12e',
      'tailscale-overview': 'tailscale-mixin-over-k12e',
      'tailscale-machine': 'tailscaled-mixin-over-k12e',
    },
    dashboardUrls: {
      'headscale-overview': '%s/d/%s/headscale-overview' % [this.grafanaUrl, this.dashboardIds['headscale-overview']],
      'tailscale-overview': '%s/d/%s/tailscale-overview' % [this.grafanaUrl, this.dashboardIds['tailscale-overview']],
      'tailscale-machine': '%s/d/%s/tailscale-machine' % [this.grafanaUrl, this.dashboardIds['tailscale-machine']],
    },

    // Alert configuration
    alerts: {
      enabled: true,

      // Tailnet alerts
      tailscaleDeviceUnauthorized: {
        enabled: true,
        severity: 'warning',
        interval: '15m',
      },

      tailscaleUserUnapproved: {
        enabled: true,
        severity: 'warning',
        interval: '15m',
      },

      tailscaleUserRecentlyCreated: {
        enabled: true,
        severity: 'info',
        threshold: '300',  // seconds
      },

      tailscaleDeviceUnapprovedRoutes: {
        enabled: true,
        severity: 'warning',
        interval: '15m',
        threshold: '10',
      },

      // Headscale alerts
      headscaleDatabaseDown: {
        enabled: true,
        severity: 'critical',
        interval: '5m',
      },

      headscaleNodeUnapprovedRoutes: {
        enabled: true,
        severity: 'warning',
        interval: '15m',
        threshold: '10',  // percent of unapproved routes
      },

      // Tailscaled alerts
      tailscaledMachineHighOutboundDroppedPackets: {
        enabled: true,
        severity: 'warning',
        interval: '15m',
        threshold: '50',  // percent
      },
    },

    tags: ['tailscale', 'headscale', 'tailscaled', 'tailscale-mixin'],

    // Custom annotations to display in graphs
    annotation: {
      enabled: false,
      name: 'Custom Annotation',
      tags: [],
      datasource: '-- Grafana --',
      iconColor: 'blue',
      type: 'tags',
    },
  },
}
