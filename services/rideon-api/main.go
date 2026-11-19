package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"net/smtp"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"rideon-api/internal/auth"
	"rideon-api/internal/finance"
	"rideon-api/internal/firebase"
)

type Server struct {
	db                   *sql.DB
	jwtSecret            string
	jwtExpiresHours      int
	uploadsDir           string
	publicBaseURL        string
	waGatewayURL         string
	waGatewaySecret      string
	paygBaseURL          string
	paygWebhookSecret    string
	aiServiceURL         string
	osrmBaseURL          string
	resendAPIKey         string
	resendFromEmail      string
	gmailUser            string
	gmailAppPassword     string
	offerSeconds         int
	negativeBalanceLimit int64
	withdrawAdminFee     int64
	firebase             *firebase.Client
}

func main() {
	port := getEnv("PORT", "8080")
	dbHost := getEnv("DB_HOST", "127.0.0.1")
	dbPort := getEnv("DB_PORT", "3306")
	dbName := getEnv("DB_DATABASE", "rideon_db")
	dbUser := getEnv("DB_USERNAME", "rideon")
	dbPass := getEnv("DB_PASSWORD", "rideon_secret")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&loc=Asia%%2FJakarta&charset=utf8mb4",
		dbUser, dbPass, dbHost, dbPort, dbName)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("[RIDEON-API] failed to open mysql connection: %v", err)
	}
	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	uploadsDir := getEnv("UPLOADS_DIR", "/app/uploads")
	_ = os.MkdirAll(uploadsDir, 0755)

	jwtHours, _ := strconv.Atoi(getEnv("JWT_EXPIRES_HOURS", "168"))
	if jwtHours <= 0 {
		jwtHours = 168
	}
	offerSec, _ := strconv.Atoi(getEnv("DRIVER_OFFER_SECONDS", "16"))
	if offerSec <= 0 {
		offerSec = 16
	}
	negLimit, _ := strconv.ParseInt(getEnv("DRIVER_NEGATIVE_BALANCE_LIMIT", "20000"), 10, 64)
	if negLimit <= 0 {
		negLimit = 20000
	}
	withdrawFee, _ := strconv.ParseInt(getEnv("WITHDRAW_ADMIN_FEE", "2000"), 10, 64)
	if withdrawFee < 0 {
		withdrawFee = 2000
	}

	srv := &Server{
		db:                   db,
		jwtSecret:            getEnv("JWT_SECRET", "change-me-rideon-jwt-secret-key-min-32-chars"),
		jwtExpiresHours:      jwtHours,
		uploadsDir:           uploadsDir,
		publicBaseURL:        getEnv("PUBLIC_BASE_URL", "http://localhost:8088"),
		waGatewayURL:         strings.TrimRight(getEnv("WA_GATEWAY_URL", "http://wa-gateway:3100"), "/"),
		waGatewaySecret:      getEnv("WHATSAPP_GATEWAY_SECRET", "rideon-wa-internal-secret"),
		paygBaseURL:          strings.TrimRight(getEnv("PAYG_BASE_URL", "http://payg:8082"), "/"),
		paygWebhookSecret:    getEnv("PAYG_WEBHOOK_SECRET", "rideon-payg-internal-secret"),
		aiServiceURL:         strings.TrimRight(getEnv("AI_SERVICE_URL", "http://ai-service:8083"), "/"),
		osrmBaseURL:          strings.TrimRight(getEnv("OSRM_BASE_URL", "https://router.project-osrm.org"), "/"),
		resendAPIKey:         strings.TrimSpace(os.Getenv("RESEND_API_KEY")),
		resendFromEmail:      getEnv("RESEND_FROM_EMAIL", "noreply@rideons.app"),
		gmailUser:            strings.TrimSpace(os.Getenv("GMAIL_USER")),
		gmailAppPassword:     strings.TrimSpace(os.Getenv("GMAIL_APP_PASSWORD")),
		offerSeconds:         offerSec,
		negativeBalanceLimit: negLimit,
		withdrawAdminFee:     withdrawFee,
		firebase: firebase.NewClientFromEnv(
			getEnv("FIREBASE_PROJECT_ID", "rideon-9eb77"),
			getEnv("FIREBASE_DATABASE_URL", "https://rideon-9eb77-default-rtdb.asia-southeast1.firebasedatabase.app"),
			getEnv("FIREBASE_SERVICE_ACCOUNT_PATH", "/app/secrets/firebase-service-account.json"),
		),
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/v1/health", srv.handleHealth)
	mux.HandleFunc("/health", srv.handleHealth)
	mux.HandleFunc("/v1/upload", srv.handleUpload)
	mux.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir(uploadsDir))))
	mux.HandleFunc("/v1/internal/qris-paid", srv.handleInternalQRISPaid)

	// Auth & OTP
	mux.HandleFunc("/v1/auth/login", srv.handleLogin)
	mux.HandleFunc("/v1/auth/google", srv.handleGoogleLogin)
	mux.HandleFunc("/v1/auth/otp/send", srv.handleOTPSend)
	mux.HandleFunc("/v1/auth/otp/verify", srv.handleOTPVerify)
	mux.HandleFunc("/v1/auth/register", srv.handleRegister)
	mux.HandleFunc("/v1/auth/me", srv.handleAuthMe)

	// Catalog, Promotions, Favorites
	mux.HandleFunc("/v1/stores", srv.handleStores)
	mux.HandleFunc("/v1/stores/", srv.handleStoreSubtree)
	mux.HandleFunc("/v1/menus", srv.handlePublicMenus)
	mux.HandleFunc("/v1/promotions", srv.handlePromotions)
	mux.HandleFunc("/v1/promotions/", srv.handlePromotionByID)
	mux.HandleFunc("/v1/favorites", srv.handleFavorites)
	mux.HandleFunc("/v1/favorites/", srv.handleFavoriteByID)

	// Orders & Drivers
	mux.HandleFunc("/v1/drivers/", srv.handleDriverSubtree)
	mux.HandleFunc("/v1/orders/estimate", srv.handleOrderEstimate)
	mux.HandleFunc("/v1/orders", srv.handleOrders)
	mux.HandleFunc("/v1/orders/", srv.handleOrderSubtree)

	// Wallets, Withdrawals, Talangan Claims, Support Tickets, Webhooks
	mux.HandleFunc("/v1/wallets/", srv.handleWalletsSubtree)
	mux.HandleFunc("/v1/withdrawals", srv.handleWithdrawals)
	mux.HandleFunc("/v1/talangan-claims", srv.handleTalanganClaims)
	mux.HandleFunc("/v1/talangan-claims/", srv.handleTalanganClaimSubtree)
	mux.HandleFunc("/v1/support-tickets", srv.handleSupportTickets)
	mux.HandleFunc("/v1/webhooks/wa", srv.handleWAWebhook)

	// Admin
	mux.HandleFunc("/v1/admin/overview", srv.requireAdmin(srv.handleAdminOverview))
	mux.HandleFunc("/v1/admin/map", srv.requireAdmin(srv.handleAdminMap))
	mux.HandleFunc("/v1/admin/registrations", srv.requireAdmin(srv.handleAdminRegistrations))
	mux.HandleFunc("/v1/admin/registrations/", srv.requireAdmin(srv.handleAdminRegistrationAction))
	mux.HandleFunc("/v1/admin/orders", srv.requireAdmin(srv.handleAdminOrders))
	mux.HandleFunc("/v1/admin/drivers", srv.requireAdmin(srv.handleAdminDrivers))
	mux.HandleFunc("/v1/admin/drivers/", srv.requireAdmin(srv.handleAdminDriverAction))
	mux.HandleFunc("/v1/admin/stores", srv.requireAdmin(srv.handleAdminStores))
	mux.HandleFunc("/v1/admin/stores/", srv.requireAdmin(srv.handleAdminStoreAction))
	mux.HandleFunc("/v1/admin/customers", srv.requireAdmin(srv.handleAdminCustomers))
	mux.HandleFunc("/v1/admin/finance", srv.requireAdmin(srv.handleAdminFinance))
	mux.HandleFunc("/v1/admin/withdrawals/", srv.requireAdmin(srv.handleAdminWithdrawalAction))
	mux.HandleFunc("/v1/admin/talangan-claims/", srv.requireAdmin(srv.handleAdminTalanganAction))
	mux.HandleFunc("/v1/admin/settings", srv.requireAdmin(srv.handleAdminSettings))
	mux.HandleFunc("/v1/admin/pricing-rules", srv.requireAdmin(srv.handleAdminPricingRules))
	mux.HandleFunc("/v1/admin/pricing-rules/", srv.requireAdmin(srv.handleAdminPricingRuleByID))
	mux.HandleFunc("/v1/admin/support-tickets/", srv.requireAdmin(srv.handleAdminSupportTicketReply))

	log.Printf("[RIDEON-API] listening on 0.0.0.0:%s", port)
	if err := http.ListenAndServe("0.0.0.0:"+port, corsMiddleware(mux)); err != nil {
		log.Fatalf("[RIDEON-API] server stopped: %v", err)
	}
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Gateway-Secret")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	dbStatus := "connected"
	if err := s.db.PingContext(r.Context()); err != nil {
		dbStatus = "error: " + err.Error()
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"status":   "ok",
		"service":  "rideon-api",
		"database": dbStatus,
	})
}

