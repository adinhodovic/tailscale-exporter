local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;

{
  filters(config):: {
    local this = self,
    cluster: '%(clusterLabel)s="$cluster"' % config,
    namespace: 'namespace="$namespace"',
    job: 'job="$job"',
    jobMulti: 'job=~"$job"',

    // Tailnet
    tailnetV: 'tailnet="$tailnet"',

    // Tailscaled
    tailscaledMachineV: 'tailscale_machine="$tailscale_machine"',

    base: |||
      %(cluster)s
    ||| % this,

    tailnet: |||
      %(base)s,
      %(namespace)s,
      %(job)s,
      %(tailnetV)s
    ||| % this,

    tailscaled: |||
      %(base)s,
      %(jobMulti)s
    ||| % this,

    tailscaledMachine: |||
      %(tailscaled)s,
      %(tailscaledMachineV)s
    ||| % this,
  },

  variables(config):: {
    local this = self,

    local defaultFilters = $.filters(config),

    datasource:
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source') +
      {
        current: {
          selected: true,
          text: config.datasourceName,
          value: config.datasourceName,
        },
      },

    clusterTailscale:
      query.new(
        config.clusterLabel,
        'label_values(tailscale_up{}, cluster)',
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    clusterHeadscale:
      query.new(
        config.clusterLabel,
        'label_values(headscale_up, cluster)',
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    namespaceTailscale:
      query.new(
        'namespace',
        'label_values(tailscale_up{%(cluster)s}, namespace)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Namespace') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    namespaceHeadscale:
      query.new(
        'namespace',
        'label_values(headscale_up{%(cluster)s}, namespace)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Namespace') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    jobTailscale:
      query.new(
        'job',
        'label_values(tailscale_up{%(cluster)s, %(namespace)s}, job)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    jobHeadscale:
      query.new(
        'job',
        'label_values(headscale_up{%(cluster)s, %(namespace)s}, job)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Job') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    tailnet:
      query.new(
        'tailnet',
        'label_values(tailscale_up{%(cluster)s, %(namespace)s, %(job)s}, tailnet)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Tailnet') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    tailscaledCluster:
      query.new(
        config.clusterLabel,
        'label_values(tailscaled_health_messages, cluster)',
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    tailscaledJob:
      query.new(
        'job',
        'label_values(tailscaled_health_messages{%(cluster)s}, job)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('job') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    tailscaledMachine:
      query.new(
        'tailscale_machine',
        'label_values(tailscaled_health_messages{%(cluster)s, %(jobMulti)s}, tailscale_machine)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Tailscale Machine') +
      query.refresh.onLoad() +
      query.refresh.onTime(),
  },
}
