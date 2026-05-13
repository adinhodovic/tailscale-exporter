package main

import (
	"io"
	"net/http"
	"strings"
	"testing"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func TestRetryTransportRetriesRateLimitThenSucceeds(t *testing.T) {
	requests := 0
	transport := newRetryTransport(roundTripFunc(func(req *http.Request) (*http.Response, error) {
		requests++
		if requests == 1 {
			return testResponse(http.StatusTooManyRequests, "rate limited"), nil
		}
		return testResponse(http.StatusOK, "ok"), nil
	}))

	resp, err := transport.RoundTrip(testRequest(t, http.MethodGet))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status code = %d, want %d", resp.StatusCode, http.StatusOK)
	}
	if requests != 2 {
		t.Fatalf("requests = %d, want 2", requests)
	}
}

func TestRetryTransportStopsAfterMaxRetries(t *testing.T) {
	requests := 0
	transport := newRetryTransport(roundTripFunc(func(req *http.Request) (*http.Response, error) {
		requests++
		return testResponse(http.StatusServiceUnavailable, "unavailable"), nil
	}))

	resp, err := transport.RoundTrip(testRequest(t, http.MethodGet))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("status code = %d, want %d", resp.StatusCode, http.StatusServiceUnavailable)
	}
	if requests != tailscaleAPIMaxRetries+1 {
		t.Fatalf("requests = %d, want %d", requests, tailscaleAPIMaxRetries+1)
	}
}

func testRequest(t *testing.T, method string) *http.Request {
	t.Helper()
	req, err := http.NewRequest(method, "https://api.tailscale.com/api/v2/test", nil)
	if err != nil {
		t.Fatal(err)
	}
	return req
}

func testResponse(statusCode int, body string) *http.Response {
	return &http.Response{
		StatusCode: statusCode,
		Header:     make(http.Header),
		Body:       io.NopCloser(strings.NewReader(body)),
	}
}
