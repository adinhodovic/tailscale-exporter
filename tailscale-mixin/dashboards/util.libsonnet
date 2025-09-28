local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local annotation = g.dashboard.annotation;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;
local prometheus = g.query.prometheus;

local stat = g.panel.stat;
local timeSeries = g.panel.timeSeries;
local table = g.panel.table;
local pieChart = g.panel.pieChart;

// Stat
local stStandardOptions = stat.standardOptions;
local stQueryOptions = stat.queryOptions;
local stPanelOptions = stat.panelOptions;

// PieChart
local pcOptions = pieChart.options;
local pcStandardOptions = pieChart.standardOptions;
local pcPanelOptions = pieChart.panelOptions;
local pcQueryOptions = pieChart.queryOptions;
local pcLegend = pcOptions.legend;

// TimeSeries
local tsOptions = timeSeries.options;
local tsStandardOptions = timeSeries.standardOptions;
local tsPanelOptions = timeSeries.panelOptions;
local tsQueryOptions = timeSeries.queryOptions;
local tsFieldConfig = timeSeries.fieldConfig;
local tsCustom = tsFieldConfig.defaults.custom;
local tsLegend = tsOptions.legend;

// Table
local tbOptions = table.options;
local tbStandardOptions = table.standardOptions;
local tbQueryOptions = table.queryOptions;

{
  // Bypasses grafana.com/dashboards validator
  bypassDashboardValidation: {
    __inputs: [],
    __requires: [],
  },

  dashboardDescriptionLink: 'The dashboards were generated using [tailscale-mixin](https://github.com/adinhodovic/tailscale-exporter/tree/main/tailscale-mixin). Open issues and create feature requests in the repository.',

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

    cluster:
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

    namespace:
      query.new(
        'namespace',
        'label_values(tailscale_up{%(cluster)s}, namespace)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Namespace') +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    job:
      query.new(
        'job',
        'label_values(tailscale_up{%(cluster)s, %(namespace)s}, job)' % defaultFilters
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

  statPanel(
    title,
    unit,
    query,
    description=null,
    steps=[
      stStandardOptions.threshold.step.withValue(0) +
      stStandardOptions.threshold.step.withColor('green'),
    ],
    mappings=[]
  )::
    stat.new(title) +
    (
      if description != null then
        stPanelOptions.withDescription(description)
      else {}
    ) +
    stQueryOptions.withTargets([
      prometheus.new('${datasource}', query),
    ]) +
    variable.query.withDatasource('prometheus', '$datasource') +
    stStandardOptions.withUnit(unit) +
    stStandardOptions.thresholds.withSteps(steps) +
    stStandardOptions.withMappings(
      mappings
    ),


  pieChartPanel(title, unit, query, legend='', description='', values=['percent'])::
    pieChart.new(
      title,
    ) +
    pieChart.new(title) +
    (
      if description != '' then
        pcPanelOptions.withDescription(description)
      else {}
    ) +
    variable.query.withDatasource('prometheus', '$datasource') +
    pcQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withLegendFormat(
            q.legend
          ) +
          prometheus.withInstant(true)
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        ) +
        prometheus.withLegendFormat(
          legend
        ) +
        prometheus.withInstant(true)
    ) +
    pcStandardOptions.withUnit(unit) +
    pcOptions.tooltip.withMode('multi') +
    pcOptions.tooltip.withSort('desc') +
    pcOptions.withDisplayLabels(values) +
    pcLegend.withShowLegend(true) +
    pcLegend.withDisplayMode('table') +
    pcLegend.withPlacement('right') +
    pcLegend.withValues(values),

  timeSeriesPanel(title, unit, query, legend='', calcs=['mean', 'max'], stack=null, description=null, exemplar=false)::
    timeSeries.new(title) +
    (
      if description != null then
        tsPanelOptions.withDescription(description)
      else {}
    ) +
    variable.query.withDatasource('prometheus', '$datasource') +
    tsQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withLegendFormat(
            q.legend
          ) +
          prometheus.withExemplar(
            // allows us to override exemplar per query if needed
            std.get(q, 'exemplar', default=exemplar)
          )
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        ) +
        prometheus.withLegendFormat(
          legend
        ) +
        prometheus.withExemplar(exemplar)
    ) +
    tsStandardOptions.withUnit(unit) +
    tsOptions.tooltip.withMode('multi') +
    tsOptions.tooltip.withSort('desc') +
    tsLegend.withShowLegend() +
    tsLegend.withDisplayMode('table') +
    tsLegend.withPlacement('right') +
    tsLegend.withCalcs(calcs) +
    tsLegend.withSortBy('Mean') +
    tsLegend.withSortDesc(true) +
    tsCustom.withFillOpacity(10) +
    (
      if stack == 'normal' then
        tsCustom.withAxisSoftMin(0) +
        tsCustom.withFillOpacity(100) +
        tsCustom.stacking.withMode(stack) +
        tsCustom.withLineWidth(1)
      else if stack == 'percent' then
        tsCustom.withFillOpacity(100) +
        tsCustom.stacking.withMode(stack) +
        tsCustom.withLineWidth(1)
      else {}
    ),

  tablePanel(title, unit, query, description=null, sortBy=null, transformations=[], overrides=[])::
    table.new(title) +
    (
      if description != null then
        tsPanelOptions.withDescription(description)
      else {}
    ) +
    tbStandardOptions.withUnit(unit) +
    tbOptions.footer.withEnablePagination(true) +
    variable.query.withDatasource('prometheus', '$datasource') +
    tsQueryOptions.withTargets(
      if std.isArray(query) then
        [
          prometheus.new(
            '$datasource',
            q.expr,
          ) +
          prometheus.withFormat('table') +
          prometheus.withInstant(true)
          for q in query
        ] else
        prometheus.new(
          '$datasource',
          query,
        ) +
        prometheus.withFormat('table') +
        prometheus.withInstant(true)
    ) +
    (
      if sortBy != null then
        tbOptions.withSortBy(
          tbOptions.sortBy.withDisplayName(sortBy.name) +
          tbOptions.sortBy.withDesc(sortBy.desc)
        ) else {}
    ) +
    tbQueryOptions.withTransformations(transformations) +
    tbStandardOptions.withOverrides(overrides),

  annotations(config, filters)::
    local customAnnotation =
      annotation.withName(config.annotation.name) +
      annotation.withIconColor(config.annotation.iconColor) +
      annotation.withEnable(true) +
      annotation.withHide(false) +
      annotation.datasource.withUid(config.annotation.datasource) +
      annotation.target.withType(config.annotation.type) +
      (
        if config.annotation.type == 'tags' then
          annotation.target.withMatchAny(true) +
          if std.length(config.annotation.tags) > 0 then
            annotation.target.withTags(config.annotation.tags)
          else {}
        else {}
      );

    std.prune([
      if config.annotation.enabled then customAnnotation,
    ]),

  dashboardLinks(config):: [
    dashboard.link.dashboards.new('Tailscale', config.tags) +
    dashboard.link.link.options.withTargetBlank(true) +
    dashboard.link.link.options.withAsDropdown(false) +
    dashboard.link.link.options.withIncludeVars(false) +
    dashboard.link.link.options.withKeepTime(true),
  ],
}
