package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

type Claims struct {
	UserID string `json:"user_id"`
	Role   string `json:"role"`
	Status string `json:"status"`
	Email  string `json:"email"`
	Name   string `json:"name"`
	Iat    int64  `json:"iat"`
	Exp    int64  `json:"exp"`
}

func HashPassword(plain string) (string, error) {
	if strings.TrimSpace(plain) == "" {
		return "", errors.New("password cannot be empty")
	}
	bytes, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func CheckPassword(hash, plain string) bool {
	if hash == "" || plain == "" {
		return false
	}
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(plain)) == nil
}

func GenerateJWT(secret string, expiresHours int, userID, role, status, email, name string) (string, error) {
	if secret == "" {
		return "", errors.New("jwt secret cannot be empty")
	}
	if expiresHours <= 0 {
		expiresHours = 168
	}
	now := time.Now().Unix()
	headerJSON := `{"alg":"HS256","typ":"JWT"}`
	claims := Claims{
		UserID: userID,
		Role:   role,
		Status: status,
		Email:  email,
		Name:   name,
		Iat:    now,
		Exp:    now + int64(expiresHours*3600),
	}
	claimsBytes, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	hEnc := base64.RawURLEncoding.EncodeToString([]byte(headerJSON))
	pEnc := base64.RawURLEncoding.EncodeToString(claimsBytes)
	signingInput := hEnc + "." + pEnc

	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(signingInput))
	sig := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
	return signingInput + "." + sig, nil
}

func VerifyJWT(tokenStr, secret string) (*Claims, error) {
	parts := strings.Split(strings.TrimSpace(tokenStr), ".")
	if len(parts) != 3 || secret == "" {
		return nil, errors.New("invalid token format")
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(parts[0] + "." + parts[1]))
	expectedSig := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
	if !hmac.Equal([]byte(expectedSig), []byte(parts[2])) {
		return nil, errors.New("invalid token signature")
	}
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, err
	}
	var claims Claims
	if err := json.Unmarshal(payloadBytes, &claims); err != nil {
		return nil, err
	}
	if claims.Exp > 0 && time.Now().Unix() > claims.Exp {
		return nil, errors.New("token expired")
	}
	return &claims, nil
}

