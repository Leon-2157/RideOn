package main

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"rideon-payg/internal/qris"
)

type Server struct {
	db                *sql.DB
	webhookSecret     string
	jwtSecret         string
	staticQRIS        string
	expireMinutes     int
	rideonInternalURL string
}

func main() {
	port := getEnv("PORT", "8082")
	dbHost := getEnv("DB_HOST", "127.0.0.1")
	dbPort := getEnv("DB_PORT", "3306")
	dbName := getEnv("DB_DATABASE", "rideon_db")
	dbUser := getEnv("DB_USERNAME", "rideon")
	dbPass := getEnv("DB_PASSWORD", "rideon_secret")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&loc=Asia%%2FJakarta&charset=utf8mb4",
		dbUser, dbPass, dbHost, dbPort, dbName)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("[PAYG] failed to open mysql connection: %v", err)
	}
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	expireMin, err := strconv.Atoi(getEnv("QRIS_EXPIRE_MINUTES", "15"))
	if err != nil || expireMin <= 0 {
		expireMin = 15
	}

	srv := &Server{
		db:                db,
		webhookSecret:     getEnv("PAYG_WEBHOOK_SECRET", "rideon-payg-internal-secret"),
		jwtSecret:         getEnv("JWT_SECRET", "change-me-rideon-jwt-secret-key-min-32-chars"),
		staticQRIS:        strings.TrimSpace(os.Getenv("PAYG_STATIC_QRIS")),
		expireMinutes:     expireMin,
		rideonInternalURL: strings.TrimRight(getEnv("RIDEON_API_INTERNAL_URL", "http://rideon-api:8080"), "/"),
	}
	ensureQRISSchema(db)

	mux := http.NewServeMux()
	mux.HandleFunc("/pay/health", srv.handleHealth)
	mux.HandleFunc("/health", srv.handleHealth)
	mux.HandleFunc("/pay/qris/generate", srv.handleGenerateQRIS)
	mux.HandleFunc("/pay/checkout/create", srv.handleGenerateQRIS)
	mux.HandleFunc("/pay/qris/webhook", srv.handleWebhook)
	mux.HandleFunc("/pay/webhook/macrodroid", srv.handleWebhook)
	mux.HandleFunc("/pay/qris/", srv.handleQRISStatusSubtree)

	log.Printf("[PAYG] listening on 0.0.0.0:%s", port)
	if err := http.ListenAndServe("0.0.0.0:"+port, corsMiddleware(mux)); err != nil {
		log.Fatalf("[PAYG] server stopped: %v", err)
	}
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-PayG-Secret, X-Webhook-Secret")
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
		"service":  "rideon-payg",
		"database": dbStatus,
	})
}

type generateRequest struct {
	Purpose     string  `json:"purpose"`
	OrderID     *string `json:"order_id"`
	UserID      string  `json:"user_id"`
	BaseAmount  int64   `json:"base_amount"`
	Amount      int64   `json:"amount"`
	ReferenceID string  `json:"reference_id"`
}

func (s *Server) handleGenerateQRIS(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	var req generateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	purpose := strings.ToUpper(strings.TrimSpace(req.Purpose))
	if purpose == "" {
		if req.OrderID != nil && *req.OrderID != "" {
			purpose = "ORDER_PAYMENT"
		} else {
			purpose = "DRIVER_TOPUP"
		}
	}
	if purpose != "ORDER_PAYMENT" && purpose != "DRIVER_TOPUP" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "purpose must be ORDER_PAYMENT or DRIVER_TOPUP"})
		return
	}
	if strings.TrimSpace(req.UserID) == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "user_id is required"})
		return
	}
	baseAmount := req.BaseAmount
	if baseAmount <= 0 {
		baseAmount = req.Amount
	}
	if baseAmount <= 0 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "base_amount or amount must be greater than zero"})
		return
	}

	uniqueCode, payableAmount, err := qris.AllocateUniqueCode(r.Context(), s.db, baseAmount)
	if err != nil {
		writeJSON(w, http.StatusConflict, map[string]any{"error": err.Error()})
		return
	}

	staticTemplate := s.resolveStaticQRIS(r)
	expireMin := s.resolveExpireMinutes(r)

	dynamicPayload, err := qris.GenerateDynamicQRIS(staticTemplate, payableAmount)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": err.Error()})
		return
	}
	qrSVG, svgErr := qris.RenderSVG(dynamicPayload)
	if svgErr != nil {
		qrSVG = ""
	}

	txID := newUUIDv4()
	refID := strings.TrimSpace(req.ReferenceID)
	if refID == "" {
		refID = fmt.Sprintf("QRIS-%d-%s", time.Now().Unix(), strings.ToUpper(txID[:6]))
	}
	expiresAt := time.Now().Add(time.Duration(expireMin) * time.Minute)

	var orderIDVal any = nil
	if req.OrderID != nil && strings.TrimSpace(*req.OrderID) != "" {
		orderIDVal = strings.TrimSpace(*req.OrderID)
	}

	_, err = s.db.ExecContext(r.Context(), `
		INSERT INTO qris_transactions (id, reference_id, purpose, order_id, user_id, base_amount, unique_code, amount, qris_payload, status, expires_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)
	`, txID, refID, purpose, orderIDVal, strings.TrimSpace(req.UserID), baseAmount, uniqueCode, payableAmount, dynamicPayload, expiresAt)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to store qris transaction: " + err.Error()})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"id":             txID,
		"reference_id":   refID,
		"purpose":        purpose,
		"order_id":       orderIDVal,
		"user_id":        req.UserID,
		"base_amount":    baseAmount,
		"unique_code":    uniqueCode,
		"payable_amount": payableAmount,
		"amount":         payableAmount,
		"qris_payload":   dynamicPayload,
		"qr_svg":         qrSVG,
		"status":         "PENDING",
		"expires_at":     expiresAt.Format(time.RFC3339),
	})
}

