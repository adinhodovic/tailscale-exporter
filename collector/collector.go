package collector

import (
	"context"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"

	"tailscale.com/client/tailscale/v2"
)

const (
	namespace = "tailscale"
)

var (
	factories = make(
		map[string]func(collectorConfig) (Collector, error),
	)
	initiatedCollectorsMtx = sync.Mutex{}
	initiatedCollectors    = make(map[string]Collector)
)

var (
	upDesc = newDesc(
		"",
		"up",
		"Whether Tailscale API is accessible.",
		nil,
	)
	scrapeDurationDesc = newDesc(
		"scrape",
		"collector_duration_seconds",
		"tailscale_exporter: Duration of a collector scrape.",
		[]string{"collector"},
	)
	scrapeSuccessDesc = newDesc(
		"scrape",
		"collector_success",
		"tailscale_exporter: Whether a collector succeeded.",
		[]string{"collector"},
	)
)

func boolAsFloat(b bool) float64 {
	if b {
		return 1
	}
	return 0
}

type collectorConfig struct {
	logger *slog.Logger
}

func newDesc(
	subsystem, name, help string,
	variableLabels []string,
) *prometheus.Desc {
	return prometheus.NewDesc(
		prometheus.BuildFQName(namespace, subsystem, name),
		help, variableLabels, nil,
	)
}

func registerCollector(
	name string,
	createFunc func(collectorConfig) (Collector, error),
) {
	// Register the create function for this collector
	factories[name] = createFunc
}

type Collector interface {
	Update(
		ctx context.Context,
		client TailscaleClient,
		ch chan<- prometheus.Metric,
	) error
}

// TailscaleCollector collects comprehensive Tailscale metrics.
type TailscaleCollector struct {
	client TailscaleClient

	Collectors map[string]Collector
	logger     *slog.Logger
}

type TailscaleClient interface {
	Keys() KeysAPI
	DNS() DNSAPI
	Devices() DevicesAPI
	Users() UsersAPI
	TailnetSettings() TailnetSettingsAPI
}

// KeysAPI is the subset of *tailscale.KeysResource you actually use
type KeysAPI interface {
	List(ctx context.Context, all bool) ([]tailscale.Key, error)
}

// DNSAPI is the subset of *tailscale.DNSResource you actually use
type DNSAPI interface {
	Nameservers(ctx context.Context) ([]string, error)
	Preferences(ctx context.Context) (*tailscale.DNSPreferences, error)
}

// DevicesAPI is the subset of *tailscale.DevicesResource you actually use
type DevicesAPI interface {
	List(ctx context.Context) ([]tailscale.Device, error)
}

// UsersAPI is the subset of *tailscale.UsersResource you actually use
type UsersAPI interface {
	List(
		ctx context.Context,
		userType *tailscale.UserType,
		role *tailscale.UserRole,
	) ([]tailscale.User, error)
}

// TailnetSettingsAPI is the subset of *tailscale.TailnetSettingsResource you actually use
type TailnetSettingsAPI interface {
	Get(ctx context.Context) (*tailscale.TailnetSettings, error)
}

// TailscaleClientWrapper wraps the real tailscale.Client to implement our TailscaleClient interface
type TailscaleClientWrapper struct {
	client *tailscale.Client
}

func NewTailscaleClientWrapper(client *tailscale.Client) *TailscaleClientWrapper {
	return &TailscaleClientWrapper{client: client}
}

func (w *TailscaleClientWrapper) Keys() KeysAPI {
	return w.client.Keys()
}

func (w *TailscaleClientWrapper) DNS() DNSAPI {
	return w.client.DNS()
}

func (w *TailscaleClientWrapper) Devices() DevicesAPI {
	return w.client.Devices()
}

func (w *TailscaleClientWrapper) Users() UsersAPI {
	return w.client.Users()
}

func (w *TailscaleClientWrapper) TailnetSettings() TailnetSettingsAPI {
	return w.client.TailnetSettings()
}

// NewTailscaleCollector creates the Tailscale collector.
func NewTailscaleCollector(
	logger *slog.Logger,
	httpClient *http.Client,
	tailnet string,
) (*TailscaleCollector, error) {
	t := &TailscaleCollector{
		logger: logger,
	}

	collectors := make(map[string]Collector)
	initiatedCollectorsMtx.Lock()
	defer initiatedCollectorsMtx.Unlock()
	for key := range factories {
		if collector, ok := initiatedCollectors[key]; ok {
			collectors[key] = collector
		} else {
			coll, err := factories[key](collectorConfig{
				logger: logger.With("collector", key),
			})
			if err != nil {
				return nil, err
			}
			collectors[key] = coll
			initiatedCollectors[key] = coll
		}
	}

	t.Collectors = collectors

	client := &tailscale.Client{
		HTTP:    httpClient,
		Tailnet: tailnet,
	}
	t.client = NewTailscaleClientWrapper(client)

	return t, nil
}

// Describe implements the prometheus.Collector interface.
func (t *TailscaleCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- upDesc
	ch <- scrapeDurationDesc
	ch <- scrapeSuccessDesc
}

func (t *TailscaleCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.TODO()
	wg := sync.WaitGroup{}
	wg.Add(len(t.Collectors))

	for name, c := range t.Collectors {
		go func(name string, c Collector) {
			execute(ctx, name, c, t.client, ch, t.logger)
			wg.Done()
		}(name, c)
	}
	wg.Wait()
	ch <- prometheus.MustNewConstMetric(upDesc, prometheus.GaugeValue, 1)
}

func execute(
	ctx context.Context,
	name string,
	c Collector,
	client TailscaleClient,
	ch chan<- prometheus.Metric,
	logger *slog.Logger,
) {
	begin := time.Now()
	err := c.Update(ctx, client, ch)
	duration := time.Since(begin)
	var success float64

	if err != nil {
		logger.ErrorContext(
			ctx,
			"collector failed",
			"name",
			name,
			"duration_seconds",
			duration.Seconds(),
			"err",
			err,
		)
		success = 0
	} else {
		logger.DebugContext(ctx, "collector succeeded", "name", name, "duration_seconds", duration.Seconds())
		success = 1
	}
	ch <- prometheus.MustNewConstMetric(scrapeDurationDesc, prometheus.GaugeValue, duration.Seconds(), name)
	ch <- prometheus.MustNewConstMetric(scrapeSuccessDesc, prometheus.GaugeValue, success, name)
}
