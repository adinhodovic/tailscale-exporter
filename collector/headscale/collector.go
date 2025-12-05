package headscale

import (
	"context"
	"log/slog"
	"sync"
	"time"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"github.com/prometheus/client_golang/prometheus"
	"google.golang.org/grpc/metadata"
)

const (
	namespace = "headscale"
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
		"Whether Headscale API is accessible.",
		nil,
	)
	scrapeDurationDesc = newDesc(
		"scrape",
		"collector_duration_seconds",
		"headscale_exporter: Duration of a collector scrape.",
		[]string{"collector"},
	)
	scrapeSuccessDesc = newDesc(
		"scrape",
		"collector_success",
		"headscale_exporter: Whether a collector succeeded.",
		[]string{"collector"},
	)
)

type collectorConfig struct {
	logger *slog.Logger
}

type Collector interface {
	Update(ctx context.Context, client HeadscaleClient, ch chan<- prometheus.Metric) error
}

type HeadscaleCollector struct {
	client     HeadscaleClient
	Collectors map[string]Collector
	logger     *slog.Logger
}

type HeadscaleClient interface {
	ListUsers(ctx context.Context) ([]*headscalev1.User, error)
	ListNodes(ctx context.Context) ([]*headscalev1.Node, error)
	ListAPIKeys(ctx context.Context) ([]*headscalev1.ApiKey, error)
	ListPreAuthKeys(ctx context.Context) ([]*headscalev1.PreAuthKey, error)
	Health(ctx context.Context) (*headscalev1.HealthResponse, error)
}

type grpcHeadscaleClient struct {
	client headscalev1.HeadscaleServiceClient
	apiKey string
}

func NewGRPCHeadscaleClient(
	client headscalev1.HeadscaleServiceClient,
	apiKey string,
) HeadscaleClient {
	return &grpcHeadscaleClient{
		client: client,
		apiKey: apiKey,
	}
}

func (c *grpcHeadscaleClient) ctxWithAuth(ctx context.Context) context.Context {
	if c.apiKey == "" {
		return ctx
	}
	return metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+c.apiKey)
}

func (c *grpcHeadscaleClient) ListUsers(ctx context.Context) ([]*headscalev1.User, error) {
	ctx = c.ctxWithAuth(ctx)
	resp, err := c.client.ListUsers(ctx, &headscalev1.ListUsersRequest{})
	if err != nil {
		return nil, err
	}
	return resp.GetUsers(), nil
}

func (c *grpcHeadscaleClient) ListNodes(ctx context.Context) ([]*headscalev1.Node, error) {
	ctx = c.ctxWithAuth(ctx)
	resp, err := c.client.ListNodes(ctx, &headscalev1.ListNodesRequest{})
	if err != nil {
		return nil, err
	}
	return resp.GetNodes(), nil
}

func (c *grpcHeadscaleClient) ListAPIKeys(ctx context.Context) ([]*headscalev1.ApiKey, error) {
	ctx = c.ctxWithAuth(ctx)
	resp, err := c.client.ListApiKeys(ctx, &headscalev1.ListApiKeysRequest{})
	if err != nil {
		return nil, err
	}
	return resp.GetApiKeys(), nil
}

func (c *grpcHeadscaleClient) ListPreAuthKeys(
	ctx context.Context,
) ([]*headscalev1.PreAuthKey, error) {
	ctx = c.ctxWithAuth(ctx)

	usersResp, err := c.client.ListUsers(ctx, &headscalev1.ListUsersRequest{})
	if err != nil {
		return nil, err
	}

	var keys []*headscalev1.PreAuthKey
	for _, user := range usersResp.GetUsers() {
		resp, err := c.client.ListPreAuthKeys(ctx, &headscalev1.ListPreAuthKeysRequest{
			User: user.GetId(),
		})
		if err != nil {
			return nil, err
		}
		keys = append(keys, resp.GetPreAuthKeys()...)
	}
	return keys, nil
}

func (c *grpcHeadscaleClient) Health(ctx context.Context) (*headscalev1.HealthResponse, error) {
	ctx = c.ctxWithAuth(ctx)
	return c.client.Health(ctx, &headscalev1.HealthRequest{})
}

func newDesc(subsystem, name, help string, variableLabels []string) *prometheus.Desc {
	return prometheus.NewDesc(
		prometheus.BuildFQName(namespace, subsystem, name),
		help,
		variableLabels,
		nil,
	)
}

func registerCollector(name string, createFunc func(collectorConfig) (Collector, error)) {
	factories[name] = createFunc
}

func NewHeadscaleCollector(
	logger *slog.Logger,
	client HeadscaleClient,
) (*HeadscaleCollector, error) {
	h := &HeadscaleCollector{
		logger: logger,
		client: client,
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

	h.Collectors = collectors
	return h, nil
}

func (h *HeadscaleCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- upDesc
	ch <- scrapeDurationDesc
	ch <- scrapeSuccessDesc
}

func (h *HeadscaleCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.TODO()
	wg := sync.WaitGroup{}
	wg.Add(len(h.Collectors))

	for name, c := range h.Collectors {
		go func(name string, c Collector) {
			execute(ctx, name, c, h.client, ch, h.logger)
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
	client HeadscaleClient,
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