func (s *Server) handleQRISStatusSubtree(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	// Expect /pay/qris/:reference_id/status
	trimmed := strings.TrimPrefix(r.URL.Path, "/pay/qris/")
	parts := strings.Split(strings.Trim(trimmed, "/"), "/")
	if len(parts) < 1 || parts[0] == "" {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "reference_id is required"})
		return
	}
	refID := parts[0]

	var (
		id          string
		referenceID string
		purpose     string
		orderID     sql.NullString
		userID      string
		baseAmount  int64
		uniqueCode  int
		amount      int64
		qrisPayload string
		status      string
		expiresAt   time.Time
		paidAt      sql.NullTime
	)

	err := s.db.QueryRowContext(r.Context(), `
		SELECT id, reference_id, purpose, order_id, user_id,
		       COALESCE(base_amount, amount), COALESCE(unique_code, 0), amount,
		       qris_payload, status, expires_at, paid_at
		FROM qris_transactions
		WHERE reference_id = ?
	`, refID).Scan(&id, &referenceID, &purpose, &orderID, &userID, &baseAmount, &uniqueCode, &amount, &qrisPayload, &status, &expiresAt, &paidAt)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "QRIS transaction not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if status == "PENDING" && time.Now().After(expiresAt) {
		_, _ = s.db.ExecContext(r.Context(), `
			UPDATE qris_transactions SET status = 'EXPIRED' WHERE id = ? AND status = 'PENDING'
		`, id)
		status = "EXPIRED"
	}

	var paidAtStr any = nil
	if paidAt.Valid {
		paidAtStr = paidAt.Time.Format(time.RFC3339)
	}
	var orderIDOut any = nil
	if orderID.Valid {
		orderIDOut = orderID.String
	}
	qrSVG, _ := qris.RenderSVG(qrisPayload)

	writeJSON(w, http.StatusOK, map[string]any{
		"id":             id,
		"reference_id":   referenceID,
		"purpose":        purpose,
		"order_id":       orderIDOut,
		"user_id":        userID,
		"base_amount":    baseAmount,
		"unique_code":    uniqueCode,
		"payable_amount": amount,
		"amount":         amount,
		"qris_payload":   qrisPayload,
		"qr_svg":         qrSVG,
		"status":         status,
		"expires_at":     expiresAt.Format(time.RFC3339),
		"paid_at":        paidAtStr,
	})
}

type webhookRequest struct {
	ReferenceID      string `json:"reference_id"`
	Amount           int64  `json:"amount"`
	NotificationText string `json:"notification_text"`
	VerifiedBy       string `json:"verified_by"`
	Secret           string `json:"secret"`
}

var amountRegex = regexp.MustCompile(`(?i)rp\.?\s*([0-9][0-9\.]*)`)

