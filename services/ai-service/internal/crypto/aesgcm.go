package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"io"
	"strings"
)

// NormalizeKey accepts either a 32-byte raw ASCII string or a 64-character hex string
// that decodes to 32 bytes for AES-256-GCM.
func NormalizeKey(raw string) ([]byte, error) {
	trimmed := strings.TrimSpace(raw)
	if len(trimmed) == 32 {
		return []byte(trimmed), nil
	}
	if len(trimmed) == 64 {
		decoded, err := hex.DecodeString(trimmed)
		if err == nil && len(decoded) == 32 {
			return decoded, nil
		}
	}
	return nil, errors.New("encryption key must be 32 raw bytes or 64 hex characters for AES-256-GCM")
}

// EncryptAPIKey encrypts a plaintext API key using AES-256-GCM and encodes
// nonce + ciphertext as standard base64. Empty plaintext returns an empty string.
func EncryptAPIKey(plaintext string, key []byte) (string, error) {
	if strings.TrimSpace(plaintext) == "" {
		return "", nil
	}
	if len(key) != 32 {
		return "", errors.New("encryption key must be 32 bytes")
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	sealed := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(sealed), nil
}

// DecryptAPIKey decrypts a base64-encoded AES-256-GCM payload back to plaintext.
func DecryptAPIKey(encoded string, key []byte) (string, error) {
	if strings.TrimSpace(encoded) == "" {
		return "", nil
	}
	if len(key) != 32 {
		return "", errors.New("encryption key must be 32 bytes")
	}

	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(encoded))
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonceSize := gcm.NonceSize()
	if len(raw) < nonceSize {
		return "", errors.New("ciphertext too short")
	}

	nonce, ciphertext := raw[:nonceSize], raw[nonceSize:]
	plain, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", err
	}
	return string(plain), nil
}

// MaskAPIKey returns a masked representation safe for UI display.
func MaskAPIKey(decrypted string, hasEncrypted bool) string {
	if decrypted == "" && !hasEncrypted {
		return ""
	}
	if len(decrypted) <= 8 {
		return "****"
	}
	return decrypted[:4] + "****" + decrypted[len(decrypted)-4:]
}

