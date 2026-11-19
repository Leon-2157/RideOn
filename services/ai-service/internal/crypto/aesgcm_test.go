package crypto

import "testing"

func TestEncryptDecryptAPIKeyRoundTrip(t *testing.T) {
	key, err := NormalizeKey("0123456789abcdef0123456789abcdef")
	if err != nil {
		t.Fatalf("NormalizeKey failed: %v", err)
	}

	secret := "sk-live-rideon-secret-token-1234567890"
	encrypted, err := EncryptAPIKey(secret, key)
	if err != nil {
		t.Fatalf("EncryptAPIKey failed: %v", err)
	}
	if encrypted == "" || encrypted == secret {
		t.Fatalf("expected non-empty encrypted output different from plaintext, got %q", encrypted)
	}

	decrypted, err := DecryptAPIKey(encrypted, key)
	if err != nil {
		t.Fatalf("DecryptAPIKey failed: %v", err)
	}
	if decrypted != secret {
		t.Fatalf("DecryptAPIKey = %q, want %q", decrypted, secret)
	}
}

func TestDecryptWithWrongKeyFails(t *testing.T) {
	key1, _ := NormalizeKey("0123456789abcdef0123456789abcdef")
	key2, _ := NormalizeKey("fedcba9876543210fedcba9876543210")

	encrypted, err := EncryptAPIKey("top-secret-key", key1)
	if err != nil {
		t.Fatalf("EncryptAPIKey failed: %v", err)
	}
	if _, err := DecryptAPIKey(encrypted, key2); err == nil {
		t.Fatal("expected DecryptAPIKey to fail with wrong key, got nil")
	}
}

func TestNormalizeKeyRejectsInvalidLength(t *testing.T) {
	if _, err := NormalizeKey("short-key"); err == nil {
		t.Fatal("expected error for non-32-byte key")
	}
	hexKey := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	decoded, err := NormalizeKey(hexKey)
	if err != nil || len(decoded) != 32 {
		t.Fatalf("expected 64-char hex key to decode to 32 bytes, err=%v len=%d", err, len(decoded))
	}
}