func (s *Server) handleWebhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	var req webhookRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	if !s.isAuthorizedWebhook(r, req.Secret) {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "Unauthorized webhook secret or admin token"})
		return
	}

	tx, err := s.db.BeginTx(r.Context(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	matchedAmount := req.Amount
	if matchedAmount <= 0 && req.NotificationText != "" {
		matches := amountRegex.FindStringSubmatch(req.NotificationText)
		if len(matches) > 1 {
			cleanDigits := strings.ReplaceAll(matches[1], ".", "")
			if parsed, pErr := strconv.ParseInt(cleanDigits, 10, 64); pErr == nil {
				matchedAmount = parsed
			}
		}
	}

	var (
		qrisID      string
		referenceID string
		purpose     string
		orderID     sql.NullString
		userID      string
		amount      int64
		status      string
	)

	if strings.TrimSpace(req.ReferenceID) != "" {
		err = tx.QueryRowContext(r.Context(), `
			SELECT id, reference_id, purpose, order_id, user_id, amount, status
			FROM qris_transactions
			WHERE reference_id = ?
			FOR UPDATE
		`, strings.TrimSpace(req.ReferenceID)).Scan(&qrisID, &referenceID, &purpose, &orderID, &userID, &amount, &status)
	} else if matchedAmount > 0 {
		err = tx.QueryRowContext(r.Context(), `
			SELECT id, reference_id, purpose, order_id, user_id, amount, status
			FROM qris_transactions
			WHERE amount = ? AND status = 'PENDING' AND expires_at >= NOW()
			ORDER BY created_at DESC
			LIMIT 1
			FOR UPDATE
		`, matchedAmount).Scan(&qrisID, &referenceID, &purpose, &orderID, &userID, &amount, &status)
	} else {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "reference_id or amount/notification_text is required"})
		return
	}

	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "No matching QRIS transaction found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if status == "PAID" {
		_ = tx.Commit()
		writeJSON(w, http.StatusOK, map[string]any{
			"status":       "PAID",
			"reference_id": referenceID,
			"purpose":      purpose,
			"amount":       amount,
			"idempotent":   true,
		})
		return
	}

	verifiedBy := strings.TrimSpace(req.VerifiedBy)
	if verifiedBy == "" {
		verifiedBy = "payg-webhook"
	}

	_, err = tx.ExecContext(r.Context(), `
		UPDATE qris_transactions
		SET status = 'PAID', paid_at = NOW(), verified_by = ?
		WHERE id = ?
	`, verifiedBy, qrisID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to update qris status: " + err.Error()})
		return
	}

	var walletBalanceAfter *int64

	if purpose == "DRIVER_TOPUP" {
		walletID, balanceBefore, wErr := resolveOrCreateDriverWallet(r, tx, userID)
		if wErr != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to resolve driver wallet: " + wErr.Error()})
			return
		}
		after := balanceBefore + amount
		_, err = tx.ExecContext(r.Context(), `
			UPDATE wallets SET balance = ? WHERE id = ?
		`, after, walletID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to update wallet balance: " + err.Error()})
			return
		}

		wtxID := newUUIDv4()
		desc := fmt.Sprintf("Top-Up Saldo Deposit QRIS (%s)", referenceID)
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
			VALUES (?, ?, 'TOPUP_QRIS', ?, ?, ?, 'QRIS_TRANSACTION', ?, ?)
		`, wtxID, walletID, amount, balanceBefore, after, referenceID, desc)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to insert wallet transaction: " + err.Error()})
			return
		}
		walletBalanceAfter = &after
	} else if purpose == "ORDER_PAYMENT" && orderID.Valid && orderID.String != "" {
		_, err = tx.ExecContext(r.Context(), `
			UPDATE orders SET payment_status = 'PAID' WHERE id = ?
		`, orderID.String)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to update order payment_status: " + err.Error()})
			return
		}
	}

	if err := tx.Commit(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	resp := map[string]any{
		"status":       "PAID",
		"reference_id": referenceID,
		"purpose":      purpose,
		"amount":       amount,
	}
	if walletBalanceAfter != nil {
		resp["wallet_balance_after"] = *walletBalanceAfter
	}
	if orderID.Valid {
		resp["order_id"] = orderID.String
		s.notifyRideonInternalAsync(orderID.String, referenceID, purpose)
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) notifyRideonInternalAsync(orderID, referenceID, purpose string) {
	if s.rideonInternalURL == "" || orderID == "" {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
		defer cancel()
		body, _ := json.Marshal(map[string]any{
			"order_id":     orderID,
			"reference_id": referenceID,
			"purpose":      purpose,
		})
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.rideonInternalURL+"/v1/internal/qris-paid", bytes.NewReader(body))
		if err != nil {
			return
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-PayG-Secret", s.webhookSecret)
		client := &http.Client{Timeout: 4 * time.Second}
		if resp, err := client.Do(req); err == nil {
			resp.Body.Close()
		}
	}()
}

func ensureQRISSchema(db *sql.DB) {
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	for _, stmt := range []string{
		`ALTER TABLE qris_transactions ADD COLUMN base_amount BIGINT DEFAULT NULL AFTER user_id`,
		`ALTER TABLE qris_transactions ADD COLUMN unique_code INT DEFAULT NULL AFTER base_amount`,
	} {
		if _, err := db.ExecContext(ctx, stmt); err != nil {
			msg := strings.ToLower(err.Error())
			if !strings.Contains(msg, "duplicate column") && !strings.Contains(msg, "1060") {
				log.Printf("[PAYG] schema check warning: %v", err)
			}
		}
	}
}

func resolveOrCreateDriverWallet(r *http.Request, tx *sql.Tx, userOrDriverID string) (string, int64, error) {
	// First check if a DRIVER wallet exists directly for userOrDriverID
	var walletID string
	var balance int64
	err := tx.QueryRowContext(r.Context(), `
		SELECT id, balance FROM wallets WHERE owner_type = 'DRIVER' AND owner_id = ? FOR UPDATE
	`, userOrDriverID).Scan(&walletID, &balance)
	if err == nil {
		return walletID, balance, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return "", 0, err
	}

	// If user_id was passed, look up drivers.id for that user_id
	var driverID string
	dErr := tx.QueryRowContext(r.Context(), `
		SELECT id FROM drivers WHERE user_id = ? LIMIT 1
	`, userOrDriverID).Scan(&driverID)
	ownerID := userOrDriverID
	if dErr == nil && driverID != "" {
		ownerID = driverID
		err = tx.QueryRowContext(r.Context(), `
			SELECT id, balance FROM wallets WHERE owner_type = 'DRIVER' AND owner_id = ? FOR UPDATE
		`, ownerID).Scan(&walletID, &balance)
		if err == nil {
			return walletID, balance, nil
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return "", 0, err
		}
	}

	// Create wallet if it didn't exist yet
	walletID = newUUIDv4()
	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO wallets (id, owner_type, owner_id, balance) VALUES (?, 'DRIVER', ?, 0)
	`, walletID, ownerID)
	if err != nil {
		return "", 0, err
	}
	return walletID, 0, nil
}

