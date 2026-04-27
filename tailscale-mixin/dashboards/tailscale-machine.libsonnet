local mixinUtils = import 'github.com/adinhodovic/mixin-utils/utils.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboardUtil = import 'util.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local table = g.panel.table;

// Table
local tbStandardOptions = table.standardOptions;
local tbQueryOptions = table.queryOptions;
local tbPanelOptions = table.panelOptions;
local tbOverride = tbStandardOptions.override;

{
  local dashboardName = 'tailscale-machine',
  grafanaDashboards+:: {
    ['%s.json' % dashboardName]:


      local defaultVariables = dashboardUtil.variables($._config);
      local variables = [
        defaultVariables.datasource,
        defaultVariables.tailscaledCluster,
        defaultVariables.tailscaledJob,
        defaultVariables.tailscaledMachine,
      ];

      local defaultFilters = dashboardUtil.filters($._config);
      local queries = {
        tailscaledMachineCount: |||
          count(
            tailscaled_health_messages{
              %(tailscaled)s
            }
          )
        ||| % defaultFilters,

        tailscaledAdvertisedRoutesCount: |||
          sum(
            tailscaled_advertised_routes{
              %(tailscaled)s
            }
          )
        ||| % defaultFilters,
        tailscaledApprovedRoutesCount: std.strReplace(queries.tailscaledAdvertisedRoutesCount, 'advertised', 'approved'),

        tailscaledInboundBytesRate: |||
          sum(
            rate(
              tailscaled_inbound_bytes_total{
                %(tailscaled)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,
        tailscaledInboundBytesRate1h: std.strReplace(queries.tailscaledInboundBytesRate, '$__rate_interval', '1h'),
        tailscaledOutboundBytesRate: std.strReplace(queries.tailscaledInboundBytesRate, 'inbound', 'outbound'),
        tailscaledOutboundBytesRate1h: std.strReplace(queries.tailscaledOutboundBytesRate, '$__rate_interval', '1h'),

        tailscaledHealthMessagesByType: |||
          sum(
            tailscaled_health_messages{
              %(tailscaled)s
            }
          ) by (type)
        ||| % defaultFilters,

        tailscaledTop20MachinesByInboundTraffic1h: |||
          topk(
            20,
            sum(
              rate(
                tailscaled_inbound_bytes_total{
                  %(tailscaled)s
                }[1h]
              )
            ) by (tailscale_machine)
          )
        ||| % defaultFilters,

        tailscaledMachinesWithUnapprovedRoutes: |||
          sum(
            tailscaled_advertised_routes{
              %(tailscaled)s
            }
          ) by (tailscale_machine)
          -
          sum(
            tailscaled_approved_routes{
              %(tailscaled)s
            }
          ) by (tailscale_machine)
          > 0
        ||| % defaultFilters,

        tailscaledMachinesWithDroppedPackets1h: |||
          sum(
            increase(
              tailscaled_outbound_dropped_packets_total{
                %(tailscaled)s
              }[1h]
            )
          ) by (tailscale_machine)
          /
          sum(
            increase(
              tailscaled_outbound_packets_total{
                %(tailscaled)s
              }[1h]
            )
          ) by (tailscale_machine)
          * 100
          > 0
        ||| % defaultFilters,

        tailscaledOutboundDroppedPacketsByReasonRate: |||
          sum(
            increase(
              tailscaled_outbound_dropped_packets_total{
                %(tailscaled)s
              }[$__rate_interval]
            )
          ) by (reason)
        ||| % defaultFilters,
        tailscaledOutboundDroppedPacketsByReasonRate1h: std.strReplace(queries.tailscaledOutboundDroppedPacketsByReasonRate, '$__rate_interval', '1h'),

        tailscaledInboundBytesByPathRate: |||
          sum(
            increase(
              tailscaled_inbound_bytes_total{
                %(tailscaled)s
              }[$__rate_interval]
            )
          ) by (path)
        ||| % defaultFilters,
        tailscaledInboundBytesByPathRate1h: std.strReplace(queries.tailscaledInboundBytesByPathRate, '$__rate_interval', '1h'),
        tailscaledOutboundBytesByPathRate: std.strReplace(queries.tailscaledInboundBytesByPathRate, 'inbound', 'outbound'),
        tailscaledOutboundBytesByPathRate1h: std.strReplace(queries.tailscaledOutboundBytesByPathRate, '$__rate_interval', '1h'),

        tailscaledInboundPacketByPathRate: |||
          sum(
            increase(
              tailscaled_inbound_packets_total{
                %(tailscaled)s
              }[$__rate_interval]
            )
          ) by (path)
        ||| % defaultFilters,
        tailscaledOutboundPacketByPathRate: std.strReplace(queries.tailscaledInboundPacketByPathRate, 'inbound', 'outbound'),

        // Tailscale Machine
        tailscaledAdvertisedRoutesMachineCount: |||
          sum(
            tailscaled_advertised_routes{
              %(tailscaledMachine)s
            }
          )
        ||| % defaultFilters,
        tailscaledApprovedRoutesMachineCount: std.strReplace(queries.tailscaledAdvertisedRoutesMachineCount, 'advertised', 'approved'),

        tailscaleDerpOutboundBytesMachineRate1h: |||
          sum(
            rate(
              tailscaled_outbound_bytes_total{
                %(tailscaledMachine)s,
                path="derp"
              }[1h]
            )
          )
        ||| % defaultFilters,
        tailscaleNonDerpOutboundBytesMachineRate1h: std.strReplace(queries.tailscaleDerpOutboundBytesMachineRate1h, 'path=', 'path!='),

        tailscaledHealthMessagesMachineByType: |||
          sum(
            tailscaled_health_messages{
              %(tailscaledMachine)s
            }
          ) by (type)
        ||| % defaultFilters,

        tailscaledOutboundDroppedPacketsMachineByReasonRate: |||
          sum(
            increase(
              tailscaled_outbound_dropped_packets_total{
                %(tailscaledMachine)s
              }[$__rate_interval]
            )
          ) by (reason)
        ||| % defaultFilters,
        tailscaledOutboundDroppedPacketsMachineByReasonRate1h: std.strReplace(queries.tailscaledOutboundDroppedPacketsMachineByReasonRate, '$__rate_interval', '1h'),

        tailscaledInboundBytesMachineByPathRate: |||
          sum(
            increase(
              tailscaled_inbound_bytes_total{
                %(tailscaledMachine)s
              }[$__rate_interval]
            )
          ) by (path)
        ||| % defaultFilters,
        tailscaledOutboundBytesMachineByPathRate: std.strReplace(queries.tailscaledInboundBytesMachineByPathRate, 'inbound', 'outbound'),

        tailscaledInboundPacketMachineByPathRate: |||
          sum(
            increase(
              tailscaled_inbound_packets_total{
                %(tailscaledMachine)s
              }[$__rate_interval]
            )
          ) by (path)
        ||| % defaultFilters,
        tailscaledOutboundPacketMachineByPathRate: std.strReplace(queries.tailscaledInboundPacketMachineByPathRate, 'inbound', 'outbound'),
      };

      local panels = {

        tailscaledMachineCountStat:
          mixinUtils.dashboards.statPanel(
            'Tailscale Machines',
            'short',
            queries.tailscaledMachineCount,
            description='Number of tailscaled instances currently reporting metrics. A sudden drop usually means scrape failures, stopped daemons, or machines that can no longer reach Prometheus.',
          ),

        tailscaledRoutesPieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Advertised / Approved Routes',
            'short',
            [
              {
                expr: queries.tailscaledAdvertisedRoutesCount,
                legend: 'Advertised',
              },
              {
                expr: queries.tailscaledApprovedRoutesCount,
                legend: 'Approved',
              },
            ],
            description='Advertised routes are routes machines offer to the tailnet. Approved routes are routes the control plane allows clients to use. A gap means subnet routing is configured but not fully enabled.',
          ),

        tailscaledInboundPathPieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Paths Distribution Inbound [1h]',
            'bps',
            queries.tailscaledInboundBytesByPathRate1h,
            '{{ path }}',
            description='Inbound traffic split by path over the last hour. DERP-heavy traffic can indicate failed direct connectivity, restrictive NAT, or firewall changes.',
          ),

        tailscaledOutboundPathPieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Paths Distribution Outbound [1h]',
            'bps',
            queries.tailscaledOutboundBytesByPathRate1h,
            '{{ path }}',
            description='Outbound traffic split by path over the last hour. A high DERP share is useful when investigating latency or relay dependency.',
          ),

        tailscaledInboundOutboundPieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Inbound vs Outbound Traffic [1h]',
            'bps',
            [
              {
                expr: queries.tailscaledInboundBytesRate1h,
                legend: 'Inbound',
              },
              {
                expr: queries.tailscaledOutboundBytesRate1h,
                legend: 'Outbound',
              },
            ],
            '{{ path }}',
            description='Inbound and outbound traffic over the last hour. Large asymmetry can help identify machines acting as gateways, subnet routers, or unexpectedly chatty clients.',
          ),

        tailscaledDroppedPacketsByReasonPieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Dropped Packets by Reason [1h]',
            'pps',
            queries.tailscaledOutboundDroppedPacketsByReasonRate1h,
            '{{ reason }}',
            description='Dropped outbound packets grouped by reason over the last hour. Non-zero values are worth correlating with route approval, ACLs, and path changes.',
          ),

        tailscaledTop20MachinesByInboundTrafficTable:
          mixinUtils.dashboards.tablePanel(
            'Top 20 Machines by Inbound Traffic (1h)',
            'Bps',
            queries.tailscaledTop20MachinesByInboundTraffic1h,
            description='Highest inbound-traffic machines over the last hour. Use this to spot subnet routers, gateways, or unexpected traffic concentration, then drill into the machine row.',
            sortBy={ name: 'Inbound Traffic (Bps)', desc: true },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    tailscale_machine: 'Tailscale Machine',
                    Value: 'Inbound Traffic (Bps)',
                  },
                  indexByName: {
                    tailscale_machine: 0,
                    Value: 1,
                  },
                  includeByName: {
                    tailscale_machine: true,
                    Value: true,
                  },
                }
              ),
            ],
            links=[
              tbPanelOptions.link.withTitle('Go To Machine') +
              tbPanelOptions.link.withType('dashboard') +
              tbPanelOptions.link.withUrl(
                '/d/%s/tailscale-machine?var-tailscale_machine=${__data.fields.Tailscale Machine}' % $._config.dashboardIds['tailscale-machine']
              ) +
              tbPanelOptions.link.withTargetBlank(true),
            ],
          ),

        tailscaledMachinesWithUnapprovedRoutesTable:
          mixinUtils.dashboards.tablePanel(
            'Machines with Unapproved Routes',
            'short',
            queries.tailscaledMachinesWithUnapprovedRoutes,
            description='Machines where advertised routes exceed approved routes. These machines are offering routes that clients cannot use until the routes are approved.',
            sortBy={ name: 'Unapproved Routes', desc: true },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    tailscale_machine: 'Tailscale Machine',
                    Value: 'Unapproved Routes',
                  },
                  indexByName: {
                    tailscale_machine: 0,
                    Value: 1,
                  },
                  includeByName: {
                    tailscale_machine: true,
                    Value: true,
                  },
                }
              ),
            ],
            links=[
              tbPanelOptions.link.withTitle('Go To Machine') +
              tbPanelOptions.link.withType('dashboard') +
              tbPanelOptions.link.withUrl(
                '/d/%s/tailscale-machine?var-tailscale_machine=${__data.fields.Tailscale Machine}' % $._config.dashboardIds['tailscale-machine']
              ) +
              tbPanelOptions.link.withTargetBlank(true),
            ],
          ),

        tailscaledMachinesWithDroppedPacketsTable:
          mixinUtils.dashboards.tablePanel(
            'Machines with Dropped Packets (1h)',
            'percent',
            queries.tailscaledMachinesWithDroppedPackets1h,
            description='Machines with outbound packet drops in the last hour. Investigate persistent values with path, route, and ACL changes for the same machine.',
            sortBy={ name: 'Dropped Packets', desc: true },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    tailscale_machine: 'Tailscale Machine',
                    Value: 'Dropped Packets',
                  },
                  indexByName: {
                    tailscale_machine: 0,
                    Value: 1,
                  },
                  includeByName: {
                    tailscale_machine: true,
                    Value: true,
                  },
                }
              ),
            ],
            overrides=[
              tbOverride.byName.new('Dropped Packets') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('percent') +
                tbStandardOptions.withMin(0) +
                tbStandardOptions.withMax(100)
              ),
            ],
            links=[
              tbPanelOptions.link.withTitle('Go To Machine') +
              tbPanelOptions.link.withType('dashboard') +
              tbPanelOptions.link.withUrl(
                '/d/%s/tailscale-machine?var-tailscale_machine=${__data.fields.Tailscale Machine}' % $._config.dashboardIds['tailscale-machine']
              ) +
              tbPanelOptions.link.withTargetBlank(true),
            ],
          ),

        tailscaledHealthMessagesByTypeTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Health Messages by Type',
            'short',
            queries.tailscaledHealthMessagesByType,
            '{{ type }}',
            description='Health messages grouped by type across selected machines. Spikes usually point to daemon warnings, network path degradation, or local host issues that need machine-level drilldown.',
            stack='normal',
          ),

        tailscaledOutboundDroppedPacketsByReasonTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Outbound Dropped Packets by Reason',
            'pps',
            queries.tailscaledOutboundDroppedPacketsByReasonRate,
            '{{ reason }}',
            description='Outbound packet drops grouped by reason. Use this with the affected-machine table to identify whether drops are isolated to one host or broad across the fleet.',
            stack='normal',
          ),

        tailscaledInboundBytesByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Inbound Bytes by Path',
            'bps',
            queries.tailscaledInboundBytesByPathRate,
            '{{ path }}',
            description='Inbound traffic grouped by direct and relay paths. Changes in path mix can explain latency shifts even when total traffic is stable.',
            stack='normal',
          ),

        tailscaledOutboundBytesByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Outbound Bytes by Path',
            'bps',
            queries.tailscaledOutboundBytesByPathRate,
            '{{ path }}',
            description='Outbound traffic grouped by direct and relay paths. A rising DERP line often means direct peer connectivity is failing or becoming less reliable.',
            stack='normal',
          ),

        tailscaledInboundPacketByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Inbound Packets by Path',
            'pps',
            queries.tailscaledInboundPacketByPathRate,
            '{{ path }}',
            description='Inbound packet rate by path. Compare with bytes by path to distinguish many small control packets from large data transfers.',
            stack='normal',
          ),

        tailscaledOutboundPacketByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Outbound Packets by Path',
            'pps',
            queries.tailscaledOutboundPacketByPathRate,
            '{{ path }}',
            description='Outbound packet rate by path. Sustained DERP packet volume can indicate relay dependency even when bandwidth is modest.',
            stack='normal',
          ),

        // Tailscale Machine
        tailscaledRoutesMachinePieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Advertised / Approved Routes',
            'short',
            [
              {
                expr: queries.tailscaledAdvertisedRoutesMachineCount,
                legend: 'Advertised',
              },
              {
                expr: queries.tailscaledApprovedRoutesMachineCount,
                legend: 'Approved',
              },
            ],
            description='Advertised versus approved routes for the selected machine. A mismatch means the machine is offering routes that are not active for clients.',
          ),

        tailscaledDerpNonDerpOutboundBytesMachinePieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'DERP vs Non-DERP Outbound Traffic [1h]',
            'bps',
            [
              {
                expr: queries.tailscaleDerpOutboundBytesMachineRate1h,
                legend: 'DERP',
              },
              {
                expr: queries.tailscaleNonDerpOutboundBytesMachineRate1h,
                legend: 'Non-DERP',
              },
            ],
            description='DERP versus direct outbound traffic for the selected machine over the last hour. High DERP usage can explain latency and is often caused by NAT, firewall, or connectivity changes.',
          ),

        tailscaledDroppedPacketsMachineByReasonPieChartPanel:
          mixinUtils.dashboards.pieChartPanel(
            'Dropped Packets by Reason [1h]',
            'pps',
            queries.tailscaledOutboundDroppedPacketsMachineByReasonRate1h,
            '{{ reason }}',
            description='Dropped outbound packets by reason for the selected machine over the last hour. Non-zero values should be checked against health messages and route state.',
          ),

        tailscaledHealthMessagesMachineByTypeTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Health Messages by Type',
            'short',
            queries.tailscaledHealthMessagesMachineByType,
            '{{ type }}',
            description='Health messages by type for the selected machine. Persistent or new message types are often the first signal of local daemon or network-path problems.',
            stack='normal',
          ),

        tailscaledOutboundDroppedPacketsMachineByReasonTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Outbound Dropped Packets by Reason',
            'short',
            queries.tailscaledOutboundDroppedPacketsMachineByReasonRate,
            '{{ reason }}',
            description='Outbound packet drops by reason for the selected machine. Use this to verify whether packet loss is transient or tied to a specific drop reason.',
            stack='normal',
          ),
        tailscaledInboundBytesMachineByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Inbound Bytes by Path',
            'Bps',
            queries.tailscaledInboundBytesMachineByPathRate,
            '{{ path }}',
            description='Inbound traffic by path for the selected machine. A move from direct to DERP usually indicates peer-to-peer connectivity regression.',
            stack='normal',
          ),

        tailscaledOutboundBytesMachineByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Outbound Bytes by Path',
            'Bps',
            queries.tailscaledOutboundBytesMachineByPathRate,
            '{{ path }}',
            description='Outbound traffic by path for the selected machine. High DERP traffic can point to relay dependency and higher expected latency.',
            stack='normal',
          ),

        tailscaledInboundPacketMachineByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Inbound Packets by Path',
            'pps',
            queries.tailscaledInboundPacketMachineByPathRate,
            '{{ path }}',
            description='Inbound packets by path for the selected machine. Compare with byte volume to understand packet size and control-plane chatter.',
            stack='normal',
          ),

        tailscaledOutboundPacketMachineByPathTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Outbound Packets by Path',
            'pps',
            queries.tailscaledOutboundPacketMachineByPathRate,
            '{{ path }}',
            description='Outbound packets by path for the selected machine. Sustained relay packet rate is a useful signal when troubleshooting latency or firewall behavior.',
            stack='normal',
          ),
      };

      local rows =
        [
          row.new('Summary') +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.tailscaledMachineCountStat,
            panels.tailscaledRoutesPieChartPanel,
            panels.tailscaledInboundPathPieChartPanel,
            panels.tailscaledOutboundPathPieChartPanel,
            panels.tailscaledInboundOutboundPieChartPanel,
            panels.tailscaledDroppedPacketsByReasonPieChartPanel,
          ],
          panelWidth=4,
          panelHeight=5,
          startY=1,
        ) +
        grid.wrapPanels(
          [
            panels.tailscaledTop20MachinesByInboundTrafficTable,
            panels.tailscaledMachinesWithUnapprovedRoutesTable,
            panels.tailscaledMachinesWithDroppedPacketsTable,
          ],
          panelWidth=8,
          panelHeight=8,
          startY=7,
        ) +
        [
          row.new('Network Summary') +
          row.gridPos.withX(0) +
          row.gridPos.withY(15) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.tailscaledHealthMessagesByTypeTimeSeries,
            panels.tailscaledOutboundDroppedPacketsByReasonTimeSeries,
            panels.tailscaledInboundBytesByPathTimeSeries,
            panels.tailscaledInboundPacketByPathTimeSeries,
            panels.tailscaledOutboundBytesByPathTimeSeries,
            panels.tailscaledOutboundPacketByPathTimeSeries,
          ],
          panelWidth=12,
          panelHeight=5,
          startY=16,
        ) +
        [
          row.new('Tailscale Machine $tailscale_machine') +
          row.gridPos.withX(0) +
          row.gridPos.withY(31) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1) +
          row.withRepeat('tailscale_machine'),
        ] +
        grid.wrapPanels(
          [
            panels.tailscaledRoutesMachinePieChartPanel,
            panels.tailscaledDerpNonDerpOutboundBytesMachinePieChartPanel,
            panels.tailscaledDroppedPacketsMachineByReasonPieChartPanel,
          ],
          panelWidth=8,
          panelHeight=4,
          startY=32,
        ) +
        grid.wrapPanels(
          [
            panels.tailscaledHealthMessagesMachineByTypeTimeSeries,
            panels.tailscaledOutboundDroppedPacketsMachineByReasonTimeSeries,
            panels.tailscaledInboundBytesMachineByPathTimeSeries,
            panels.tailscaledInboundPacketMachineByPathTimeSeries,
            panels.tailscaledOutboundBytesMachineByPathTimeSeries,
            panels.tailscaledOutboundPacketMachineByPathTimeSeries,
          ],
          panelWidth=12,
          panelHeight=5,
          startY=36,
        );

      mixinUtils.dashboards.bypassDashboardValidation +
      dashboard.new(
        'Tailscale / Machine',
      ) +
      dashboard.withDescription('An overview of tailscaled daemon metrics including inbound/outbound traffic by path, dropped packets by reason, health messages, and per-machine drilldown with DERP vs non-DERP traffic breakdown. %s' % mixinUtils.dashboards.dashboardDescriptionLink('tailscale-mixin', 'https://github.com/adinhodovic/tailscale-exporter/tree/main/tailscale-mixin')) +
      dashboard.withUid($._config.dashboardIds[dashboardName]) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(false) +
      dashboard.time.withFrom('now-6h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withLinks(
        mixinUtils.dashboards.dashboardLinks('Tailscale', $._config, dropdown=true)
      ) +
      dashboard.withPanels(
        rows
      ) +
      dashboard.withAnnotations(
        mixinUtils.dashboards.annotations($._config, defaultFilters)
      ),
  },
}
