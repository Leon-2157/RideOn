package firebase

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	defaultTokenURL    = "https://oauth2.googleapis.com/token"
	firebaseScopes     = "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/identitytoolkit"
	identitySignUpBase = "https://identitytoolkit.googleapis.com/v1"
	fcmBaseURL         = "https://fcm.googleapis.com/v1"
)

type serviceAccount struct {
	ProjectID   string `json:"project_id"`
	PrivateKey  string `json:"private_key"`
	ClientEmail string `json:"client_email"`
	TokenURI    string `json:"token_uri"`
}

// Client provides lightweight stdlib REST access to Firebase RTDB, FCM v1, and Identity Toolkit.
// When service account credentials are absent, calls degrade gracefully to no-ops.
type Client struct {
	enabled     bool
	projectID   string
	databaseURL string
	clientEmail string
	privateKey  *rsa.PrivateKey
	tokenURL    string
	fcmBase     string
	authBase    string
	httpClient  *http.Client

	mu          sync.Mutex
	cachedToken string
	tokenExpiry time.Time
}

func NewClientFromEnv(projectID, databaseURL, serviceAccountPath string) *Client {
	c := &Client{
		projectID:   strings.TrimSpace(projectID),
		databaseURL: strings.TrimRight(strings.TrimSpace(databaseURL), "/"),
		tokenURL:    defaultTokenURL,
		fcmBase:     fcmBaseURL,
		authBase:    identitySignUpBase,
		httpClient:  &http.Client{Timeout: 4 * time.Second},
	}

	raw, err := os.ReadFile(strings.TrimSpace(serviceAccountPath))
	if err != nil || len(bytes.TrimSpace(raw)) == 0 {
		log.Printf("[FIREBASE] service account unavailable (%s): running in graceful fallback mode", serviceAccountPath)
		return c
	}

	var sa serviceAccount
	if err := json.Unmarshal(raw, &sa); err != nil {
		log.Printf("[FIREBASE] invalid service account JSON: %v", err)
		return c
	}
	block, _ := pem.Decode([]byte(sa.PrivateKey))
	if block == nil {
		log.Printf("[FIREBASE] invalid private_key PEM block")
		return c
	}
	parsedKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		if pkcs1, pErr := x509.ParsePKCS1PrivateKey(block.Bytes); pErr == nil {
			parsedKey = pkcs1
		} else {
			log.Printf("[FIREBASE] failed to parse private_key: %v", err)
			return c
		}
	}
	rsaKey, ok := parsedKey.(*rsa.PrivateKey)
	if !ok {
		log.Printf("[FIREBASE] private_key is not RSA")
		return c
	}

	if c.projectID == "" {
		c.projectID = sa.ProjectID
	}
	if sa.TokenURI != "" {
		c.tokenURL = sa.TokenURI
	}
	c.clientEmail = sa.ClientEmail
	c.privateKey = rsaKey
	c.enabled = c.clientEmail != "" && c.privateKey != nil
	log.Printf("[FIREBASE] initialized REST client (project=%s)", c.projectID)
	return c
}

func (c *Client) IsEnabled() bool {
	return c != nil && c.enabled
}

