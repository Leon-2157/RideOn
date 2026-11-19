package router

import (
	"context"
	"errors"
	"testing"
)

func TestFilterAndSortActive(t *testing.T) {
	input := []ProviderConfig{
		{ID: "p3", DisplayName: "Third", PriorityOrder: 3, IsActive: true, APIKey: "k3"},
		{ID: "p1", DisplayName: "First", PriorityOrder: 1, IsActive: true, APIKey: "k1"},
		{ID: "p2-inactive", DisplayName: "SecondInactive", PriorityOrder: 2, IsActive: false, APIKey: "k2"},
		{ID: "p0-nokey", DisplayName: "NoKey", PriorityOrder: 0, IsActive: true, APIKey: ""},
	}

	got := FilterAndSortActive(input)
	if len(got) != 2 {
		t.Fatalf("len(FilterAndSortActive) = %d, want 2", len(got))
	}
	if got[0].ID != "p1" || got[1].ID != "p3" {
		t.Fatalf("order = [%s, %s], want [p1, p3]", got[0].ID, got[1].ID)
	}
}

func TestRouteWithFailoverUsesBackupWhenPrimaryFails(t *testing.T) {
	providers := []ProviderConfig{
		{ID: "2", DisplayName: "Provider Cadangan", AdapterType: "gemini_native", PriorityOrder: 2, IsActive: true, APIKey: "key-2"},
		{ID: "1", DisplayName: "Provider Utama", AdapterType: "openai_compatible", PriorityOrder: 1, IsActive: true, APIKey: "key-1"},
	}

	var callOrder []string
	mockInvoker := func(ctx context.Context, p ProviderConfig, msg string) (string, error) {
		callOrder = append(callOrder, p.DisplayName)
		if p.PriorityOrder == 1 {
			return "", errors.New("upstream timeout")
		}
		return "Halo dari cadangan", nil
	}

	res, err := RouteWithFailover(context.Background(), providers, "Tes pesan", mockInvoker)
	if err != nil {
		t.Fatalf("RouteWithFailover returned unexpected error: %v", err)
	}
	if len(callOrder) != 2 || callOrder[0] != "Provider Utama" || callOrder[1] != "Provider Cadangan" {
		t.Fatalf("unexpected callOrder: %v", callOrder)
	}
	if res.ProviderUsed != "Provider Cadangan" || res.Reply != "Halo dari cadangan" {
		t.Fatalf("unexpected result: %+v", res)
	}
}

func TestRouteWithFailoverReturnsPoliteFallbackWhenNoneActive(t *testing.T) {
	providers := []ProviderConfig{
		{ID: "1", DisplayName: "Provider Utama", PriorityOrder: 1, IsActive: false, APIKey: ""},
	}

	res, err := RouteWithFailover(context.Background(), providers, "Halo", nil)
	if err != nil {
		t.Fatalf("expected nil error when no active providers, got %v", err)
	}
	if !res.Simulated || res.Reply != FallbackInactiveMessage {
		t.Fatalf("expected fallback message, got %+v", res)
	}
}

