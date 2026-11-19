package finance

import "testing"

func TestCalculateCommission5Pct5Pct(t *testing.T) {
	split := CalculateCommission5Pct5Pct(10000, 40000, 5.0, 5.0)
	if split.DriverCommission != 500 || split.DriverNetEarning != 9500 {
		t.Fatalf("driver split = (%d, %d), want (500, 9500)", split.DriverCommission, split.DriverNetEarning)
	}
	if split.StoreCommission != 2000 || split.StoreNetEarning != 38000 {
		t.Fatalf("store split = (%d, %d), want (2000, 38000)", split.StoreCommission, split.StoreNetEarning)
	}
	if split.PlatformTotalShare != 2500 {
		t.Fatalf("PlatformTotalShare = %d, want 2500", split.PlatformTotalShare)
	}
}

func TestCheckDriverCashEligibility(t *testing.T) {
	if err := CheckDriverCashEligibility(0, 20000); err != nil {
		t.Fatalf("expected balance 0 to be eligible, got: %v", err)
	}
	if err := CheckDriverCashEligibility(-19500, 20000); err != nil {
		t.Fatalf("expected balance -19500 to be eligible, got: %v", err)
	}
	if err := CheckDriverCashEligibility(-20000, 20000); err == nil {
		t.Fatal("expected balance -20000 to be blocked for cash orders")
	}
	if err := CheckDriverCashEligibility(-25000, 20000); err == nil {
		t.Fatal("expected balance -25000 to be blocked for cash orders")
	}
}

func TestComputeFare(t *testing.T) {
	// 1.5 km within 2 km base -> minFare 8000
	if got := ComputeFare(1.5, 5000, 2200, 8000, 0); got != 8000 {
		t.Fatalf("ComputeFare(1.5 km) = %d, want 8000", got)
	}
	// 4.2 km -> base 5000 + ceil(2.2)*2200 = 5000 + 6600 = 11600
	if got := ComputeFare(4.2, 5000, 2200, 8000, 0); got != 11600 {
		t.Fatalf("ComputeFare(4.2 km) = %d, want 11600", got)
	}
}

