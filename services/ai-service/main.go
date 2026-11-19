package main

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
	aicontext "rideon-ai-service/internal/context"
	"rideon-ai-service/internal/crypto"
	"rideon-ai-service/internal/router"
)

type Server struct {
	db     *sql.DB
	encKey []byte
}

func main() {
	port := getEnv("PORT", "8083")
	dbHost := getEnv("DB_HOST", "127.0.0.1")
	dbPort := getEnv("DB_PORT", "3306")
	dbName := getEnv("DB_DATABASE", "rideon_db")
	dbUser := getEnv("DB_USERNAME", "rideon")
	dbPass := getEnv("DB_PASSWORD", "rideon_secret")

	rawKey := getEnv("AI_ENCRYPTION_KEY", "0123456789abcdef0123456789abcdef")
	encKey, err := crypto.NormalizeKey(rawKey)
	if err != nil {
		log.Fatalf("[AI-SERVICE] invalid AI_ENCRYPTION_KEY: %v", err)
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&loc=Asia%%2FJakarta&charset=utf8mb4",
		dbUser, dbPass, dbHost, dbPort, dbName)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("[AI-SERVICE] failed to open mysql connection: %v", err)
	}
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	srv := &Server{
		db:     db,
		encKey: encKey,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/ai/health", srv.handleHealth)
	mux.HandleFunc("/health", srv.handleHealth)
	mux.HandleFunc("/ai/chat", srv.handleChat)
	mux.HandleFunc("/ai/providers", srv.handleProvidersCollection)
	mux.HandleFunc("/ai/providers/", srv.handleProviderByID)

	log.Printf("[AI-SERVICE] listening on 0.0.0.0:%s", port)
	if err := http.ListenAndServe("0.0.0.0:"+port, corsMiddleware(mux)); err != nil {
		log.Fatalf("[AI-SERVICE] server stopped: %v", err)
	}
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
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
		"service":  "rideon-ai-service",
		"database": dbStatus,
	})
}

type chatMessageInput struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	SessionID    string             `json:"session_id"`
	UserID       string             `json:"user_id"`
	AppRole      string             `json:"app_role"`
	Message      string             `json:"message"`
	SystemPrompt string             `json:"system_prompt"`
	Messages     []chatMessageInput `json:"messages"`
}

