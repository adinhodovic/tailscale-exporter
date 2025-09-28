local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboardUtil = import 'util.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local table = g.panel.table;

// Table
local tbStandardOptions = table.standardOptions;
local tbQueryOptions = table.queryOptions;
local tbOverride = tbStandardOptions.override;

{
  local dashboardName = 'tailscale-overview',
  grafanaDashboards+:: {
    ['%s.json' % dashboardName]:


      local defaultVariables = dashboardUtil.variables($._config);

      local variables = [
        defaultVariables.datasource,
        defaultVariables.cluster,
        defaultVariables.namespace,
        defaultVariables.job,
        defaultVariables.tailnet,
      ];

      local defaultFilters = dashboardUtil.filters($._config);
      local queries = {

        tailnetSettingsInfo: |||
          tailscale_tailnet_settings_info{
            %(tailnet)s
          }
        ||| % defaultFilters,

        usersTotal: |||
          sum(
            tailscale_users_info{
              %(tailnet)s
            }
          )
        ||| % defaultFilters,

        devicesTotal: |||
          sum(
            tailscale_devices_info{
              %(tailnet)s
            }
          )
        ||| % defaultFilters,

        devicesOnlineTotal: |||
          sum(
            tailscale_devices_online{
              %(tailnet)s
            }
          )
        ||| % defaultFilters,

        keysTotal: |||
          sum(
            tailscale_keys_info{
              %(tailnet)s
            }
          )
        ||| % defaultFilters,

        nameserversTotal: |||
          sum(
            tailscale_dns_nameservers_info{
              %(tailnet)s
            }
          ) by (nameserver)
        ||| % defaultFilters,

        magicDnsEnabled: |||
          sum(
            tailscale_dns_magic_dns{
              %(tailnet)s
            }
          )
        ||| % defaultFilters,

        devicesByOs: |||
          count(
            tailscale_devices_info{
              %(tailnet)s
            }
          ) by (os)
        ||| % defaultFilters,

        devicesByVersion: |||
          count(
            tailscale_devices_info{
              %(tailnet)s
            }
          ) by (client_version)
        ||| % defaultFilters,

        devicesUpdateAvailable: |||
          count(
            tailscale_devices_update_available{
              %(tailnet)s
            } == 1
          )
        ||| % defaultFilters,

        devicesUpdateNotAvailable: |||
          count(
            tailscale_devices_update_available{
              %(tailnet)s
            } == 0
          )
        ||| % defaultFilters,

        devicesAuthorized: |||
          count(
            tailscale_devices_authorized{
              %(tailnet)s
            } == 1
          )
        ||| % defaultFilters,

        devicesNotAuthorized: |||
          count(
            tailscale_devices_authorized{
              %(tailnet)s
            } == 0
          )
        ||| % defaultFilters,

        devicesInfo: |||
          tailscale_devices_info{
            %(tailnet)s
          }
        ||| % defaultFilters,

        devicesLastSeen: |||
          time() -
          max(
            tailscale_devices_last_seen_timestamp{
              %(tailnet)s
            }
          ) by (name, id, client_version)
        ||| % defaultFilters,

        devicesUpdateAvailableByNameId: |||
          sum(
            tailscale_devices_update_available{
              %(tailnet)s
            }
          ) by (name, id)
          == 1
        ||| % defaultFilters,

        devicesCreated: |||
          min(
            tailscale_devices_created_timestamp{
              %(tailnet)s
            } * 1000
          ) by (name, id)
        ||| % defaultFilters,

        devicesExpires: |||
          min(
            tailscale_devices_expires_timestamp{
              %(tailnet)s
            } * 1000
          ) by (name, id)
        ||| % defaultFilters,

        devicesAuthorizedByNameId: |||
          sum(
            tailscale_devices_authorized{
              %(tailnet)s
            }
          ) by (name, id)
        ||| % defaultFilters,

        devicesBlocksIncoming: |||
          sum(
            tailscale_devices_blocks_incoming{
              %(tailnet)s
            }
          ) by (name, id)
        ||| % defaultFilters,

        devicesRoutesEnabled: |||
          sum(
            tailscale_devices_routes_enabled{
              %(tailnet)s
            }
          ) by (name, id)
        ||| % defaultFilters,

        devicesRoutesAdvertised: |||
          sum(
            tailscale_devices_routes_advertised{
              %(tailnet)s
            }
          ) by (name, id)
        ||| % defaultFilters,

        devicesKeyExpiryDisabled: |||
          sum(
            tailscale_devices_key_expiry_disabled{
              %(tailnet)s
            }
          ) by (name, id)
        ||| % defaultFilters,

        devicesExternal: |||
          sum(
            tailscale_devices_external{
              %(tailnet)s
            }
          ) by (name, id)
        ||| % defaultFilters,


        usersByRole: |||
          count(
            tailscale_users_info{
              %(tailnet)s
            }
          ) by (role)
        ||| % defaultFilters,

        usersByStatus: |||
          count(
            tailscale_users_info{
              %(tailnet)s
            }
          ) by (status)
        ||| % defaultFilters,

        usersByType: |||
          count(
            tailscale_users_info{
              %(tailnet)s
            }
          ) by (type)
        ||| % defaultFilters,

        usersLoggedIn: |||
          count(
            tailscale_users_currently_logged_in{
              %(tailnet)s
            } == 1
          )
        ||| % defaultFilters,

        usersLoggedOut: |||
          count(
            tailscale_users_currently_logged_in{
              %(tailnet)s
            } == 0
          )
        ||| % defaultFilters,

        usersInfo: |||
          tailscale_users_info{
            %(tailnet)s
          }
        ||| % defaultFilters,

        usersCreated: |||
          min(
            tailscale_users_created_timestamp{
              %(tailnet)s
            } * 1000
          ) by (name, id)
        ||| % defaultFilters,

        usersLastSeen: |||
          max(
            tailscale_users_last_seen_timestamp{
              %(tailnet)s
            } * 1000
          ) by (name, id)
        ||| % defaultFilters,

        // Keys
        keysInfo: |||
          tailscale_keys_info{
            %(tailnet)s
          }
        ||| % defaultFilters,

        keysCreated: |||
          min(
            tailscale_keys_created_timestamp{
              %(tailnet)s
            } * 1000
          ) by (name, id, key_type, user_id)
        ||| % defaultFilters,

        keysExpires: |||
          min(
            tailscale_keys_expires_timestamp{
              %(tailnet)s
            } * 1000
          ) by (name, id, key_type, user_id)
        ||| % defaultFilters,
      };

      local panels = {
        tailnetSettingsInfoTable:
          dashboardUtil.tablePanel(
            'Tailnet Settings',
            'bool',
            queries.tailnetSettingsInfo,
            description='A table showing the current settings for the selected tailnet.',
            sortBy={ name: 'Tailnet', desc: true },
            transformations=[
              tbQueryOptions.transformation.withId(
                'merge'
              ),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    tailnet: 'Tailnet',
                    acls_externally_managed_on: 'ACLs Externally Managed',
                    devices_approval_on: 'Devices Approval',
                    devices_auto_updates_on: 'Devices Auto Updates',
                    network_flow_logging_on: 'Network Flow Logging',
                    posture_identity_collection_on: 'Posture Identity Collection',
                    regional_routing_on: 'Regional Routing',
                    users_approval_on: 'Users Approval',
                    Value: 'Up',
                  },
                  indexByName: {
                    tailnet: 0,
                    acls_externally_managed_on: 1,
                    devices_approval_on: 2,
                    devices_auto_updates_on: 3,
                    network_flow_logging_on: 4,
                    posture_identity_collection_on: 5,
                    regional_routing_on: 6,
                    users_approval_on: 7,
                    Value: 8,
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
                    region: true,
                    prometheus: true,
                  },
                }
              ),
            ],
          ),

        usersTotalStat:
          dashboardUtil.statPanel(
            'Total Users',
            'short',
            queries.usersTotal,
            description='The total number of users in the selected tailnet.',
          ),

        devicesTotalStat:
          dashboardUtil.statPanel(
            'Total Devices',
            'short',
            queries.devicesTotal,
            description='The total number of devices in the selected tailnet.',
          ),

        devicesOnlineTotalStat:
          dashboardUtil.statPanel(
            'Devices Logged In',
            'short',
            queries.devicesOnlineTotal,
            description='The total number of devices that are currently online in the selected tailnet.',
          ),

        keysTotalStat:
          dashboardUtil.statPanel(
            'Total Keys',
            'short',
            queries.keysTotal,
            description='The total number of keys in the selected tailnet.',
          ),

        nameserversTotalTable:
          dashboardUtil.tablePanel(
            'Nameservers',
            'string',
            queries.nameserversTotal,
            description='A table showing the nameservers configured for the selected tailnet.',
            sortBy={ name: 'Nameserver', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    nameserver: 'Nameserver',
                  },
                  indexByName: {
                    nameserver: 0,
                    Value: 1,
                  },
                  excludeByName: {
                    Time: true,
                    Value: true,
                  },
                }
              ),
            ],
          ),

        magicDnsEnabledStat:
          dashboardUtil.statPanel(
            'Magic DNS Enabled',
            'bool',
            queries.magicDnsEnabled,
            description='Whether Magic DNS is enabled for the selected tailnet.',
          ),

        // Devices
        devicesByOsPieChart:
          dashboardUtil.pieChartPanel(
            'Devices by OS',
            'short',
            queries.devicesByOs,
            '{{ os }}',
            description='A pie chart showing the distribution of devices by operating system in the selected tailnet.',
          ),

        devicesByVersionPieChart:
          dashboardUtil.pieChartPanel(
            'Devices by Version',
            'short',
            queries.devicesByVersion,
            '{{ client_version }}',
            description='A pie chart showing the distribution of devices by Tailscale client version in the selected tailnet.',
          ),

        devicesUpdateAvailablePieChart:
          dashboardUtil.pieChartPanel(
            'Devices with Update Available',
            'short',
            [
              {
                expr: queries.devicesUpdateAvailable,
                legend: 'Update Available',
              },
              {
                expr: queries.devicesUpdateNotAvailable,
                legend: 'No Update Available',
              },
            ],
            description='The total number of devices that have an update available in the selected tailnet.',
          ),

        devicesAuthorizedPieChart:
          dashboardUtil.pieChartPanel(
            'Authorized Devices',
            'short',
            [
              {
                expr: queries.devicesAuthorized,
                legend: 'Authorized',
              },
              {
                expr: queries.devicesNotAuthorized,
                legend: 'Not Authorized',
              },
            ],
            description='The total number of devices that are authorized to access the tailnet.',
          ),

        devicesInfoTable:
          dashboardUtil.tablePanel(
            'Devices',
            'string',
            queries.devicesInfo,
            description='A table showing all devices in the selected tailnet.',
            sortBy={ name: 'Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    name: 'Name',
                    user: 'User',
                    os: 'OS',
                    client_version: 'Client Version',
                    hostname: 'Host Name',
                    tailscale_ip: 'Tailscale IP',
                    id: 'ID',
                    machine_key: 'Machine Key',
                    node_key: 'Node Key',
                  },
                  indexByName: {
                    name: 0,
                    user: 1,
                    os: 2,
                    client_version: 3,
                    hostname: 4,
                    tailscale_ip: 5,
                    id: 6,
                    machine_key: 7,
                    node_key: 8,
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
                    region: true,
                    prometheus: true,
                    tailnet: true,
                    Value: true,
                  },
                }
              ),
            ],
          ),

        devicesUpdateAvailableTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Update Available',
            'bool',
            queries.devicesUpdateAvailableByNameId,
            '{{name}}',
            description='A timeseries panel showing devices that have an update available.',
          ),

        devicesLastSeenTimeSeries:
          dashboardUtil.timeSeriesPanel(
            'Time Since Last Seen',
            's',
            queries.devicesLastSeen,
            '{{name}}',
            description='A timeseries panel showing the last time a device was seen.',
          ),

        devicesSettingsInfoTable:
          dashboardUtil.tablePanel(
            'Devices Settings',
            'bool',
            [
              {
                expr: queries.devicesCreated,
              },
              {
                expr: queries.devicesExpires,
              },
              {
                expr: queries.devicesAuthorizedByNameId,
              },
              {
                expr: queries.devicesBlocksIncoming,
              },
              {
                expr: queries.devicesRoutesEnabled,
              },
              {
                expr: queries.devicesRoutesAdvertised,
              },
              {
                expr: queries.devicesKeyExpiryDisabled,
              },
              {
                expr: queries.devicesExternal,
              },
            ],
            description='A table showing all devices in the selected tailnet.',
            sortBy={ name: 'Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'merge'
              ),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    name: 'Name',
                    id: 'ID',
                    'Value #A': 'Created',
                    'Value #B': 'Expires',
                    'Value #C': 'Authorized',
                    'Value #D': 'Blocks Incoming',
                    'Value #E': 'Routes Enabled',
                    'Value #F': 'Routes Advertised',
                    'Value #G': 'Key Expiry Disabled',
                    'Value #H': 'External',
                  },
                  indexByName: {
                    name: 0,
                    id: 1,
                    'Value #A': 2,
                    'Value #B': 3,
                    'Value #C': 4,
                    'Value #D': 5,
                    'Value #E': 6,
                    'Value #F': 7,
                    'Value #G': 8,
                    'Value #H': 9,
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
                    region: true,
                    prometheus: true,
                    tailnet: true,
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
              tbOverride.byName.new('ID') +
              tbOverride.byName.withPropertiesFromOptions(
                tbStandardOptions.withUnit('string')
              ),
            ]
          ),

        // Users
        usersByRolePieChart:
          dashboardUtil.pieChartPanel(
            'Users by Role',
            'short',
            queries.usersByRole,
            '{{ role }}',
            description='A pie chart showing the distribution of users by role in the selected tailnet.',
          ),

        usersByStatusPieChart:
          dashboardUtil.pieChartPanel(
            'Users by Status',
            'short',
            queries.usersByStatus,
            '{{ status }}',
            description='A pie chart showing the distribution of users by status in the selected tailnet.',
          ),

        usersByTypePieChart:
          dashboardUtil.pieChartPanel(
            'Users by Type',
            'short',
            queries.usersByType,
            '{{ type }}',
            description='A pie chart showing the distribution of users by type in the selected tailnet.',
          ),

        usersLoggedInPieChart:
          dashboardUtil.pieChartPanel(
            'Users Logged In',
            'short',
            [
              {
                expr: queries.usersLoggedIn,
                legend: 'Logged In',
              },
              {
                expr: queries.usersLoggedOut,
                legend: 'Logged Out',
              },
            ],
            description='The total number of users that are currently logged in to the selected tailnet.',
          ),

        usersInfoTable:
          dashboardUtil.tablePanel(
            'Users',
            'short',
            [
              {
                expr: queries.usersInfo,
              },
              {
                expr: queries.usersCreated,
              },
              {
                expr: queries.usersLastSeen,
              },
            ],
            description='A table showing all users in the selected tailnet.',
            sortBy={ name: 'Login Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'merge'
              ),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    login_name: 'Login Name',
                    display_name: 'Display Name',
                    id: 'ID',
                    'Value #B': 'Created',
                    'Value #C': 'Last Seen',
                    role: 'Role',
                    status: 'Status',
                    type: 'Type',
                  },
                  indexByName: {
                    login_name: 0,
                    display_name: 1,
                    id: 2,
                    'Value #B': 3,
                    'Value #C': 4,
                    role: 5,
                    status: 6,
                    type: 7,
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
                    region: true,
                    prometheus: true,
                    tailnet: true,
                    'Value #A': true,
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
            ]
          ),

        // Keys
        keysInfoTable:
          dashboardUtil.tablePanel(
            'Keys',
            'string',
            [
              {
                expr: queries.keysInfo,
              },
              {
                expr: queries.keysCreated,
              },
              {
                expr: queries.keysExpires,
              },
            ],
            description='A table showing all keys in the selected tailnet.',
            sortBy={ name: 'Name', desc: false },
            transformations=[
              tbQueryOptions.transformation.withId(
                'merge'
              ),
              tbQueryOptions.transformation.withId(
                'organize'
              ) +
              tbQueryOptions.transformation.withOptions(
                {
                  renameByName: {
                    id: 'ID',
                    'Value #B': 'Created',
                    'Value #C': 'Expires',
                    user_id: 'User ID',
                    key_type: 'Key Type',
                  },
                  indexByName: {
                    name: 0,
                    id: 1,
                    user_id: 2,
                    key_type: 3,
                    'Value #B': 4,
                    'Value #C': 5,
                  },
                  excludeByName: {
                    Time: true,
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
                    region: true,
                    prometheus: true,
                    tailnet: true,
                    Value: true,
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
            panels.usersTotalStat,
            panels.devicesTotalStat,
            panels.devicesOnlineTotalStat,
            panels.keysTotalStat,
            panels.nameserversTotalTable,
            panels.magicDnsEnabledStat,
          ],
          panelWidth=4,
          panelHeight=4,
          startY=1,
        ) +
        grid.wrapPanels(
          [
            panels.tailnetSettingsInfoTable,
          ],
          panelWidth=24,
          panelHeight=5,
          startY=5,
        ) +
        [
          row.new('Devices') +
          row.gridPos.withX(0) +
          row.gridPos.withY(10) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.devicesByOsPieChart,
            panels.devicesByVersionPieChart,
            panels.devicesUpdateAvailablePieChart,
            panels.devicesAuthorizedPieChart,
          ],
          panelWidth=6,
          panelHeight=5,
          startY=11,
        ) +
        grid.wrapPanels(
          [
            panels.devicesInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=16
        ) +
        grid.wrapPanels(
          [
            panels.devicesSettingsInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=26,
        ) +
        grid.wrapPanels(
          [
            panels.devicesUpdateAvailableTimeSeries,
            panels.devicesLastSeenTimeSeries,
          ],
          panelWidth=12,
          panelHeight=8,
          startY=36,
        ) +
        [
          row.new('Users') +
          row.gridPos.withX(0) +
          row.gridPos.withY(44) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.usersByRolePieChart,
            panels.usersByStatusPieChart,
            panels.usersByTypePieChart,
            panels.usersLoggedInPieChart,
          ],
          panelWidth=6,
          panelHeight=5,
          startY=45,
        ) +
        grid.wrapPanels(
          [
            panels.usersInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=50,
        ) +
        [
          row.new('Keys') +
          row.gridPos.withX(0) +
          row.gridPos.withY(60) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.keysInfoTable,
          ],
          panelWidth=24,
          panelHeight=10,
          startY=61,
        );

      dashboardUtil.bypassDashboardValidation +
      dashboard.new(
        'Tailscale / Overview',
      ) +
      dashboard.withDescription('A dashboard that gives an overview of Tailscale API metrics. %s' % dashboardUtil.dashboardDescriptionLink) +
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