func (s *Server) handleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	if err := r.ParseMultipartForm(15 << 20); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Failed to parse multipart form: " + err.Error()})
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "file field is required"})
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext == "" {
		ext = ".bin"
	}
	category := sanitizeSegment(r.FormValue("category"))
	if category == "" {
		category = "general"
	}
	targetDir := filepath.Join(s.uploadsDir, category)
	_ = os.MkdirAll(targetDir, 0755)

	filename := fmt.Sprintf("%d-%s%s", time.Now().Unix(), newUUIDv4()[:8], ext)
	destPath := filepath.Join(targetDir, filename)

	out, err := os.Create(destPath)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to create destination file"})
		return
	}
	defer out.Close()

	size, err := io.Copy(out, file)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to write uploaded file"})
		return
	}

	relURL := fmt.Sprintf("/uploads/%s/%s", category, filename)
	writeJSON(w, http.StatusCreated, map[string]any{
		"url":       relURL,
		"full_url":  strings.TrimRight(s.publicBaseURL, "/") + relURL,
		"filename":  filename,
		"category":  category,
		"size_byte": size,
	})
}

func sanitizeSegment(in string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(strings.TrimSpace(in)) {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' || r == '_' {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func (s *Server) extractClaims(r *http.Request) (*auth.Claims, error) {
	header := strings.TrimSpace(r.Header.Get("Authorization"))
	if !strings.HasPrefix(strings.ToLower(header), "bearer ") {
		return nil, errors.New("missing bearer token")
	}
	token := strings.TrimSpace(header[7:])
	return auth.VerifyJWT(token, s.jwtSecret)
}

func (s *Server) requireAdmin(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		claims, err := s.extractClaims(r)
		if err != nil {
			writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "Unauthorized: " + err.Error()})
			return
		}
		if !strings.EqualFold(claims.Role, "ADMIN") {
			writeJSON(w, http.StatusForbidden, map[string]any{"error": "Forbidden: membutuhkan akses ADMIN"})
			return
		}
		next(w, r)
	}
}

