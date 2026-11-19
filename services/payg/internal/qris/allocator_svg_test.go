package qris

import (
	"strings"
	"testing"
)

func TestPickNonCollidingCode(t *testing.T) {
	active := map[int64]bool{
		50001: true,
		50002: true,
		50003: true,
	}
	code, payable, err := pickNonCollidingCode(50000, active, 0)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if code != 4 || payable != 50004 {
		t.Fatalf("expected code=4 payable=50004, got code=%d payable=%d", code, payable)
	}

	// Exhaust all 999 slots
	full := map[int64]bool{}
	for c := 1; c <= 999; c++ {
		full[50000+int64(c)] = true
	}
	if _, _, err := pickNonCollidingCode(50000, full, 0); err == nil {
		t.Fatal("expected error when all 999 slots are occupied")
	}
}

func TestRenderSVGProducesValidSVG(t *testing.T) {
	payload, err := GenerateDynamicQRIS("", 50123)
	if err != nil {
		t.Fatalf("GenerateDynamicQRIS error: %v", err)
	}
	svg, err := RenderSVG(payload)
	if err != nil {
		t.Fatalf("RenderSVG error: %v", err)
	}
	if !strings.HasPrefix(svg, `<svg xmlns="http://www.w3.org/2000/svg"`) || !strings.HasSuffix(svg, `</svg>`) {
		t.Fatalf("unexpected SVG wrapper: %s", svg[:min(len(svg), 120)])
	}
	if !strings.Contains(svg, `<path fill="#111111" d="M`) {
		t.Fatalf("expected path modules in SVG")
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

