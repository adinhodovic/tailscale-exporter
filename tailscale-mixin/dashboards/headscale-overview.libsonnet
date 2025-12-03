local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboardUtil = import 'util.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local table = g.panel.table;

// Table helpers
local tbStandardOptions = table.standardOptions;
local tbQueryOptions = table.queryOptions;
local tbOverride = tbStandardOptions.override;

{
  local dashboardName = 'headscale-overview',
  grafanaDashboards+:: {
    ['%s.json' % dashboardName]:

      local defaultVariables = dashboardUtil.variables($._config);

      local variables = [
        defaultVariables.datasource,
        defaultVariables.cluster,
        defaultVariables.namespace,
        defaultVariables.job,
      ];

      local defaultFilters = dashboardUtil.filters($._config);
      local headscaleFilters = {
        headscale: |||
          %(base)s,
          %(namespace)s,
          %(job)s
        ||| % defaultFilters,
      };

      local queries = {
        nodesTotal: |||
          count(
            headscale_nodes_info{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        nodesOnline: |||
          sum(
            headscale_nodes_online{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        nodesOffline: |||
          count(
            headscale_nodes_online{
              %(headscale)s
            } == 0
          )
        ||| % headscaleFilters,

        nodesByUser: |||
          count(
            headscale_nodes_info{
              %(headscale)s
            }
          ) by (user)
        ||| % headscaleFilters,

        nodesByRegisterMethod: |||
          count(
            headscale_nodes_info{
              %(headscale)s
            }
          ) by (register_method)
        ||| % headscaleFilters,

        nodesTagsByCategory: |||
          sum(
            headscale_nodes_tags{
              %(headscale)s
            }
          ) by (category)
        ||| % headscaleFilters,

        nodesOnlineTimeSeries: |||
          sum(
            headscale_nodes_online{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        nodesApprovedRoutes: |||
          sum(
            headscale_nodes_approved_routes{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        nodesAvailableRoutes: |||
          sum(
            headscale_nodes_available_routes{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        nodesSubnetRoutes: |||
          sum(
            headscale_nodes_subnet_routes{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        nodesInfo: |||
          headscale_nodes_info{
            %(headscale)s
          }
        ||| % headscaleFilters,

        nodesCreated: |||
          min(
            headscale_nodes_created_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, name, user)
        ||| % headscaleFilters,

        nodesLastSeen: |||
          max(
            headscale_nodes_last_seen_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, name, user)
        ||| % headscaleFilters,

        nodesExpiry: |||
          min(
            headscale_nodes_expiry_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, name, user)
        ||| % headscaleFilters,

        nodesLastSeenAge: |||
          time() -
          max(
            headscale_nodes_last_seen_timestamp{
              %(headscale)s
            }
          ) by (id, name, user)
        ||| % headscaleFilters,

        usersTotal: |||
          count(
            headscale_users_info{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        usersByProvider: |||
          count(
            headscale_users_info{
              %(headscale)s
            }
          ) by (provider)
        ||| % headscaleFilters,

        usersInfo: |||
          headscale_users_info{
            %(headscale)s
          }
        ||| % headscaleFilters,

        apiKeysTotal: |||
          count(
            headscale_apikeys_info{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        apiKeysExpiringSoon: |||
          count(
            headscale_apikeys_expiration_timestamp{
              %(headscale)s
            } < time() + 30 * 24 * 60 * 60
          )
        ||| % headscaleFilters,

        apiKeysCreated: |||
          min(
            headscale_apikeys_created_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, prefix)
        ||| % headscaleFilters,

        apiKeysExpires: |||
          min(
            headscale_apikeys_expiration_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, prefix)
        ||| % headscaleFilters,

        apiKeysLastSeen: |||
          max(
            headscale_apikeys_last_seen_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, prefix)
        ||| % headscaleFilters,

        preAuthKeysTotal: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,

        preAuthKeysExpiringSoon: |||
          count(
            headscale_preauthkeys_expiration_timestamp{
              %(headscale)s
            } < time() + 7 * 24 * 60 * 60
          )
        ||| % headscaleFilters,

        preAuthKeysInfo: |||
          headscale_preauthkeys_info{
            %(headscale)s
          }
        ||| % headscaleFilters,

        preAuthKeysCreated: |||
          min(
            headscale_preauthkeys_created_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, user)
        ||| % headscaleFilters,

        preAuthKeysExpiration: |||
          min(
            headscale_preauthkeys_expiration_timestamp{
              %(headscale)s
            } * 1000
          ) by (id, user)
        ||| % headscaleFilters,

        preAuthKeysUsed: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s,
              used="true"
            }
          )
        ||| % headscaleFilters,

        preAuthKeysUnused: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s,
              used="false"
            }
          )
        ||| % headscaleFilters,

        preAuthKeysReusable: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s,
              reusable="true"
            }
          )
        ||| % headscaleFilters,

        preAuthKeysSingleUse: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s,
              reusable="false"
            }
          )
        ||| % headscaleFilters,

        preAuthKeysEphemeral: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s,
              ephemeral="true"
            }
          )
        ||| % headscaleFilters,

        preAuthKeysPersistent: |||
          count(
            headscale_preauthkeys_info{
              %(headscale)s,
              ephemeral="false"
            }
          )
        ||| % headscaleFilters,

        databaseConnectivity: |||
          max(
            headscale_health_database_connectivity{
              %(headscale)s
            }
          )
        ||| % headscaleFilters,
      };

      local panels = {
        // Summary
        nodesTotalStat:
          dashboardUtil.statPanel(
            'Nodes',
            'short',
            queries.nodesTotal,
            description='Number of Headscale nodes discovered by the exporter.',
          ),

        nodesOnlineStat:
          dashboardUtil.statPanel(
            'Online Nodes',
            'short',
            queries.nodesOnline,
            description='Nodes currently online according to Headscale.',
          ),

        nodesOfflineStat:
          dashboardUtil.statPanel(
            'Offline Nodes',
            'short',
            queries.nodesOffline,
            description='Nodes that Headscale considers offline.',
          ),

        usersTotalStat:
          dashboardUtil.statPanel(
            'Users',
            'short',
            queries.usersTotal,
            description='Total number of users known to Headscale.',
          ),

        apiKeysTotalStat:
          dashboardUtil.statPanel(
            'API Keys',
            'short',
            queries.apiKeysTotal,
            description='Count of Headscale API keys.',
          ),

        apiKeysExpiringStat:
          dashboardUtil.statPanel(
            'API Keys <30d',
            'short',
            queries.apiKeysExpiringSoon,
            description='API keys that expire within the next 30 days.',
          ),

        preAuthKeysTotalStat:
          dashboardUtil.statPanel(
            'Pre-auth Keys',
            'short',
            queries.preAuthKeysTotal,
            description='Count of Headscale pre-authentication keys.',
          ),

        preAuthKeysExpiringStat:
          dashboardUtil.statPanel(
            'Pre-auth Keys <7d',
            'short',
            queries.preAuthKeysExpiringSoon,
            description='Pre-authentication keys that expire within the next 7 days.',
          ),

        databaseConnectivityStat:
          dashboardUtil.statPanel(
            'Database Connectivity',
            'bool',
            queries.databaseConnectivity,
            description='Reported database connectivity state from the Headscale health endpoint.',
          ),

        // Nodes
        nodesByUserPieChart:
          dashboardUtil.pieChartPanel(
            'Nodes by User',
            'short',
            queries.nodesByUser,
            '{{ user }}',
            description='Distribution of nodes grouped by user.',
          ),

        nodesByRegisterMethodPieChart:
          dashboardUtil.pieChartPanel(
            'Nodes by Register Method',
            'short',
            queries.nodesByRegisterMethod,
            '{{ register_method }}',
            description='Distribution of nodes grouped by registration method.',
          ),

        nodesTagsPieChart:
          dashboardUtil.pieChartPanel(
            'Node Tags',
            'short',
            queries.nodesTagsByCategory,
            '{{ category }}',
            description='Breakdown of tags reported per node grouped by category.',
          ),

        nodesOnlineTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Nodes Online',
            'short',
            queries.nodesOnlineTimeSeries,
            'Online',
            description='Total number of nodes that Headscale reports as online.',
          ),

        nodesRoutesTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Advertised Routes',
            'short',
            [
              {
                expr: queries.nodesApprovedRoutes,
                legend: 'Approved',
              },
              {
                expr: queries.nodesAvailableRoutes,
                legend: 'Available',
              },
              {
                expr: queries.nodesSubnetRoutes,
                legend: 'Subnet',
              },
            ],
            description='Counts of routes advertised by nodes grouped by state.',
          ),

        nodesInfoTable:
          dashboardUtil.tablePanel(
            'Nodes Inventory',
            'string',
            queries.nodesInfo,
            description='Node metadata reported by Headscale.',
            sortBy={ name: 'Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    id: 'ID',
                    name: 'Name',
                    user: 'User',
                    user_id: 'User ID',
                    given_name: 'Given Name',
                    register_method: 'Register Method',
                    machine_key: 'Machine Key',
                    node_key: 'Node Key',
                    disco_key: 'Disco Key',
                  },
                  indexByName: {
                    name: 0,
                    user: 1,
                    user_id: 2,
                    given_name: 3,
                    register_method: 4,
                    machine_key: 5,
                    node_key: 6,
                    disco_key: 7,
                    id: 8,
                  },
                  excludeByName: {
                    Time: true,
                    Value: true,
                    job: true,
                    container: true,
                    instance: true,
                    service: true,
                    pod: true,
                    endpoint: true,
                    namespace: true,
                    __name__: true,
                    environment: true,
                    cluster: true,
                    prometheus: true,
                  },
                }
              ),
            ],
          ),

        nodesLifecycleTable:
          dashboardUtil.tablePanel(
            'Node Lifecycle',
            'string',
            [
              {
                expr: queries.nodesCreated,
              },
              {
                expr: queries.nodesLastSeen,
              },
              {
                expr: queries.nodesExpiry,
              },
            ],
            description='Creation, last seen, and expiry timestamps per node.',
            sortBy={ name: 'Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId('merge'),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    name: 'Name',
                    id: 'ID',
                    user: 'User',
                    'Value #A': 'Created',
                    'Value #B': 'Last Seen',
                    'Value #C': 'Expiry',
                  },
                  indexByName: {
                    name: 0,
                    id: 1,
                    user: 2,
                    'Value #A': 3,
                    'Value #B': 4,
                    'Value #C': 5,
                  },
                  excludeByName: {
                    Time: true,
                    job: true,
                    container: true,
                    instance: true,
                    service: true,
                    pod: true,
                    endpoint: true,
                    namespace: true,
                    __name__: true,
                    environment: true,
                    cluster: true,
                    prometheus: true,
                  },
                }
              ),
            ],
            overrides=[
              tbOverride.byName.new('Created') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
              tbOverride.byName.new('Last Seen') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
              tbOverride.byName.new('Expiry') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
            ],
          ),

        nodesLastSeenTable:
          dashboardUtil.tablePanel(
            'Seconds Since Last Seen',
            's',
            queries.nodesLastSeenAge,
            description='How long each node has been offline according to Headscale.',
            sortBy={ name: 'Value', desc: true },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    id: 'ID',
                    name: 'Name',
                    user: 'User',
                    Value: 'Seconds Since Last Seen',
                  },
                  indexByName: {
                    name: 0,
                    user: 1,
                    id: 2,
                    Value: 3,
                  },
                  excludeByName: {
                    Time: true,
                    job: true,
                    container: true,
                    instance: true,
                    service: true,
                    pod: true,
                    endpoint: true,
                    namespace: true,
                    __name__: true,
                    environment: true,
                    cluster: true,
                    prometheus: true,
                  },
                }
              ),
            ],
          ),

        // Users
        usersByProviderPieChart:
          dashboardUtil.pieChartPanel(
            'Users by Provider',
            'short',
            queries.usersByProvider,
            '{{ provider }}',
            description='Distribution of users grouped by identity provider.',
          ),

        usersInfoTable:
          dashboardUtil.tablePanel(
            'Users',
            'string',
            queries.usersInfo,
            description='User metadata reported by Headscale.',
            sortBy={ name: 'Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    id: 'ID',
                    name: 'Name',
                    display_name: 'Display Name',
                    email: 'Email',
                    provider: 'Provider',
                    provider_id: 'Provider ID',
                  },
                  indexByName: {
                    name: 0,
                    display_name: 1,
                    email: 2,
                    provider: 3,
                    provider_id: 4,
                    id: 5,
                  },
                  excludeByName: {
                    Time: true,
                    Value: true,
                    job: true,
                    container: true,
                    instance: true,
                    service: true,
                    pod: true,
                    endpoint: true,
                    namespace: true,
                    __name__: true,
                    environment: true,
                    cluster: true,
                    prometheus: true,
                  },
                }
              ),
            ],
          ),

        // Access
        preAuthKeysUsagePieChart:
          dashboardUtil.pieChartPanel(
            'Pre-auth Keys Usage',
            'short',
            [
              { expr: queries.preAuthKeysUsed, legend: 'Used' },
              { expr: queries.preAuthKeysUnused, legend: 'Unused' },
            ],
            description='Breakdown of used vs unused pre-authentication keys.',
          ),

        preAuthKeysReusablePieChart:
          dashboardUtil.pieChartPanel(
            'Pre-auth Keys Reusable',
            'short',
            [
              { expr: queries.preAuthKeysReusable, legend: 'Reusable' },
              { expr: queries.preAuthKeysSingleUse, legend: 'Single-use' },
            ],
            description='Distribution of reusable vs single-use pre-authentication keys.',
          ),

        preAuthKeysEphemeralPieChart:
          dashboardUtil.pieChartPanel(
            'Pre-auth Keys Ephemeral',
            'short',
            [
              { expr: queries.preAuthKeysEphemeral, legend: 'Ephemeral' },
              { expr: queries.preAuthKeysPersistent, legend: 'Persistent' },
            ],
            description='Distribution of ephemeral vs persistent pre-authentication keys.',
          ),

        apiKeysInfoTable:
          dashboardUtil.tablePanel(
            'API Keys',
            'string',
            [
              { expr: queries.apiKeysCreated },
              { expr: queries.apiKeysExpires },
              { expr: queries.apiKeysLastSeen },
            ],
            description='Lifecycle information (created, expiration, last seen) for API keys.',
            sortBy={ name: 'prefix', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId('merge'),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    id: 'ID',
                    prefix: 'Prefix',
                    'Value #A': 'Created',
                    'Value #B': 'Expires',
                    'Value #C': 'Last Seen',
                  },
                  indexByName: {
                    prefix: 0,
                    id: 1,
                    'Value #A': 2,
                    'Value #B': 3,
                    'Value #C': 4,
                  },
                  excludeByName: {
                    Time: true,
                    job: true,
                    container: true,
                    instance: true,
                    service: true,
                    pod: true,
                    endpoint: true,
                    namespace: true,
                    __name__: true,
                    environment: true,
                    cluster: true,
                    prometheus: true,
                  },
                }
              ),
            ],
            overrides=[
              tbOverride.byName.new('Created') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
              tbOverride.byName.new('Expires') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
              tbOverride.byName.new('Last Seen') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
            ],
          ),

        preAuthKeysInfoTable:
          dashboardUtil.tablePanel(
            'Pre-auth Keys',
            'string',
            [
              { expr: queries.preAuthKeysInfo },
              { expr: queries.preAuthKeysCreated },
              { expr: queries.preAuthKeysExpiration },
            ],
            description='Metadata and lifecycle information for Headscale pre-authentication keys.',
            sortBy={ name: 'user', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId('merge'),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    id: 'ID',
                    user: 'User',
                    reusable: 'Reusable',
                    ephemeral: 'Ephemeral',
                    used: 'Used',
                    acl_tags: 'ACL Tags',
                    'Value #B': 'Created',
                    'Value #C': 'Expiration',
                  },
                  indexByName: {
                    user: 0,
                    id: 1,
                    reusable: 2,
                    ephemeral: 3,
                    used: 4,
                    acl_tags: 5,
                    'Value #B': 6,
                    'Value #C': 7,
                  },
                  excludeByName: {
                    Time: true,
                    Value: true,
                    '#Value #A': true,
                    job: true,
                    container: true,
                    instance: true,
                    service: true,
                    pod: true,
                    endpoint: true,
                    namespace: true,
                    __name__: true,
                    environment: true,
                    cluster: true,
                    prometheus: true,
                  },
                }
              ),
            ],
            overrides=[
              tbOverride.byName.new('Created') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
              tbOverride.byName.new('Expiration') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('dateTimeAsIso')
              ),
            ],
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
            panels.nodesTotalStat,
            panels.nodesOnlineStat,
            panels.nodesOfflineStat,
            panels.usersTotalStat,
            panels.apiKeysTotalStat,
            panels.apiKeysExpiringStat,
            panels.preAuthKeysTotalStat,
            panels.preAuthKeysExpiringStat,
            panels.databaseConnectivityStat,
          ],
          panelWidth=4,
          panelHeight=4,
          startY=1,
        ) +
        [
          row.new('Nodes') +
          row.gridPos.withX(0) +
          row.gridPos.withY(5) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.nodesByUserPieChart,
            panels.nodesByRegisterMethodPieChart,
            panels.nodesTagsPieChart,
          ],
          panelWidth=8,
          panelHeight=6,
          startY=6,
        ) +
        grid.wrapPanels(
          [
            panels.nodesOnlineTimeSeries,
            panels.nodesRoutesTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=12,
        ) +
        grid.wrapPanels(
          [
            panels.nodesInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=20,
        ) +
        grid.wrapPanels(
          [
            panels.nodesLifecycleTable,
            panels.nodesLastSeenTable,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=30,
        ) +
        [
          row.new('Users') +
          row.gridPos.withX(0) +
          row.gridPos.withY(38) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.usersByProviderPieChart,
          ],
          panelWidth=8,
          panelHeight=6,
          startY=39,
        ) +
        grid.wrapPanels(
          [
            panels.usersInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=45,
        ) +
        [
          row.new('Access Management') +
          row.gridPos.withX(0) +
          row.gridPos.withY(55) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.preAuthKeysUsagePieChart,
            panels.preAuthKeysReusablePieChart,
            panels.preAuthKeysEphemeralPieChart,
          ],
          panelWidth=8,
          panelHeight=6,
          startY=56,
        ) +
        grid.wrapPanels(
          [
            panels.apiKeysInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=62,
        ) +
        grid.wrapPanels(
          [
            panels.preAuthKeysInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=72,
        );

      dashboardUtil.bypassDashboardValidation +
      dashboard.new(
        'Headscale / Overview',
      ) +
      dashboard.withDescription('An overview of Headscale metrics collected by tailscale-exporter. %s' % dashboardUtil.dashboardDescriptionLink) +
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
