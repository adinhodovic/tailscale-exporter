package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	headscaleCollector "github.com/adinhodovic/tailscale-exporter/collector/headscale"
	tailscale "github.com/adinhodovic/tailscale-exporter/collector/tailscale"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"golang.org/x/oauth2/clientcredentials"

	headscalev1 "github.com/juanfont/headscale/gen/go/headscale/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

var (
	// Global flags.
	listenAddress string
	metricsPath   string

	// Tailscale
	tailnet           string
	oauthClientID     string
	oauthClientSecret string

	// Headscale
	headscaleAddress  string
	headscaleAPIKey   string
	headscaleInsecure bool
)

// rootCmd represents the base command when called without any subcommands.
var rootCmd = &cobra.Command{
	Use:   "tailscale-exporter",
	Short: "Prometheus exporter for Tailscale metrics",
	Long: `A Prometheus exporter that collects metrics from the Tailscale API.

This exporter collects information about devices, users, DNS settings, and API keys
from your Tailscale tailnet and exposes them as Prometheus metrics.`,
	RunE: runExporter,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().
		StringVarP(&listenAddress, "listen-address", "l", ":9250", "Address to listen on for web interface and telemetry")
	rootCmd.PersistentFlags().
		StringVarP(&metricsPath, "metrics-path", "m", "/metrics", "Path under which to expose metrics")
	rootCmd.PersistentFlags().
		StringVarP(&tailnet, "tailnet", "t", "", "Tailscale tailnet (can also be set via TAILSCALE_TAILNET environment variable)")
	rootCmd.PersistentFlags().
		StringVar(&headscaleAddress, "headscale-address", "", "Headscale gRPC address (can also be set via HEADSCALE_ADDRESS environment variable)")
	rootCmd.PersistentFlags().
		StringVar(&headscaleAPIKey, "headscale-api-key", "", "Headscale API key (can also be set via HEADSCALE_API_KEY environment variable)")
	rootCmd.PersistentFlags().
		BoolVar(&headscaleInsecure, "headscale-insecure", false, "Allow insecure (plaintext) gRPC connection to Headscale (can also be set via HEADSCALE_INSECURE environment variable)")

	// Authentication flags - API Key or OAuth
	rootCmd.PersistentFlags().
		StringVar(&oauthClientID, "oauth-client-id", "", "OAuth client ID (can also be set via TAILSCALE_OAUTH_CLIENT_ID environment variable)")
	rootCmd.PersistentFlags().
		StringVar(&oauthClientSecret, "oauth-client-secret", "", "OAuth client secret (can also be set via TAILSCALE_OAUTH_CLIENT_SECRET environment variable)")

	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	viper.AutomaticEnv()

	mustBindFlag("listen-address")
	mustBindFlag("metrics-path")
	mustBindFlag("tailnet")
	mustBindFlag("headscale-address")
	mustBindFlag("headscale-api-key")
	mustBindFlag("headscale-insecure")
	mustBindFlag("oauth-client-id")
	mustBindFlag("oauth-client-secret")

	mustBindEnv("tailnet", "TAILSCALE_TAILNET")
	mustBindEnv("oauth-client-id", "TAILSCALE_OAUTH_CLIENT_ID")
	mustBindEnv("oauth-client-secret", "TAILSCALE_OAUTH_CLIENT_SECRET")
	mustBindEnv("headscale-address", "HEADSCALE_ADDRESS")
	mustBindEnv("headscale-api-key", "HEADSCALE_API_KEY")
	mustBindEnv("headscale-insecure", "HEADSCALE_INSECURE")
}

