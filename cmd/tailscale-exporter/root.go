package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/spf13/cobra"
	"golang.org/x/oauth2/clientcredentials"

	"github.com/adinhodovic/tailscale-exporter/collector"
)

var (
	// Global flags.
	listenAddress string
	metricsPath   string
	tailnet       string

	// OAuth flags.
	oauthClientID     string
	oauthClientSecret string
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

	// Authentication flags - API Key or OAuth
	rootCmd.PersistentFlags().
		StringVar(&oauthClientID, "oauth-client-id", "", "OAuth client ID (can also be set via TAILSCALE_OAUTH_CLIENT_ID environment variable)")
	rootCmd.PersistentFlags().
		StringVar(&oauthClientSecret, "oauth-client-secret", "", "OAuth client secret (can also be set via TAILSCALE_OAUTH_CLIENT_SECRET environment variable)")

	// Bind environment variables
	if rootCmd.PersistentFlags().Lookup("tailnet").Value.String() == "" {
		tailnet = getTailnetFromEnv()
	}
	if rootCmd.PersistentFlags().
		Lookup("oauth-client-id").
		Value.String() == "" {
		oauthClientID = getOAuthClientIDFromEnv()
	}
	if rootCmd.PersistentFlags().
		Lookup("oauth-client-secret").
		Value.String() == "" {
		oauthClientSecret = getOAuthClientSecretFromEnv()
	}
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

	// Get tailnet from flag or environment
	if tailnet == "" {
		tailnet = getTailnetFromEnv()
	}
	if tailnet == "" {
		return errors.New(
			"tailnet is required. Set via --tailnet flag or TAILSCALE_TAILNET environment variable",
		)
	}

	logger.Info("Using tailnet", "tailnet", tailnet)

	// Check if OAuth is requested or if OAuth credentials are provided
	if oauthClientID == "" && oauthClientSecret == "" {
		return errors.New(
			"authentication is required. Use OAuth with --oauth-client-id and --oauth-client-secret flags",
		)
	}
	oauthClientID = getOAuthClientIDFromEnv()
	oauthClientSecret = getOAuthClientSecretFromEnv()

	// Create OAuth client using client credentials flow
	oauthConfig := &clientcredentials.Config{
		ClientID:     oauthClientID,
		ClientSecret: oauthClientSecret,
		TokenURL:     "https://api.tailscale.com/api/v2/oauth/token",
		Scopes: []string{
			"devices:read",
			"users:read",
			"dns:read",
			"auth_keys:read",
		}, // Request needed scopes
	}

	// Create HTTP client that automatically handles token refresh
	httpClient := oauthConfig.Client(context.Background())

	// Test OAuth token generation
	token, err := oauthConfig.Token(context.Background())
	if err != nil {
		return fmt.Errorf("failed to obtain OAuth token: %w", err)
	}
	logger.Info("OAuth token obtained", "token_type", token.TokenType)
	logger.Info("Successfully obtained OAuth token", "expires", token.Expiry)

	// Default labels for all metrics
	defaultLabels := prometheus.Labels{"tailnet": tailnet}
	reg := prometheus.WrapRegistererWith(
		defaultLabels,
		prometheus.DefaultRegisterer,
	)

	// Create collector with OAuth HTTP client
	tsCollector, err := collector.NewTailscaleCollector(
		logger,
		httpClient,
		tailnet,
	)
	if err != nil {
		return fmt.Errorf("failed to create Tailscale collector: %w", err)
	}

	reg.MustRegister(tsCollector)

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

// getTailnetFromEnv gets the tailnet from environment variables.
func getTailnetFromEnv() string {
	// Try different environment variable names
	tailnet := os.Getenv("TAILSCALE_TAILNET")
	if tailnet == "" {
		tailnet = os.Getenv("TS_TAILNET")
	}
	if tailnet == "" {
		tailnet = os.Getenv("TAILNET")
	}
	return tailnet
}

// getOAuthClientIDFromEnv gets the OAuth client ID from environment variables.
func getOAuthClientIDFromEnv() string {
	clientID := os.Getenv("TAILSCALE_OAUTH_CLIENT_ID")
	if clientID == "" {
		clientID = os.Getenv("TS_OAUTH_CLIENT_ID")
	}
	return strings.TrimSpace(clientID)
}

// getOAuthClientSecretFromEnv gets the OAuth client secret from environment variables.
func getOAuthClientSecretFromEnv() string {
	clientSecret := os.Getenv("TAILSCALE_OAUTH_CLIENT_SECRET")
	if clientSecret == "" {
		clientSecret = os.Getenv("TS_OAUTH_CLIENT_SECRET")
	}
	return strings.TrimSpace(clientSecret)
}