func (s *Server) handleChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	var req chatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	customSystem := strings.TrimSpace(req.SystemPrompt)
	msgText := strings.TrimSpace(req.Message)
	if msgText == "" && len(req.Messages) > 0 {
		var history []string
		for _, m := range req.Messages {
			role := strings.ToLower(strings.TrimSpace(m.Role))
			content := strings.TrimSpace(m.Content)
			if content == "" {
				continue
			}
			if role == "system" {
				if customSystem == "" {
					customSystem = content
				} else {
					customSystem += "\n" + content
				}
				continue
			}
			if role == "user" {
				msgText = content
			}
			history = append(history, fmt.Sprintf("%s: %s", role, content))
		}
		if msgText == "" && len(history) > 0 {
			msgText = history[len(history)-1]
		}
	}
	if msgText == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "message or messages is required"})
		return
	}

	rawRole := strings.ToUpper(strings.TrimSpace(req.AppRole))
	dbRole := rawRole
	switch dbRole {
	case "CUSTOMER", "DRIVER", "STORE", "ADMIN":
	default:
		dbRole = "CUSTOMER"
	}

	sessionID := strings.TrimSpace(req.SessionID)
	if sessionID == "" {
		sessionID = "sess-" + newUUIDv4()[:8]
	}
	if rawRole == "WHATSAPP" && !strings.HasPrefix(sessionID, "wa-") {
		sessionID = "wa-" + sessionID
	}
	if len(sessionID) > 64 {
		sessionID = sessionID[:64]
	}

	userID := strings.TrimSpace(req.UserID)
	validUserID := s.resolveValidUserID(r.Context(), userID)

	userMsgID := newUUIDv4()
	_, err := s.db.ExecContext(r.Context(), `
		INSERT INTO ai_chat_messages (id, session_id, user_id, app_role, sender, message_text)
		VALUES (?, ?, ?, ?, 'USER', ?)
	`, userMsgID, sessionID, validUserID, dbRole, msgText)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to store user chat message: " + err.Error()})
		return
	}

	providers, err := s.loadProviders(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to load providers: " + err.Error()})
		return
	}

	roleForContext := rawRole
	if roleForContext == "" {
		roleForContext = dbRole
	}
	enrichedPrompt := aicontext.BuildSystemPrompt(r.Context(), s.db, roleForContext, userID, customSystem)
	for i := range providers {
		baseSys := strings.TrimSpace(providers[i].SystemPrompt)
		if baseSys != "" {
			providers[i].SystemPrompt = baseSys + "\n\n" + enrichedPrompt
		} else {
			providers[i].SystemPrompt = enrichedPrompt
		}
	}

	result, routeErr := router.RouteWithFailover(r.Context(), providers, msgText, nil)
	if routeErr != nil {
		result = router.GenerateResult{
			Reply:        "Mohon maaf, layanan asisten pintar sedang mengalami gangguan koneksi ke penyedia model. Silakan coba kembali beberapa saat lagi atau ajukan Tiket Bantuan.",
			ProviderUsed: "failover_exhausted",
			LatencyMs:    0,
			Simulated:    true,
		}
	}

	assistantMsgID := newUUIDv4()
	_, err = s.db.ExecContext(r.Context(), `
		INSERT INTO ai_chat_messages (id, session_id, user_id, app_role, sender, message_text, provider_used, latency_ms)
		VALUES (?, ?, ?, ?, 'ASSISTANT', ?, ?, ?)
	`, assistantMsgID, sessionID, validUserID, dbRole, result.Reply, result.ProviderUsed, result.LatencyMs)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to store assistant chat message: " + err.Error()})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"session_id":    sessionID,
		"user_id":       validUserID,
		"app_role":      roleForContext,
		"reply":         result.Reply,
		"provider_used": result.ProviderUsed,
		"latency_ms":    result.LatencyMs,
		"simulated":     result.Simulated,
	})
}

func (s *Server) resolveValidUserID(ctx context.Context, requestedID string) string {
	var id string
	err := s.db.QueryRowContext(ctx, `SELECT id FROM users WHERE id = ? LIMIT 1`, requestedID).Scan(&id)
	if err == nil && id != "" {
		return id
	}
	_ = s.db.QueryRowContext(ctx, `SELECT id FROM users ORDER BY created_at ASC LIMIT 1`).Scan(&id)
	return id
}

func (s *Server) loadProviders(ctx context.Context) ([]router.ProviderConfig, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, display_name, adapter_type, base_url, api_key_encrypted, model_name,
		       COALESCE(system_prompt, ''), temperature, max_tokens, priority_order, is_active
		FROM ai_providers
		ORDER BY priority_order ASC, id ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []router.ProviderConfig
	for rows.Next() {
		var (
			p        router.ProviderConfig
			encKey   string
			isActive int
		)
		if err := rows.Scan(
			&p.ID,
			&p.DisplayName,
			&p.AdapterType,
			&p.BaseURL,
			&encKey,
			&p.ModelName,
			&p.SystemPrompt,
			&p.Temperature,
			&p.MaxTokens,
			&p.PriorityOrder,
			&isActive,
		); err != nil {
			return nil, err
		}
		p.IsActive = isActive == 1
		if strings.TrimSpace(encKey) != "" {
			if dec, dErr := crypto.DecryptAPIKey(encKey, s.encKey); dErr == nil {
				p.APIKey = dec
			}
		}
		list = append(list, p)
	}
	return list, rows.Err()
}

type providerInput struct {
	DisplayName   *string  `json:"display_name"`
	AdapterType   *string  `json:"adapter_type"`
	BaseURL       *string  `json:"base_url"`
	APIKey        *string  `json:"api_key"`
	ModelName     *string  `json:"model_name"`
	SystemPrompt  *string  `json:"system_prompt"`
	Temperature   *float64 `json:"temperature"`
	MaxTokens     *int     `json:"max_tokens"`
	PriorityOrder *int     `json:"priority_order"`
	IsActive      *bool    `json:"is_active"`
}

