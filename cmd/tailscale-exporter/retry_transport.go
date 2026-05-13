package main

import (
	"net/http"
	"time"

	"github.com/hashicorp/go-retryablehttp"
)

const (
	tailscaleAPIMaxRetries = 3
	tailscaleAPIBackoff    = 250 * time.Millisecond
	tailscaleAPIMaxBackoff = 2 * time.Second
)

func newRetryTransport(base http.RoundTripper) http.RoundTripper {
	if base == nil {
		base = http.DefaultTransport
	}

	retryClient := retryablehttp.NewClient()
	retryClient.HTTPClient = &http.Client{Transport: base}
	retryClient.Logger = nil
	retryClient.RetryMax = tailscaleAPIMaxRetries
	retryClient.RetryWaitMin = tailscaleAPIBackoff
	retryClient.RetryWaitMax = tailscaleAPIMaxBackoff
	retryClient.Backoff = retryablehttp.DefaultBackoff
	retryClient.CheckRetry = retryablehttp.DefaultRetryPolicy
	retryClient.ErrorHandler = retryablehttp.PassthroughErrorHandler

	return &retryablehttp.RoundTripper{Client: retryClient}
}
