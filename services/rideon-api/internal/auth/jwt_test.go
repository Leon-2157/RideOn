package auth

import "testing"

func TestJWTGenerateAndVerify(t *testing.T) {
	secret := "change-me-rideon-jwt-secret-key-min-32-chars"
	tok, err := GenerateJWT(secret, 24, "00000000-0000-4000-8000-000000000001", "ADMIN", "ACTIVE", "admin@rideons.app", "Super Admin RideOn Lhokseumawe")
	if err != nil {
		t.Fatalf("GenerateJWT failed: %v", err)
	}

	claims, err := VerifyJWT(tok, secret)
	if err != nil {
		t.Fatalf("VerifyJWT failed: %v", err)
	}
	if claims.UserID != "00000000-0000-4000-8000-000000000001" || claims.Role != "ADMIN" {
		t.Fatalf("unexpected claims: %+v", claims)
	}

	if _, err := VerifyJWT(tok, "wrong-secret"); err == nil {
		t.Fatal("expected VerifyJWT with wrong secret to fail")
	}
}

func TestCheckPasswordMatchesSeederHashes(t *testing.T) {
	if !CheckPassword("$2a$10$qnJjbPYAegfYJ9fCFFsdOOCAu0TH3gPoSpawhQVnd6glJnRJyOS.C", "RideOnAdmin2026!") {
		t.Fatal("expected admin seeder hash to match RideOnAdmin2026!")
	}
	if !CheckPassword("$2a$10$1/.S653HA4u2t7Way9X7LuKyBQF6roqnSEB6rCPo4cYLLreY1XhN2", "RideOnDemo2026!") {
		t.Fatal("expected demo seeder hash to match RideOnDemo2026!")
	}
	if !CheckPassword("$2a$10$00ni90beHZP24B50xekufuu3riVgl8SlIJ97mFQk09mS9fQRlRNO2", "123456") {
		t.Fatal("expected store pin seeder hash to match 123456")
	}
}

