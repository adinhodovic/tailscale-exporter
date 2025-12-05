{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'tailscale-tailnet-alerts',
        rules: if $._config.alerts.enabled then std.prune([
          if $._config.alerts.tailscaleDeviceUnauthorized.enabled then {
            alert: 'TailscaleDeviceUnauthorized',
            expr: |||
              sum(
                tailscale_devices_authorized
              ) by (%(clusterLabel)s, namespace, job, tailnet, name, id)
              == 0
            ||| % $._config,
            'for': $._config.alerts.tailscaleDeviceUnauthorized.interval,
            annotations: {
              summary: 'Tailscale Device is Unauthorized',
              description: 'Tailscale Device {{ $labels.name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} is unauthorized. Please authorize it in the Tailscale admin console.',
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + '?var-namespace={{ $labels.namespace }}&var-tailnet={{ $labels.tailnet }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.tailscaleDeviceUnauthorized.severity,
              mixin: 'tailscale',
            },
          },
          if $._config.alerts.tailscaleUserUnapproved.enabled then {
            alert: 'TailscaleUserUnapproved',
            expr: |||
              sum(
                tailscale_users_info{
                  status="needs-approval"
                }
              ) by (%(clusterLabel)s, namespace, job, tailnet, login_name, id)
              == 1
            ||| % $._config,
            'for': $._config.alerts.tailscaleUserUnapproved.interval,
            annotations: {
              summary: 'Tailscale User is Unapproved',
              description: 'Tailscale User {{ $labels.login_name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} is unapproved. Please approve it in the Tailscale admin console.',
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + '?var-namespace={{ $labels.namespace }}&var-tailnet={{ $labels.tailnet }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.tailscaleUserUnapproved.severity,
              mixin: 'tailscale',
            },
          },
          if $._config.alerts.tailscaleUserRecentlyCreated.enabled then {
            alert: 'TailscaleUserRecentlyCreated',
            expr: |||
              time() -
              (
                max(
                  tailscale_users_created_timestamp{}
                ) by (%(clusterLabel)s, namespace, job, tailnet, id, login_name)
              )
              < %(threshold)s
            ||| % ($._config + $._config.alerts.tailscaleUserRecentlyCreated),
            annotations: {
              summary: 'Tailscale User Recently Created',
              description: 'Tailscale User {{ $labels.login_name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} was created within the last %(threshold)s seconds.' % $._config.alerts.tailscaleUserRecentlyCreated,
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + '?var-namespace={{ $labels.namespace }}&var-tailnet={{ $labels.tailnet }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.tailscaleUserRecentlyCreated.severity,
              mixin: 'tailscale',
            },
          },
          if $._config.alerts.tailscaleDeviceUnapprovedRoutes.enabled then {
            alert: 'TailscaleDeviceUnapprovedRoutes',
            expr: |||
              100 -
              (
                (
                  sum(
                    tailscale_devices_routes_enabled
                  ) by (%(clusterLabel)s, namespace, job, tailnet, name, id)
                  /
                  sum(
                    tailscale_devices_routes_advertised
                  ) by (%(clusterLabel)s, namespace, job, tailnet, name, id)
                )
                * 100
              )
              > %(threshold)s
            ||| % ($._config + $._config.alerts.tailscaleDeviceUnapprovedRoutes),
            'for': $._config.alerts.tailscaleDeviceUnapprovedRoutes.interval,
            annotations: {
              summary: 'Tailscale Device has Unapproved Routes',
              description: 'Tailscale Device {{ $labels.name }} (ID: {{ $labels.id }}) in Tailnet {{ $labels.tailnet }} has more than %(threshold)s%% unapproved routes for longer than %(interval)s.' % $._config.alerts.tailscaleDeviceUnapprovedRoutes,
              dashboard_url: $._config.dashboardUrls['tailscale-overview'] + '?var-namespace={{ $labels.namespace }}&var-tailnet={{ $labels.tailnet }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.tailscaleDeviceUnapprovedRoutes.severity,
              mixin: 'tailscale',
            },
          },
        ]) else [],
      },
      {
        name: 'headscale-alerts',
        rules: if $._config.alerts.enabled then std.prune([
          if $._config.alerts.headscaleDatabaseDown.enabled then {
            alert: 'HeadscaleDatabaseDown',
            expr: |||
              max(
                headscale_health_database_connectivity{}
              ) by (%(clusterLabel)s, namespace, job)
              == 0
            ||| % $._config,
            'for': $._config.alerts.headscaleDatabaseDown.interval,
            annotations: {
              summary: 'Headscale Database Connectivity Lost',
              description: 'Headscale instance in namespace {{ $labels.namespace }} has lost database connectivity for longer than %(interval)s.' % $._config.alerts.headscaleDatabaseDown,
              dashboard_url: $._config.dashboardUrls['headscale-overview'] + '?var-namespace={{ $labels.namespace }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.headscaleDatabaseDown.severity,
              mixin: 'headscale',
            },
          },
          if $._config.alerts.headscaleNodeUnapprovedRoutes.enabled then {
            alert: 'HeadscaleNodeUnapprovedRoutes',
            expr: |||
              100 -
              (
                (
                  sum(
                    headscale_nodes_approved_routes{}
                  ) by (%(clusterLabel)s, namespace, job, name, user)
                  /
                  sum(
                    headscale_nodes_available_routes{}
                  ) by (%(clusterLabel)s, namespace, job, name, user)
                )
                * 100
              )
              > %(threshold)s
            ||| % ($._config + $._config.alerts.headscaleNodeUnapprovedRoutes),
            'for': $._config.alerts.headscaleNodeUnapprovedRoutes.interval,
            annotations: {
              summary: 'Headscale Node has Unapproved Routes',
              description: 'Headscale node {{ $labels.name }} (user: {{ $labels.user }}) in namespace {{ $labels.namespace }} has more than %(threshold)s%% unapproved routes for longer than %(interval)s.' % $._config.alerts.headscaleNodeUnapprovedRoutes,
              dashboard_url: $._config.dashboardUrls['headscale-overview'] + '?var-namespace={{ $labels.namespace }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.headscaleNodeUnapprovedRoutes.severity,
              mixin: 'headscale',
            },
          },
        ]) else [],
      },
      {
        name: 'tailscaled-machine-alerts',
        rules: if $._config.alerts.enabled then std.prune([
          if $._config.alerts.tailscaledMachineHighOutboundDroppedPackets.enabled then {
            alert: 'TailscaledMachineHighOutboundDroppedPackets',
            expr: |||
              sum(
                increase(
                  tailscaled_outbound_dropped_packets_total{}
                  [5m]
                )
              ) by (%(clusterLabel)s, job, tailscale_machine)
              /
              sum (
                increase(
                  tailscaled_outbound_packets_total{}
                  [5m]
                )
              ) by (%(clusterLabel)s, job, tailscale_machine)
              * 100
              > %(threshold)s
            ||| % ($._config + $._config.alerts.tailscaledMachineHighOutboundDroppedPackets),
            'for': $._config.alerts.tailscaledMachineHighOutboundDroppedPackets.interval,
            annotations: {
              summary: 'Tailscaled Machine has High Outbound Dropped Packets',
              description: 'Tailscaled Machine {{ $labels.tailscale_machine }} has a high rate of outbound dropped packets (>{{ %(threshold)s }}%%) for longer than %(interval)s.' % $._config.alerts.tailscaledMachineHighOutboundDroppedPackets,
              dashboard_url: $._config.dashboardUrls['tailscale-machine'] + '?var-tailscale_machine={{ $labels.tailscale_machine }}' + clusterVariableQueryString,
            },
            labels: {
              severity: $._config.alerts.tailscaledMachineHighOutboundDroppedPackets.severity,
              mixin: 'tailscale',
            },
          },
        ]) else [],
      },
    ],
  },
}