func (c *Client) accessToken(ctx context.Context) (string, error) {
	if !c.IsEnabled() {
		return "", errors.New("firebase disabled")
	}

	c.mu.Lock()
	if c.cachedToken != "" && time.Now().Add(60*time.Second).Before(c.tokenExpiry) {
		tok := c.cachedToken
		c.mu.Unlock()
		return tok, nil
	}
	c.mu.Unlock()

	now := time.Now().Unix()
	headerB64 := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"RS256","typ":"JWT"}`))
	claimJSON, _ := json.Marshal(map[string]any{
		"iss":   c.clientEmail,
		"scope": firebaseScopes,
		"aud":   c.tokenURL,
		"iat":   now,
		"exp":   now + 3600,
	})
	claimB64 := base64.RawURLEncoding.EncodeToString(claimJSON)
	signingInput := headerB64 + "." + claimB64
	sum := sha256.Sum256([]byte(signingInput))
	sig, err := rsa.SignPKCS1v15(rand.Reader, c.privateKey, crypto.SHA256, sum[:])
	if err != nil {
		return "", err
	}
	assertion := signingInput + "." + base64.RawURLEncoding.EncodeToString(sig)

	form := url.Values{
		"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"},
		"assertion":  {assertion},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.tokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<16))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("oauth token HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	var parsed struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int64  `json:"expires_in"`
	}
	if err := json.Unmarshal(body, &parsed); err != nil {
		return "", err
	}
	if parsed.AccessToken == "" {
		return "", errors.New("empty access_token")
	}

	ttl := time.Duration(parsed.ExpiresIn) * time.Second
	if ttl <= 0 {
		ttl = 55 * time.Minute
	}

	c.mu.Lock()
	c.cachedToken = parsed.AccessToken
	c.tokenExpiry = time.Now().Add(ttl)
	c.mu.Unlock()
	return parsed.AccessToken, nil
}

func (c *Client) rtdbRequest(ctx context.Context, method, path string, data any) error {
	if !c.IsEnabled() || c.databaseURL == "" {
		return nil
	}
	tok, err := c.accessToken(ctx)
	if err != nil {
		return err
	}
	cleanPath := strings.Trim(path, "/")
	endpoint := fmt.Sprintf("%s/%s.json?access_token=%s", c.databaseURL, cleanPath, url.QueryEscape(tok))

	var bodyReader io.Reader
	if data != nil {
		b, mErr := json.Marshal(data)
		if mErr != nil {
			return mErr
		}
		bodyReader = bytes.NewReader(b)
	}

	req, err := http.NewRequestWithContext(ctx, method, endpoint, bodyReader)
	if err != nil {
		return err
	}
	if data != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("rtdb %s %s HTTP %d", method, cleanPath, resp.StatusCode)
	}
	return nil
}

func (c *Client) SetRTDB(ctx context.Context, path string, data any) error {
	return c.rtdbRequest(ctx, http.MethodPut, path, data)
}

func (c *Client) PatchRTDB(ctx context.Context, path string, data any) error {
	return c.rtdbRequest(ctx, http.MethodPatch, path, data)
}

func (c *Client) DeleteRTDB(ctx context.Context, path string) error {
	return c.rtdbRequest(ctx, http.MethodDelete, path, nil)
}

func (c *Client) PingLiveOrder(ctx context.Context, orderID string, payload map[string]any) error {
	if orderID == "" {
		return nil
	}
	payload["updated_at"] = time.Now().Format(time.RFC3339)
	return c.PatchRTDB(ctx, "live_orders/"+orderID, payload)
}

func (c *Client) BroadcastOrderOffer(ctx context.Context, driverID, orderID string, payload map[string]any) error {
	if driverID == "" || orderID == "" {
		return nil
	}
	return c.SetRTDB(ctx, fmt.Sprintf("order_offers/%s/%s", driverID, orderID), payload)
}

func (c *Client) ClearOrderOffer(ctx context.Context, driverID, orderID string) error {
	if driverID == "" || orderID == "" {
		return nil
	}
	return c.DeleteRTDB(ctx, fmt.Sprintf("order_offers/%s/%s", driverID, orderID))
}

func (c *Client) SendFCM(ctx context.Context, deviceToken, title, body string, data map[string]string) error {
	if !c.IsEnabled() || strings.TrimSpace(deviceToken) == "" || c.projectID == "" {
		return nil
	}
	tok, err := c.accessToken(ctx)
	if err != nil {
		return err
	}
	msg := map[string]any{
		"message": map[string]any{
			"token": deviceToken,
			"notification": map[string]string{
				"title": title,
				"body":  body,
			},
			"data": data,
		},
	}
	b, _ := json.Marshal(msg)
	endpoint := fmt.Sprintf("%s/projects/%s/messages:send", c.fcmBase, url.PathEscape(c.projectID))
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("fcm HTTP %d", resp.StatusCode)
	}
	return nil
}

func (c *Client) SyncAuthUser(ctx context.Context, email, password, displayName string) error {
	if !c.IsEnabled() || strings.TrimSpace(email) == "" || strings.TrimSpace(password) == "" {
		return nil
	}
	tok, err := c.accessToken(ctx)
	if err != nil {
		return err
	}
	payload := map[string]any{
		"email":         strings.TrimSpace(email),
		"password":      password,
		"displayName":   strings.TrimSpace(displayName),
		"emailVerified": false,
	}
	b, _ := json.Marshal(payload)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.authBase+"/accounts", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("firebase auth sync HTTP %d", resp.StatusCode)
	}
	return nil
}

