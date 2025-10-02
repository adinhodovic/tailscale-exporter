{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'tailscale-tailnet-alerts',
        rules: std.prune([
          if $._config.tailscaleDeviceUnauthorizedEnabled then {
            alert: 'TailscaleDeviceUnauthorized',
            expr: |||
              sum(
                tailscale_devices_authorized
              ) by (tailnet, name, id)
              == 0
            ||| % $._config,
            annotations: {
              summary: 'Tailscale Device is Unauthorized',
              description: 'Tailscale Device {{ $labels.name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} is unauthorized. Please authorize it in the Tailscale admin console.',
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + clusterVariableQueryString,
            },
            'for': $._config.tailscaleDeviceUnauthorizedFor,
            labels: {
              severity: $._config.tailscaleDeviceUnauthorizedSeverity,
              mixin: 'tailscale',
            },
          },
          if $._config.tailscaleUserUnapprovedEnabled then {
            alert: 'TailscaleUserUnapproved',
            expr: |||
              sum(
                tailscale_users_info{
                  status="needs-approval"
                }
              ) by (tailnet, login_name, id)
              == 1
            ||| % $._config,
            'for': $._config.tailscaleUserUnapprovedFor,
            annotations: {
              summary: 'Tailscale User is Unapproved',
              description: 'Tailscale User {{ $labels.login_name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} is unapproved. Please approve it in the Tailscale admin console.',
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.tailscaleUserUnapprovedSeverity,
              mixin: 'tailscale',
            },
          },
          if $._config.tailscaleUserRecentlyCreatedEnabled then {
            alert: 'TailscaleUserRecentlyCreated',
            expr: |||
              time() -
              (
                max(
                  tailscale_users_created_timestamp{}
                ) by (tailnet, id, login_name)
              )
              < %(tailscaleUserRecentlyCreatedThreshold)s
            ||| % $._config,
            annotations: {
              summary: 'Tailscale User Recently Created',
              description: 'Tailscale User {{ $labels.login_name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} was created within the last %(tailscaleUserRecentlyCreatedThreshold)s seconds.' % $._config,
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.tailscaleUserRecentlyCreatedSeverity,
              mixin: 'tailscale',
            },
          },
          if $._config.tailscaleDeviceUnapprovedRoutesEnabled then {
            alert: 'TailscaleDeviceUnapprovedRoutes',
            expr: |||
              100 -
              (
                (
                  sum(
                    tailscale_devices_routes_enabled
                  ) by (tailnet, name, id)
                  /
                  sum(
                    tailscale_devices_routes_advertised
                  ) by (tailnet, name, id)
                )
                * 100
              )
              > %(tailscaleDeviceUnapprovedRoutesThreshold)s
            ||| % $._config,
            'for': $._config.tailscaleDeviceUnapprovedRoutesFor,
            annotations: {
              summary: 'Tailscale Device has Unapproved Routes',
              description: 'Tailscale Device {{ $labels.name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} has more than %(tailscaleDeviceUnapprovedRoutesThreshold)s%% unapproved routes for longer than %(tailscaleDeviceUnapprovedRoutesFor)s.' % $._config,
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.tailscaleDeviceUnapprovedRoutesSeverity,
              mixin: 'tailscale',
            },
          },
        ]),
      },
      {
        name: 'tailscaled-machine-alerts',
        rules: std.prune([
          if $._config.tailscaledMachineHighOutboundDroppedPacketsEnabled then {
            alert: 'TailscaledMachineHighOutboundDroppedPackets',
            expr: |||
              sum(
                increase(
                  tailscaled_outbound_dropped_packets_total{}
                  [5m]
                )
              ) by (tailscale_machine)
              /
              sum (
                increase(
                  tailscaled_outbound_packets_total{}
                  [5m]
                )
              ) by (tailscale_machine)
              * 100
              > %(tailscaledMachineHighOutboundDroppedPacketsThreshold)s
            ||| % $._config,
            'for': $._config.tailscaledMachineHighOutboundDroppedPacketsFor,
            annotations: {
              summary: 'Tailscaled Machine has High Outbound Dropped Packets',
              description: 'Tailscaled Machine {{ $labels.tailscale_machine }} has a high rate of outbound dropped packets (>{{ %(tailscaledMachineHighOutboundDroppedPacketsThreshold)s }}%%) for longer than %(tailscaledMachineHighOutboundDroppedPacketsFor)s.' % $._config,
              dashboard_url: $._config.dashboardUrls['tailscale-machine'] + '?var-tailscale_machine={{ $labels.tailscale_machine }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.tailscaledMachineHighOutboundDroppedPacketsSeverity,
              mixin: 'tailscale',
            },
          },
        ]),
      },
    ],
  },
}
