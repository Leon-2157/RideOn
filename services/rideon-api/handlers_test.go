package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNormalizeOrderStatusTransition(t *testing.T) {
	cases := map[string]string{
		"driver_at_store":  "DRIVER_AT_PICKUP",
		"DRIVER_AT_STORE":  "DRIVER_AT_PICKUP",
		"driver_picked_up": "IN_TRANSIT",
		"DRIVER_PICKED_UP": "IN_TRANSIT",
		"delivered":        "DELIVERED",
	}
	for in, want := range cases {
		if got := normalizeOrderStatusTransition(in); got != want {
			t.Fatalf("normalizeOrderStatusTransition(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestIsWAEscalationMessage(t *testing.T) {
	if !isWAEscalationMessage("Halo admin, saya mau komplain pesanan saya gagal") {
		t.Fatal("expected komplain message to trigger escalation")
	}
	if isWAEscalationMessage("Jam berapa Mie Aceh Bukit Indah buka hari ini?") {
		t.Fatal("expected normal inquiry not to trigger escalation ticket")
	}
}

func TestRejectDriverOrderReturnsOKWithoutCancelling(t *testing.T) {
	s := &Server{}
	req := httptest.NewRequest(http.MethodPost, "/v1/orders/ord-123/driver-reject", nil)
	rec := httptest.NewRecorder()
	s.handleRejectDriverOrder(rec, req, "ord-123")
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
	}
}

