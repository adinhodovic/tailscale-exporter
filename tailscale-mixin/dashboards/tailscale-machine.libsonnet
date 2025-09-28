local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboardUtil = import 'util.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local table = g.panel.table;

// Table
local tbQueryOptions = table.queryOptions;

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
          dashboardUtil.statPanel(
            'Tailscale Machines',
            'short',
            queries.tailscaledMachineCount,
            description='A stat panel showing the number of Tailscale machines reporting to the selected Tailscale control plane.',
          ),

        tailscaledRoutesPieChartPanel:
          dashboardUtil.pieChartPanel(
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
            description='A pie chart panel showing the number of advertised and approved routes for the selected Tailscale machines.',
          ),

        tailscaledInboundPathPieChartPanel:
          dashboardUtil.pieChartPanel(
            'Paths Distribution Inbound [1h]',
            'bps',
            queries.tailscaledInboundBytesByPathRate1h,
            '{{ path }}',
            description='A pie chart panel showing the distribution of outbound paths for the selected Tailscale machines.',
          ),

        tailscaledOutboundPathPieChartPanel:
          dashboardUtil.pieChartPanel(
            'Paths Distribution Outbound [1h]',
            'bps',
            queries.tailscaledOutboundBytesByPathRate1h,
            '{{ path }}',
            description='A pie chart panel showing the distribution of inbound paths for the selected Tailscale machines.',
          ),

        tailscaledInboundOutboundPieChartPanel:
          dashboardUtil.pieChartPanel(
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
            description='A pie chart panel showing the distribution of outbound paths for the selected Tailscale machines.',
          ),

        tailscaledDroppedPacketsByReasonPieChartPanel:
          dashboardUtil.pieChartPanel(
            'Dropped Packets by Reason [1h]',
            'pps',
            queries.tailscaledOutboundDroppedPacketsByReasonRate1h,
            '{{ reason }}',
            description='A pie chart panel showing the distribution of dropped packets by reason for the selected Tailscale machines.',
          ),

        tailscaledTop20MachinesByInboundTrafficTable:
          dashboardUtil.tablePanel(
            'Top 20 Machines by Inbound Traffic (1h)',
            'Bps',
            queries.tailscaledTop20MachinesByInboundTraffic1h,
            description='A table panel showing the top 20 Tailscale machines by inbound traffic over the last hour.',
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
                  excludeByName: {
                    Time: true,
                    job: true,
                  },
                }
              ),
            ],
          ),

        tailscaledMachinesWithUnapprovedRoutesTable:
          dashboardUtil.tablePanel(
            'Machines with Unapproved Routes',
            'short',
            queries.tailscaledMachinesWithUnapprovedRoutes,
            description='A table panel showing the Tailscale machines with unadvertised routes.',
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
                  excludeByName: {
                    Time: true,
                    job: true,
                  },
                }
              ),
            ],
          ),

        tailscaledMachinesWithDroppedPacketsTable:
          dashboardUtil.tablePanel(
            'Machines with Dropped Packets (1h)',
            'short',
            queries.tailscaledMachinesWithDroppedPackets1h,
            description='A table panel showing the Tailscale machines with dropped packets in the last hour.',
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
                  excludeByName: {
                    Time: true,
                    job: true,
                  },
                }
              ),
            ],
          ),

        tailscaledHealthMessagesByTypeTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Health Messages by Type',
            'short',
            queries.tailscaledHealthMessagesByType,
            '{{ type }}',
            description='A bar gauge panel showing the number of health messages by type.',
            stack='normal',
          ),

        tailscaledOutboundDroppedPacketsByReasonTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Outbound Dropped Packets by Reason',
            'pps',
            queries.tailscaledOutboundDroppedPacketsByReasonRate,
            '{{ reason }}',
            description='A timeseries panel showing the outbound dropped packets by reason.',
            stack='normal',
          ),

        tailscaledInboundBytesByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Inbound Bytes by Path',
            'bps',
            queries.tailscaledInboundBytesByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the inbound bytes by path.',
            stack='normal',
          ),

        tailscaledOutboundBytesByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Outbound Bytes by Path',
            'bps',
            queries.tailscaledOutboundBytesByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the outbound bytes by path.',
            stack='normal',
          ),

        tailscaledInboundPacketByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Inbound Packets by Path',
            'pps',
            queries.tailscaledInboundPacketByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the inbound packets by path.',
            stack='normal',
          ),

        tailscaledOutboundPacketByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Outbound Packets by Path',
            'pps',
            queries.tailscaledOutboundPacketByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the outbound packets by path.',
            stack='normal',
          ),

        // Tailscale Machine
        tailscaledRoutesMachinePieChartPanel:
          dashboardUtil.pieChartPanel(
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
            description='A pie chart panel showing the number of advertised and approved routes for the selected Tailscale machines.',
          ),

        tailscaledDerpNonDerpOutboundBytesMachinePieChartPanel:
          dashboardUtil.pieChartPanel(
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
            description='A pie chart panel showing the DERP vs Non-DERP outbound traffic for the selected Tailscale machine.',
          ),

        tailscaledDroppedPacketsMachineByReasonPieChartPanel:
          dashboardUtil.pieChartPanel(
            'Dropped Packets by Reason [1h]',
            'pps',
            queries.tailscaledOutboundDroppedPacketsMachineByReasonRate1h,
            '{{ reason }}',
            description='A pie chart panel showing the distribution of dropped packets by reason for the selected Tailscale machines.',
          ),

        tailscaledHealthMessagesMachineByTypeTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Health Messages by Type',
            'short',
            queries.tailscaledHealthMessagesMachineByType,
            '{{ type }}',
            description='A bar gauge panel showing the number of health messages by type for the selected Tailscale machine.',
            stack='normal',
          ),

        tailscaledOutboundDroppedPacketsMachineByReasonTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Outbound Dropped Packets by Reason',
            'short',
            queries.tailscaledOutboundDroppedPacketsMachineByReasonRate,
            '{{ reason }}',
            description='A timeseries panel showing the outbound dropped packets by reason for the selected Tailscale machine.',
            stack='normal',
          ),
        tailscaledInboundBytesMachineByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Inbound Bytes by Path',
            'Bps',
            queries.tailscaledInboundBytesMachineByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the inbound bytes by path for the selected Tailscale machine.',
            stack='normal',
          ),

        tailscaledOutboundBytesMachineByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Outbound Bytes by Path',
            'Bps',
            queries.tailscaledOutboundBytesMachineByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the outbound bytes by path for the selected Tailscale machine.',
            stack='normal',
          ),

        tailscaledInboundPacketMachineByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Inbound Packets by Path',
            'pps',
            queries.tailscaledInboundPacketMachineByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the inbound packets by path for the selected Tailscale machine.',
            stack='normal',
          ),

        tailscaledOutboundPacketMachineByPathTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Outbound Packets by Path',
            'pps',
            queries.tailscaledOutboundPacketMachineByPathRate,
            '{{ path }}',
            description='A timeseries panel showing the outbound packets by path for the selected Tailscale machine.',
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

      dashboardUtil.bypassDashboardValidation +
      dashboard.new(
        'Tailscale / Machine',
      ) +
      dashboard.withDescription('A dashboard that gives an overview of Tailscale Machine daemon metrics. %s' % dashboardUtil.dashboardDescriptionLink) +
      dashboard.withUid($._config.dashboardIds[dashboardName]) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(false) +
      dashboard.time.withFrom('now-24h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withLinks(
        dashboardUtil.dashboardLinks($._config)
      ) +
      dashboard.withPanels(
        rows
      ) +
      dashboard.withAnnotations(
        dashboardUtil.annotations($._config, defaultFilters)
      ),
  },
}
