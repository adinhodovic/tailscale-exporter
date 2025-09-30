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
        ]),
      },
      {
        name: 'tailscaled-machine-alerts',
        rules: std.prune([
          if $._config.tailscaledMachineUnapprovedRoutesEnabled then {
            alert: 'TailscaledMachineUnapprovedRoutes',
            expr: |||
              100 -
              (
                (
                  sum(
                    tailscaled_approved_routes
                  ) by (tailscale_machine)
                  /
                  sum(
                    tailscaled_advertised_routes
                  ) by (tailscale_machine)
                )
                * 100
              )
              > %(tailscaledMachineUnapprovedRoutesThreshold)s
            ||| % $._config,
            'for': $._config.tailscaledMachineUnapprovedRoutesFor,
            annotations: {
              summary: 'Tailscaled Machine has Unapproved Routes',
              description: 'Tailscaled Machine {{ $labels.tailscale_machine }} has unapproved routes for longer than %(tailscaledMachineUnapprovedRoutesFor)s.' % $._config,
              dashboard_url: $._config.dashboardUrls['tailscale-machine'] + '?var-tailscale_machine={{ $labels.tailscale_machine }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.tailscaledMachineUnapprovedRoutesSeverity,
              mixin: 'tailscale',
            },
          },
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