func (s *Server) handleProvidersCollection(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		rows, err := s.db.QueryContext(r.Context(), `
			SELECT id, display_name, adapter_type, base_url, api_key_encrypted, model_name,
			       COALESCE(system_prompt, ''), temperature, max_tokens, priority_order, is_active, updated_at
			FROM ai_providers
			ORDER BY priority_order ASC, id ASC
		`)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()

		var out []map[string]any
		for rows.Next() {
			var (
				id, displayName, adapterType, baseURL, encKey, modelName, systemPrompt string
				temp                                                                   float64
				maxTokens, priorityOrder, isActive                                     int
				updatedAt                                                              time.Time
			)
			if err := rows.Scan(&id, &displayName, &adapterType, &baseURL, &encKey, &modelName, &systemPrompt, &temp, &maxTokens, &priorityOrder, &isActive, &updatedAt); err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
				return
			}
			dec := ""
			if strings.TrimSpace(encKey) != "" {
				dec, _ = crypto.DecryptAPIKey(encKey, s.encKey)
			}
			out = append(out, map[string]any{
				"id":             id,
				"display_name":   displayName,
				"adapter_type":   adapterType,
				"base_url":       baseURL,
				"has_api_key":    strings.TrimSpace(encKey) != "",
				"api_key_masked": crypto.MaskAPIKey(dec, strings.TrimSpace(encKey) != ""),
				"model_name":     modelName,
				"system_prompt":  systemPrompt,
				"temperature":    temp,
				"max_tokens":     maxTokens,
				"priority_order": priorityOrder,
				"is_active":      isActive == 1,
				"updated_at":     updatedAt.Format(time.RFC3339),
			})
		}
		writeJSON(w, http.StatusOK, map[string]any{"providers": out})

	case http.MethodPost:
		var in providerInput
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		displayName := "Provider Baru"
		if in.DisplayName != nil && strings.TrimSpace(*in.DisplayName) != "" {
			displayName = strings.TrimSpace(*in.DisplayName)
		}
		adapterType := "openai_compatible"
		if in.AdapterType != nil && (*in.AdapterType == "openai_compatible" || *in.AdapterType == "gemini_native") {
			adapterType = *in.AdapterType
		}
		baseURL := "https://api.example.com/v1"
		if in.BaseURL != nil && strings.TrimSpace(*in.BaseURL) != "" {
			baseURL = strings.TrimSpace(*in.BaseURL)
		}
		modelName := "ganti-dengan-nama-model"
		if in.ModelName != nil && strings.TrimSpace(*in.ModelName) != "" {
			modelName = strings.TrimSpace(*in.ModelName)
		}
		sysPrompt := "Anda adalah asisten layanan ekosistem RideOn Lhokseumawe & Aceh Utara. Jawab dengan sopan, ringkas, dan jelas dalam Bahasa Indonesia."
		if in.SystemPrompt != nil {
			sysPrompt = *in.SystemPrompt
		}
		temp := 0.70
		if in.Temperature != nil {
			temp = *in.Temperature
		}
		maxTokens := 1024
		if in.MaxTokens != nil && *in.MaxTokens > 0 {
			maxTokens = *in.MaxTokens
		}
		priorityOrder := 1
		if in.PriorityOrder != nil {
			priorityOrder = *in.PriorityOrder
		}
		isActive := 0
		if in.IsActive != nil && *in.IsActive {
			isActive = 1
		}
		encKey := ""
		if in.APIKey != nil && strings.TrimSpace(*in.APIKey) != "" {
			var err error
			encKey, err = crypto.EncryptAPIKey(strings.TrimSpace(*in.APIKey), s.encKey)
			if err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to encrypt api_key: " + err.Error()})
				return
			}
		}

		id := newUUIDv4()
		_, err := s.db.ExecContext(r.Context(), `
			INSERT INTO ai_providers (id, display_name, adapter_type, base_url, api_key_encrypted, model_name, system_prompt, temperature, max_tokens, priority_order, is_active)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, id, displayName, adapterType, baseURL, encKey, modelName, sysPrompt, temp, maxTokens, priorityOrder, isActive)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, map[string]any{
			"id":             id,
			"display_name":   displayName,
			"adapter_type":   adapterType,
			"base_url":       baseURL,
			"has_api_key":    encKey != "",
			"model_name":     modelName,
			"priority_order": priorityOrder,
			"is_active":      isActive == 1,
		})

	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
	}
}

func (s *Server) handleProviderByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	id := strings.Trim(strings.TrimPrefix(r.URL.Path, "/ai/providers/"), "/")
	if id == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "provider id is required"})
		return
	}

	var in providerInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	var (
		displayName, adapterType, baseURL, encKey, modelName, systemPrompt string
		temp                                                               float64
		maxTokens, priorityOrder, isActive                                 int
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT display_name, adapter_type, base_url, api_key_encrypted, model_name,
		       COALESCE(system_prompt, ''), temperature, max_tokens, priority_order, is_active
		FROM ai_providers
		WHERE id = ?
	`, id).Scan(&displayName, &adapterType, &baseURL, &encKey, &modelName, &systemPrompt, &temp, &maxTokens, &priorityOrder, &isActive)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "AI provider not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if in.DisplayName != nil && strings.TrimSpace(*in.DisplayName) != "" {
		displayName = strings.TrimSpace(*in.DisplayName)
	}
	if in.AdapterType != nil {
		if *in.AdapterType != "openai_compatible" && *in.AdapterType != "gemini_native" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "adapter_type must be openai_compatible or gemini_native"})
			return
		}
		adapterType = *in.AdapterType
	}
	if in.BaseURL != nil && strings.TrimSpace(*in.BaseURL) != "" {
		baseURL = strings.TrimSpace(*in.BaseURL)
	}
	if in.ModelName != nil && strings.TrimSpace(*in.ModelName) != "" {
		modelName = strings.TrimSpace(*in.ModelName)
	}
	if in.SystemPrompt != nil {
		systemPrompt = *in.SystemPrompt
	}
	if in.Temperature != nil {
		temp = *in.Temperature
	}
	if in.MaxTokens != nil && *in.MaxTokens > 0 {
		maxTokens = *in.MaxTokens
	}
	if in.PriorityOrder != nil {
		priorityOrder = *in.PriorityOrder
	}
	if in.IsActive != nil {
		if *in.IsActive {
			isActive = 1
		} else {
			isActive = 0
		}
	}
	if in.APIKey != nil {
		rawPlain := strings.TrimSpace(*in.APIKey)
		if rawPlain == "" {
			encKey = ""
		} else {
			encrypted, encErr := crypto.EncryptAPIKey(rawPlain, s.encKey)
			if encErr != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to encrypt api_key: " + encErr.Error()})
				return
			}
			encKey = encrypted
		}
	}

	_, err = s.db.ExecContext(r.Context(), `
		UPDATE ai_providers
		SET display_name = ?, adapter_type = ?, base_url = ?, api_key_encrypted = ?,
		    model_name = ?, system_prompt = ?, temperature = ?, max_tokens = ?,
		    priority_order = ?, is_active = ?
		WHERE id = ?
	`, displayName, adapterType, baseURL, encKey, modelName, systemPrompt, temp, maxTokens, priorityOrder, isActive, id)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	dec := ""
	if strings.TrimSpace(encKey) != "" {
		dec, _ = crypto.DecryptAPIKey(encKey, s.encKey)
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"id":             id,
		"display_name":   displayName,
		"adapter_type":   adapterType,
		"base_url":       baseURL,
		"has_api_key":    strings.TrimSpace(encKey) != "",
		"api_key_masked": crypto.MaskAPIKey(dec, strings.TrimSpace(encKey) != ""),
		"model_name":     modelName,
		"system_prompt":  systemPrompt,
		"temperature":    temp,
		"max_tokens":     maxTokens,
		"priority_order": priorityOrder,
		"is_active":      isActive == 1,
	})
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

