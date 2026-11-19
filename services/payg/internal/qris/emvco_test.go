package qris

import (
	"strings"
	"testing"
)

func TestComputeCRC16StandardVector(t *testing.T) {
	// Standard EMVCo / CCITT-FALSE check vector: "123456789" -> 0x29B1.
	got := ComputeCRC16("123456789")
	if got != "29B1" {
		t.Fatalf("ComputeCRC16(\"123456789\") = %s, want 29B1", got)
	}
}

func TestGenerateDynamicQRIS(t *testing.T) {
	dynamic, err := GenerateDynamicQRIS("", 25137)
	if err != nil {
		t.Fatalf("GenerateDynamicQRIS returned error: %v", err)
	}

	if !ValidateCRC(dynamic) {
		t.Fatalf("generated QRIS failed CRC validation: %s", dynamic)
	}

	if !strings.Contains(dynamic, "010212") {
		t.Errorf("expected Tag 01 dynamic indicator 010212 in %s", dynamic)
	}

	if !strings.Contains(dynamic, "540525137") {
		t.Errorf("expected Tag 54 amount 540525137 in %s", dynamic)
	}

	fields, err := ParseEMVCo(dynamic)
	if err != nil {
		t.Fatalf("ParseEMVCo failed on generated dynamic QRIS: %v", err)
	}

	found01 := false
	found54 := false
	for _, f := range fields {
		if f.Tag == "01" && f.Value == "12" {
			found01 = true
		}
		if f.Tag == "54" && f.Value == "25137" {
			found54 = true
		}
	}
	if !found01 || !found54 {
		t.Fatalf("missing required tags in parsed fields: found01=%v found54=%v", found01, found54)
	}
}

func TestGenerateDynamicQRISRejectsInvalidAmount(t *testing.T) {
	if _, err := GenerateDynamicQRIS("", 0); err == nil {
		t.Fatal("expected error for zero amount, got nil")
	}
	if _, err := GenerateDynamicQRIS("", -5000); err == nil {
		t.Fatal("expected error for negative amount, got nil")
	}
}