func normalizePhone(raw string) string {
	var digits strings.Builder
	for _, c := range raw {
		if c >= '0' && c <= '9' {
			digits.WriteRune(c)
		}
	}
	p := digits.String()
	if strings.HasPrefix(p, "0") {
		return "62" + p[1:]
	}
	return p
}

func (s *Server) getIntSetting(ctx context.Context, key string, fallback int) int {
	var v string
	if err := s.db.QueryRowContext(ctx, "SELECT value FROM system_settings WHERE `key` = ? LIMIT 1", key).Scan(&v); err == nil {
		if n, pErr := strconv.Atoi(strings.TrimSpace(v)); pErr == nil && n > 0 {
			return n
		}
	}
	return fallback
}

func (s *Server) getInt64Setting(ctx context.Context, key string, fallback int64) int64 {
	var v string
	if err := s.db.QueryRowContext(ctx, "SELECT value FROM system_settings WHERE `key` = ? LIMIT 1", key).Scan(&v); err == nil {
		if n, pErr := strconv.ParseInt(strings.TrimSpace(v), 10, 64); pErr == nil && n >= 0 {
			return n
		}
	}
	return fallback
}

func (s *Server) sendEmailMessage(toEmail, subject, htmlBody string) (string, error) {
	if s.resendAPIKey != "" {
		payload := map[string]any{
			"from":    fmt.Sprintf("RideOn Indonesia <%s>", s.resendFromEmail),
			"to":      []string{toEmail},
			"subject": subject,
			"html":    htmlBody,
		}
		b, _ := json.Marshal(payload)
		req, err := http.NewRequest(http.MethodPost, "https://api.resend.com/emails", bytes.NewReader(b))
		if err == nil {
			req.Header.Set("Authorization", "Bearer "+s.resendAPIKey)
			req.Header.Set("Content-Type", "application/json")
			client := &http.Client{Timeout: 8 * time.Second}
			resp, rErr := client.Do(req)
			if rErr == nil {
				defer resp.Body.Close()
				if resp.StatusCode >= 200 && resp.StatusCode < 300 {
					return "resend", nil
				}
			}
		}
	}
	if s.gmailUser != "" && s.gmailAppPassword != "" {
		authSMTP := smtp.PlainAuth("", s.gmailUser, s.gmailAppPassword, "smtp.gmail.com")
		msg := []byte(fmt.Sprintf("To: %s\r\nFrom: Tim Bantuan RideOn <%s>\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n%s\r\n",
			toEmail, s.gmailUser, subject, htmlBody))
		if err := smtp.SendMail("smtp.gmail.com:587", authSMTP, s.gmailUser, []string{toEmail}, msg); err == nil {
			return "gmail_smtp", nil
		}
	}
	return "simulated_local", nil
}

