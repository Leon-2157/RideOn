package firebase

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
)

func TestDisabledClientIsGracefulNoOp(t *testing.T) {
	c := NewClientFromEnv("rideon-9eb77", "https://rideon-9eb77-default-rtdb.asia-southeast1.firebasedatabase.app", "/nonexistent/sa.json")
	if c.IsEnabled() {
		t.Fatal("expected disabled client when service account file is missing")
	}
	ctx := context.Background()
	if err := c.PingLiveOrder(ctx, "ord-1", map[string]any{"status": "CREATED"}); err != nil {
		t.Fatalf("expected nil error on disabled PingLiveOrder, got %v", err)
	}
	if err := c.BroadcastOrderOffer(ctx, "drv-1", "ord-1", map[string]any{"id": "ord-1"}); err != nil {
		t.Fatalf("expected nil error on disabled BroadcastOrderOffer, got %v", err)
	}
	if err := c.ClearOrderOffer(ctx, "drv-1", "ord-1"); err != nil {
		t.Fatalf("expected nil error on disabled ClearOrderOffer, got %v", err)
	}
	if err := c.SendFCM(ctx, "tok-123", "Title", "Body", nil); err != nil {
		t.Fatalf("expected nil error on disabled SendFCM, got %v", err)
	}
	if err := c.SyncAuthUser(ctx, "a@b.com", "secret123", "Ali"); err != nil {
		t.Fatalf("expected nil error on disabled SyncAuthUser, got %v", err)
	}
}

func TestEnabledClientDispatchesOAuthRTDBAndFCM(t *testing.T) {
	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("rsa generate: %v", err)
	}

	var tokenCalls, rtdbCalls, fcmCalls int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.URL.Path == "/token":
			atomic.AddInt32(&tokenCalls, 1)
			_ = json.NewEncoder(w).Encode(map[string]any{"access_token": "mock-access-tok", "expires_in": 3600})
		case r.URL.Path == "/live_orders/ord-99.json":
			atomic.AddInt32(&rtdbCalls, 1)
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"status":"SEARCHING_DRIVER"}`))
		case r.URL.Path == "/projects/rideon-9eb77/messages:send":
			atomic.AddInt32(&fcmCalls, 1)
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"name":"projects/rideon-9eb77/messages/1"}`))
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer srv.Close()

	c := &Client{
		enabled:     true,
		projectID:   "rideon-9eb77",
		databaseURL: srv.URL,
		clientEmail: "firebase-adminsdk@rideon-9eb77.iam.gserviceaccount.com",
		privateKey:  priv,
		tokenURL:    srv.URL + "/token",
		fcmBase:     srv.URL,
		httpClient:  srv.Client(),
	}

	ctx := context.Background()
	if err := c.PingLiveOrder(ctx, "ord-99", map[string]any{"status": "SEARCHING_DRIVER"}); err != nil {
		t.Fatalf("PingLiveOrder failed: %v", err)
	}
	if err := c.SendFCM(ctx, "dev-tok", "Order Baru", "Silakan konfirmasi", map[string]string{"order_id": "ord-99"}); err != nil {
		t.Fatalf("SendFCM failed: %v", err)
	}

	if atomic.LoadInt32(&tokenCalls) != 1 {
		t.Fatalf("expected OAuth token to be cached (1 call), got %d", tokenCalls)
	}
	if atomic.LoadInt32(&rtdbCalls) != 1 || atomic.LoadInt32(&fcmCalls) != 1 {
		t.Fatalf("expected 1 RTDB and 1 FCM call, got rtdb=%d fcm=%d", rtdbCalls, fcmCalls)
	}
}