func (s *Server) isAuthorizedWebhook(r *http.Request, bodySecret string) bool {
	candidates := []string{
		r.Header.Get("X-PayG-Secret"),
		r.Header.Get("X-Webhook-Secret"),
		bodySecret,
	}
	for _, c := range candidates {
		if c != "" && c == s.webhookSecret {
			return true
		}
	}
	authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
	if strings.HasPrefix(strings.ToLower(authHeader), "bearer ") {
		token := strings.TrimSpace(authHeader[7:])
		if token == s.webhookSecret || verifyHS256AdminJWT(token, s.jwtSecret) {
			return true
		}
	}
	return false
}

func verifyHS256AdminJWT(tokenStr, secret string) bool {
	parts := strings.Split(tokenStr, ".")
	if len(parts) != 3 || secret == "" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(parts[0] + "." + parts[1]))
	expectedSig := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
	if !hmac.Equal([]byte(expectedSig), []byte(parts[2])) {
		return false
	}
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return false
	}
	var claims map[string]any
	if err := json.Unmarshal(payloadBytes, &claims); err != nil {
		return false
	}
	role, _ := claims["role"].(string)
	return strings.EqualFold(role, "ADMIN")
}

func (s *Server) resolveStaticQRIS(r *http.Request) string {
	var val string
	err := s.db.QueryRowContext(r.Context(), `
		SELECT value FROM system_settings WHERE `+"`key`"+` = 'payg_static_qris' LIMIT 1
	`).Scan(&val)
	if err == nil && strings.TrimSpace(val) != "" {
		return strings.TrimSpace(val)
	}
	return s.staticQRIS
}

func (s *Server) resolveExpireMinutes(r *http.Request) int {
	var val string
	err := s.db.QueryRowContext(r.Context(), `
		SELECT value FROM system_settings WHERE `+"`key`"+` = 'qris_expire_minutes' LIMIT 1
	`).Scan(&val)
	if err == nil {
		if parsed, pErr := strconv.Atoi(strings.TrimSpace(val)); pErr == nil && parsed > 0 {
			return parsed
		}
	}
	return s.expireMinutes
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