func runExporter(cmd *cobra.Command, args []string) error {
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))

	logger.Info("Starting tailscale_exporter",
		"version", version,
	)

	logger.Info("Build info",
		"commit", commit,
		"build_time", buildTime,
	)

	listenAddress = strings.TrimSpace(viper.GetString("listen-address"))
	metricsPath = strings.TrimSpace(viper.GetString("metrics-path"))
	tailnet = strings.TrimSpace(viper.GetString("tailnet"))
	oauthClientID = strings.TrimSpace(viper.GetString("oauth-client-id"))
	oauthClientSecret = strings.TrimSpace(viper.GetString("oauth-client-secret"))
	headscaleAddress = strings.TrimSpace(viper.GetString("headscale-address"))
	headscaleAPIKey = strings.TrimSpace(viper.GetString("headscale-api-key"))
	headscaleInsecure = viper.GetBool("headscale-insecure")

	registered := false

	if tailnet != "" {
		if oauthClientID == "" || oauthClientSecret == "" {
			return errors.New("oauth credentials are required when tailnet is set")
		}

		oauthConfig := &clientcredentials.Config{
			ClientID:     oauthClientID,
			ClientSecret: oauthClientSecret,
			TokenURL:     "https://api.tailscale.com/api/v2/oauth/token",
			Scopes: []string{
				"devices:core:read",
				"devices:posture_attributes:read",
				"devices:routes:read",
				"users:read",
				"dns:read",
				"auth_keys:read",
				"feature_settings:read",
				"policy_file:read",
			},
		}

		httpClient := oauthConfig.Client(context.Background())
		token, err := oauthConfig.Token(context.Background())
		if err != nil {
			return fmt.Errorf("failed to obtain OAuth token: %w", err)
		}
		logger.Info("OAuth token obtained", "token_type", token.TokenType)
		logger.Info("Successfully obtained OAuth token", "expires", token.Expiry)

		tsCollector, err := tailscale.NewTailscaleCollector(
			logger,
			httpClient,
			tailnet,
		)
		if err != nil {
			return fmt.Errorf("failed to create Tailscale collector: %w", err)
		}

		tsReg := prometheus.WrapRegistererWith(
			prometheus.Labels{"tailnet": tailnet},
			prometheus.DefaultRegisterer,
		)
		tsReg.MustRegister(tsCollector)
		registered = true
		logger.Info("Tailscale metrics enabled", "tailnet", tailnet)
	} else {
		logger.Info("Tailscale metrics disabled", "reason", "tailnet not set")
	}

	// Optional Headscale metrics.
	if headscaleAddress != "" {
		if headscaleAPIKey == "" {
			return errors.New("HEADSCALE_API_KEY (or --headscale-api-key) is required when HEADSCALE_ADDRESS is set")
		}

		var transportCreds credentials.TransportCredentials
		if headscaleInsecure {
			logger.Warn("Using insecure gRPC connection to Headscale", "address", headscaleAddress)
			transportCreds = insecure.NewCredentials()
		} else {
			transportCreds = credentials.NewTLS(&tls.Config{
				MinVersion: tls.VersionTLS12,
			})
		}

		conn, err := grpc.Dial(
			headscaleAddress,
			grpc.WithTransportCredentials(transportCreds),
		)
		if err != nil {
			return fmt.Errorf("failed to connect to headscale: %w", err)
		}
		defer func() {
			if err := conn.Close(); err != nil {
				logger.Error("Failed to close headscale connection", "error", err)
			}
		}()

		hsClient := headscaleCollector.NewGRPCHeadscaleClient(
			headscalev1.NewHeadscaleServiceClient(conn),
			headscaleAPIKey,
		)
		hsCollector, err := headscaleCollector.NewHeadscaleCollector(
			logger.With("system", "headscale"),
			hsClient,
		)
		if err != nil {
			return fmt.Errorf("failed to create Headscale collector: %w", err)
		}
		prometheus.DefaultRegisterer.MustRegister(hsCollector)
		registered = true
		logger.Info("Headscale metrics enabled", "address", headscaleAddress)
	} else {
		logger.Info("Headscale metrics disabled", "reason", "HEADSCALE_ADDRESS not set")
	}

	if !registered {
		logger.Error("No collectors enabled", "action", "set --tailnet or --headscale-address")
		return errors.New("at least one metrics source (tailnet or headscale) must be configured")
	}

	// Create HTTP server
	http.Handle(metricsPath, promhttp.Handler())

	// Root handler with simple landing page
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		_, err := w.Write([]byte(`<html>
			<head><title>Tailscale Exporter</title></head>
			<body>
			<h1>Tailscale Exporter</h1>
			<p><a href='` + metricsPath + `'>Metrics</a></p>
			</body>
			</html>`))
		if err != nil {
			logger.Error("Error writing response", "err", err)
		}
	})

	server := &http.Server{
		Addr:         listenAddress,
		Handler:      nil,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	// Handle graceful shutdown
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint

		logger.Info("Received interrupt signal, shutting down...")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			logger.Error("HTTP server shutdown error", "err", err)
		}
	}()

	logger.Info("Listening", "address", listenAddress)
	if err := server.ListenAndServe(); err != http.ErrServerClosed {
		return fmt.Errorf("HTTP server failed: %w", err)
	}

	logger.Info("Tailscale exporter stopped")
	return nil
}

// SetVersionInfo sets the version information for the command.
func SetVersionInfo(v, c, bt string) {
	version = v
	commit = c
	buildTime = bt
}

func mustBindFlag(name string) {
	if err := viper.BindPFlag(name, rootCmd.PersistentFlags().Lookup(name)); err != nil {
		panic(fmt.Errorf("failed to bind flag %s: %w", name, err))
	}
}

func mustBindEnv(key, env string) {
	if err := viper.BindEnv(key, env); err != nil {
		panic(fmt.Errorf("failed to bind env for %s: %w", key, err))
	}
}