func (s *Server) notifyUserAsync(userID, title, body, emailSubject, emailHTML string) {
	if strings.TrimSpace(userID) == "" {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		var email, fcmToken sql.NullString
		_ = s.db.QueryRowContext(ctx, `SELECT email, fcm_token FROM users WHERE id = ? LIMIT 1`, userID).Scan(&email, &fcmToken)
		if s.firebase != nil && fcmToken.Valid && strings.TrimSpace(fcmToken.String) != "" {
			_ = s.firebase.SendFCM(ctx, fcmToken.String, title, body, map[string]string{"title": title, "body": body})
		}
		if email.Valid && strings.TrimSpace(email.String) != "" && emailSubject != "" {
			_, _ = s.sendEmailMessage(strings.TrimSpace(email.String), emailSubject, emailHTML)
		}
	}()
}

func (s *Server) estimateOSRMDistance(ctx context.Context, lat1, lng1, lat2, lng2 float64) (float64, int) {
	url := fmt.Sprintf("%s/route/v1/driving/%.6f,%.6f;%.6f,%.6f?overview=false",
		s.osrmBaseURL, lng1, lat1, lng2, lat2)
	client := &http.Client{Timeout: 3 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err == nil {
		resp, dErr := client.Do(req)
		if dErr == nil {
			defer resp.Body.Close()
			if resp.StatusCode == http.StatusOK {
				var parsed struct {
					Routes []struct {
						Distance float64 `json:"distance"`
						Duration float64 `json:"duration"`
					} `json:"routes"`
				}
				if json.NewDecoder(resp.Body).Decode(&parsed) == nil && len(parsed.Routes) > 0 && parsed.Routes[0].Distance > 0 {
					km := math.Round((parsed.Routes[0].Distance/1000.0)*100) / 100
					if km < 0.5 {
						km = 0.5
					}
					min := int(math.Ceil(parsed.Routes[0].Duration / 60.0))
					if min < 3 {
						min = 3
					}
					return km, min
				}
			}
		}
	}
	km := finance.HaversineRoadKm(lat1, lng1, lat2, lng2)
	min := int(math.Ceil(km * 2.5))
	if min < 4 {
		min = 4
	}
	return km, min
}

func newUUIDv4() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%s-%s-%s-%s-%s",
		hex.EncodeToString(b[0:4]),
		hex.EncodeToString(b[4:6]),
		hex.EncodeToString(b[6:8]),
		hex.EncodeToString(b[8:10]),
		hex.EncodeToString(b[10:16]),
	)
}

func getEnv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

