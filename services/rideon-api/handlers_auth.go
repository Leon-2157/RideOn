package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"net/http"
	"strings"
	"time"

	"rideon-api/internal/auth"
)

type loginRequest struct {
	Identifier string `json:"identifier"`
	Email      string `json:"email"`
	Phone      string `json:"phone"`
	Password   string `json:"password"`
}

func (s *Server) handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	ident := strings.TrimSpace(req.Identifier)
	if ident == "" {
		ident = strings.TrimSpace(req.Email)
	}
	if ident == "" {
		ident = strings.TrimSpace(req.Phone)
	}
	if ident == "" || strings.TrimSpace(req.Password) == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Email/Nomor WA dan password wajib diisi"})
		return
	}

	var (
		userID       string
		email        sql.NullString
		phone        sql.NullString
		passwordHash sql.NullString
		name         string
		role         string
		status       string
		avatarURL    sql.NullString
	)

	query := `SELECT id, email, phone, password_hash, name, role, status, avatar_url FROM users WHERE email = ? OR phone = ? LIMIT 1`
	normPhone := normalizePhone(ident)
	if normPhone == "" {
		normPhone = ident
	}
	err := s.db.QueryRowContext(r.Context(), query, ident, normPhone).Scan(
		&userID, &email, &phone, &passwordHash, &name, &role, &status, &avatarURL,
	)
	if errors.Is(err, sql.ErrNoRows) || !passwordHash.Valid || !auth.CheckPassword(passwordHash.String, req.Password) {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "Email/Nomor WA atau kata sandi salah"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	token, err := auth.GenerateJWT(s.jwtSecret, s.jwtExpiresHours, userID, role, status, email.String, name)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	profile := s.buildUserProfile(r.Context(), userID, email.String, phone.String, name, role, status, avatarURL.String)
	writeJSON(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  profile,
	})
}

type googleLoginRequest struct {
	GoogleUID string `json:"google_uid"`
	Email     string `json:"email"`
	Name      string `json:"name"`
	AvatarURL string `json:"avatar_url"`
	Role      string `json:"role"`
}

func (s *Server) handleGoogleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var req googleLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	email := strings.TrimSpace(req.Email)
	googleUID := strings.TrimSpace(req.GoogleUID)
	if email == "" && googleUID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "email or google_uid is required"})
		return
	}

	var (
		userID string
		uEmail sql.NullString
		uPhone sql.NullString
		uName  string
		uRole  string
		uStat  string
		uAvt   sql.NullString
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT id, email, phone, name, role, status, avatar_url
		FROM users
		WHERE (google_uid IS NOT NULL AND google_uid = ?) OR (email IS NOT NULL AND email = ?)
		LIMIT 1
	`, googleUID, email).Scan(&userID, &uEmail, &uPhone, &uName, &uRole, &uStat, &uAvt)

	if errors.Is(err, sql.ErrNoRows) {
		userID = newUUIDv4()
		uName = strings.TrimSpace(req.Name)
		if uName == "" {
			uName = strings.Split(email, "@")[0]
		}
		uRole = strings.ToUpper(strings.TrimSpace(req.Role))
		if uRole != "DRIVER" && uRole != "STORE" {
			uRole = "CUSTOMER"
		}
		if uRole == "CUSTOMER" {
			uStat = "ACTIVE"
		} else {
			uStat = "PENDING_APPROVAL"
		}
		var gVal any = nil
		if googleUID != "" {
			gVal = googleUID
		}
		var eVal any = nil
		if email != "" {
			eVal = email
		}
		_, iErr := s.db.ExecContext(r.Context(), `
			INSERT INTO users (id, email, google_uid, firebase_uid, name, role, status, avatar_url)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, eVal, gVal, "fb-"+userID[:8], uName, uRole, uStat, req.AvatarURL)
		if iErr != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": iErr.Error()})
			return
		}
		if uRole == "CUSTOMER" {
			_, _ = s.db.ExecContext(r.Context(), `
				INSERT INTO wallets (id, owner_type, owner_id, balance) VALUES (?, 'CUSTOMER', ?, 0)
			`, newUUIDv4(), userID)
		}
		uEmail = sql.NullString{String: email, Valid: email != ""}
		uAvt = sql.NullString{String: req.AvatarURL, Valid: req.AvatarURL != ""}
	} else if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	token, err := auth.GenerateJWT(s.jwtSecret, s.jwtExpiresHours, userID, uRole, uStat, uEmail.String, uName)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	profile := s.buildUserProfile(r.Context(), userID, uEmail.String, uPhone.String, uName, uRole, uStat, uAvt.String)
	writeJSON(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  profile,
	})
}

type otpSendRequest struct {
	Target  string `json:"target"`
	Channel string `json:"channel"` // EMAIL or WHATSAPP
	Purpose string `json:"purpose"` // LOGIN, REGISTER, RESET_PASSWORD
}

func (s *Server) handleOTPSend(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var req otpSendRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	target := strings.TrimSpace(req.Target)
	if target == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "target is required"})
		return
	}
	channel := strings.ToUpper(strings.TrimSpace(req.Channel))
	if channel != "EMAIL" && channel != "WHATSAPP" {
		if strings.Contains(target, "@") {
			channel = "EMAIL"
		} else {
			channel = "WHATSAPP"
		}
	}
	if channel == "WHATSAPP" {
		target = normalizePhone(target)
	}
	purpose := strings.ToUpper(strings.TrimSpace(req.Purpose))
	switch purpose {
	case "LOGIN", "REGISTER", "RESET_PASSWORD":
	default:
		purpose = "REGISTER"
	}

	code := fmt.Sprintf("%06d", 100000+rand.Intn(900000))
	otpHash, err := auth.HashPassword(code)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	otpID := newUUIDv4()
	expiresAt := time.Now().Add(5 * time.Minute)
	_, err = s.db.ExecContext(r.Context(), `
		INSERT INTO otp_verifications (id, target, channel, otp_hash, purpose, attempts, is_used, expires_at)
		VALUES (?, ?, ?, ?, ?, 0, 0, ?)
	`, otpID, target, channel, otpHash, purpose, expiresAt)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	providerUsed := "simulated_local"
	simulated := true

	if channel == "WHATSAPP" {
		payload, _ := json.Marshal(map[string]any{
			"phoneNumber": target,
			"purpose":     strings.ToLower(purpose),
			"code":        code,
		})
		client := &http.Client{Timeout: 5 * time.Second}
		waReq, reqErr := http.NewRequestWithContext(r.Context(), http.MethodPost, s.waGatewayURL+"/api/send-otp", bytes.NewReader(payload))
		if reqErr == nil {
			waReq.Header.Set("Content-Type", "application/json")
			waReq.Header.Set("X-Gateway-Secret", s.waGatewaySecret)
			if resp, dErr := client.Do(waReq); dErr == nil {
				defer resp.Body.Close()
				var waResp map[string]any
				_ = json.NewDecoder(resp.Body).Decode(&waResp)
				providerUsed = "wa-gateway"
				if simVal, ok := waResp["simulated"].(bool); ok {
					simulated = simVal
				}
			}
		}
	} else {
		html := fmt.Sprintf(`<div style="font-family:sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #e5e7eb;border-radius:12px;">
			<h2 style="color:#6B48FC;margin-top:0;">RideOn Indonesia</h2>
			<p>Kode verifikasi OTP (%s) Anda adalah:</p>
			<div style="font-size:28px;font-weight:700;letter-spacing:4px;padding:12px 16px;background:#f5f3ff;color:#17152B;border-radius:8px;text-align:center;">%s</div>
			<p style="font-size:12px;color:#6b7280;">Berlaku selama 5 menit. Jangan berikan kode ini kepada siapa pun.</p>
		</div>`, purpose, code)
		prov, _ := s.sendEmailMessage(target, "Kode Verifikasi OTP RideOn", html)
		providerUsed = prov
		simulated = prov == "simulated_local"
	}

	resp := map[string]any{
		"success":       true,
		"target":        target,
		"channel":       channel,
		"purpose":       purpose,
		"provider_used": providerUsed,
		"simulated":     simulated,
		"expires_at":    expiresAt.Format(time.RFC3339),
	}
	if simulated {
		resp["simulated_code"] = code
	}
	writeJSON(w, http.StatusOK, resp)
}

type otpVerifyRequest struct {
	Target  string `json:"target"`
	Channel string `json:"channel"`
	Code    string `json:"code"`
}

func (s *Server) handleOTPVerify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var req otpVerifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	target := strings.TrimSpace(req.Target)
	channel := strings.ToUpper(strings.TrimSpace(req.Channel))
	if channel == "" {
		if strings.Contains(target, "@") {
			channel = "EMAIL"
		} else {
			channel = "WHATSAPP"
		}
	}
	if channel == "WHATSAPP" {
		target = normalizePhone(target)
	}
	code := strings.TrimSpace(req.Code)
	if target == "" || code == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "target and code are required"})
		return
	}

	var (
		id        string
		otpHash   string
		attempts  int
		expiresAt time.Time
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT id, otp_hash, attempts, expires_at
		FROM otp_verifications
		WHERE target = ? AND channel = ? AND is_used = 0
		ORDER BY created_at DESC
		LIMIT 1
	`, target, channel).Scan(&id, &otpHash, &attempts, &expiresAt)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Kode OTP tidak ditemukan atau sudah digunakan"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	if time.Now().After(expiresAt) {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Kode OTP sudah kedaluwarsa"})
		return
	}
	if attempts >= 5 {
		writeJSON(w, http.StatusTooManyRequests, map[string]any{"error": "Terlalu banyak percobaan OTP yang salah"})
		return
	}
	if !auth.CheckPassword(otpHash, code) {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = ?`, id)
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Kode OTP tidak sesuai"})
		return
	}

	_, _ = s.db.ExecContext(r.Context(), `UPDATE otp_verifications SET is_used = 1 WHERE id = ?`, id)
	writeJSON(w, http.StatusOK, map[string]any{
		"success":  true,
		"verified": true,
		"target":   target,
		"channel":  channel,
	})
}

type registerRequest struct {
	Name           string  `json:"name"`
	Email          string  `json:"email"`
	Phone          string  `json:"phone"`
	Password       string  `json:"password"`
	Role           string  `json:"role"` // CUSTOMER, DRIVER, STORE
	VehicleType    string  `json:"vehicle_type"`
	VehicleBrand   string  `json:"vehicle_brand"`
	VehiclePlate   string  `json:"vehicle_plate"`
	KTPNumber      string  `json:"ktp_number"`
	SIMNumber      string  `json:"sim_number"`
	KTPPhotoURL    string  `json:"ktp_photo_url"`
	SIMPhotoURL    string  `json:"sim_photo_url"`
	STNKPhotoURL   string  `json:"stnk_photo_url"`
	StoreName      string  `json:"store_name"`
	Category       string  `json:"category"`
	Description    string  `json:"description"`
	Address        string  `json:"address"`
	Lat            float64 `json:"lat"`
	Lng            float64 `json:"lng"`
	StorePin       string  `json:"store_pin"`
	BusinessDocURL string  `json:"business_doc_url"`
	OpenTime       string  `json:"open_time"`
	CloseTime      string  `json:"close_time"`
}

func (s *Server) handleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var req registerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	name := strings.TrimSpace(req.Name)
	email := strings.TrimSpace(req.Email)
	phone := normalizePhone(req.Phone)
	if name == "" || (email == "" && phone == "") || len(req.Password) < 6 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Nama, Email/Nomor WA, dan password (minimal 6 karakter) wajib diisi"})
		return
	}

	role := strings.ToUpper(strings.TrimSpace(req.Role))
	switch role {
	case "DRIVER", "STORE", "CUSTOMER":
	default:
		role = "CUSTOMER"
	}

	userStatus := "ACTIVE"
	if role == "DRIVER" || role == "STORE" {
		userStatus = "PENDING_APPROVAL"
	}

	passHash, err := auth.HashPassword(req.Password)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	tx, err := s.db.BeginTx(r.Context(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	userID := newUUIDv4()
	var eVal, pVal any
	if email != "" {
		eVal = email
	}
	if phone != "" {
		pVal = phone
	}

	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO users (id, email, phone, password_hash, firebase_uid, name, role, status)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, userID, eVal, pVal, passHash, "fb-"+userID[:12], name, role, userStatus)
	if err != nil {
		writeJSON(w, http.StatusConflict, map[string]any{"error": "Email atau Nomor WA sudah terdaftar: " + err.Error()})
		return
	}

	if role == "CUSTOMER" {
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO wallets (id, owner_type, owner_id, balance) VALUES (?, 'CUSTOMER', ?, 0)
		`, newUUIDv4(), userID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
	} else if role == "DRIVER" {
		driverID := newUUIDv4()
		vType := strings.ToUpper(strings.TrimSpace(req.VehicleType))
		if vType != "MOBIL" {
			vType = "MOTOR"
		}
		vBrand := strings.TrimSpace(req.VehicleBrand)
		if vBrand == "" {
			vBrand = "Honda Beat"
		}
		vPlate := strings.TrimSpace(req.VehiclePlate)
		if vPlate == "" {
			vPlate = "BL " + strings.ToUpper(driverID[:4]) + " N"
		}
		lat := req.Lat
		lng := req.Lng
		if lat == 0 {
			lat = 5.2039
		}
		if lng == 0 {
			lng = 97.0642
		}
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO drivers (id, user_id, vehicle_type, vehicle_brand, vehicle_plate, ktp_number, sim_number, ktp_photo_url, sim_photo_url, stnk_photo_url, is_online, cash_float_amount, last_lat, last_lng)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 100000, ?, ?)
		`, driverID, userID, vType, vBrand, vPlate, req.KTPNumber, req.SIMNumber, req.KTPPhotoURL, req.SIMPhotoURL, req.STNKPhotoURL, lat, lng)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Gagal membuat profil driver: " + err.Error()})
			return
		}
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO wallets (id, owner_type, owner_id, balance) VALUES (?, 'DRIVER', ?, 0)
		`, newUUIDv4(), driverID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		payloadBytes, _ := json.Marshal(map[string]any{
			"vehicle_type":  vType,
			"vehicle_brand": vBrand,
			"vehicle_plate": vPlate,
			"ktp_number":    req.KTPNumber,
			"sim_number":    req.SIMNumber,
			"area":          "Lhokseumawe & Aceh Utara",
		})
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO registrations (id, user_id, applicant_role, status, payload_json)
			VALUES (?, ?, 'DRIVER', 'PENDING', ?)
		`, newUUIDv4(), userID, string(payloadBytes))
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
	} else if role == "STORE" {
		storeID := newUUIDv4()
		sName := strings.TrimSpace(req.StoreName)
		if sName == "" {
			sName = "Warung " + name
		}
		cat := strings.TrimSpace(req.Category)
		if cat == "" {
			cat = "Kuliner"
		}
		addr := strings.TrimSpace(req.Address)
		if addr == "" {
			addr = "Bukit Indah, Lhokseumawe"
		}
		lat := req.Lat
		lng := req.Lng
		if lat == 0 {
			lat = 5.2041
		}
		if lng == 0 {
			lng = 97.0638
		}
		pinPlain := strings.TrimSpace(req.StorePin)
		if pinPlain == "" {
			pinPlain = "123456"
		}
		openTime := strings.TrimSpace(req.OpenTime)
		if openTime == "" {
			openTime = "08:00"
		}
		closeTime := strings.TrimSpace(req.CloseTime)
		if closeTime == "" {
			closeTime = "22:00"
		}
		var docVal any = nil
		if strings.TrimSpace(req.BusinessDocURL) != "" {
			docVal = strings.TrimSpace(req.BusinessDocURL)
		}
		pinHash, _ := auth.HashPassword(pinPlain)
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO stores (id, user_id, store_name, category, description, address, lat, lng, banner_url, is_open, open_time, close_time, pin_hash)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
		`, storeID, userID, sName, cat, req.Description, addr, lat, lng, docVal, openTime, closeTime, pinHash)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Gagal membuat profil toko: " + err.Error()})
			return
		}
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO wallets (id, owner_type, owner_id, balance) VALUES (?, 'STORE', ?, 0)
		`, newUUIDv4(), storeID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		payloadBytes, _ := json.Marshal(map[string]any{
			"store_name":       sName,
			"category":         cat,
			"address":          addr,
			"lat":              lat,
			"lng":              lng,
			"open_time":        openTime,
			"close_time":       closeTime,
			"business_doc_url": strings.TrimSpace(req.BusinessDocURL),
			"area":             addr,
		})
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO registrations (id, user_id, applicant_role, status, payload_json)
			VALUES (?, ?, 'STORE', 'PENDING', ?)
		`, newUUIDv4(), userID, string(payloadBytes))
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
	}

	if err := tx.Commit(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if s.firebase != nil && email != "" {
		go func(em, pw, nm string) {
			ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
			defer cancel()
			_ = s.firebase.SyncAuthUser(ctx, em, pw, nm)
		}(email, req.Password, name)
	}

	token, _ := auth.GenerateJWT(s.jwtSecret, s.jwtExpiresHours, userID, role, userStatus, email, name)
	profile := s.buildUserProfile(r.Context(), userID, email, phone, name, role, userStatus, "")
	writeJSON(w, http.StatusCreated, map[string]any{
		"token": token,
		"user":  profile,
	})
}

func (s *Server) handleAuthMe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodPatch && r.Method != http.MethodPut {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	claims, err := s.extractClaims(r)
	if err != nil {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"error": err.Error()})
		return
	}

	if r.Method == http.MethodPatch || r.Method == http.MethodPut {
		var body struct {
			Name      *string `json:"name"`
			Phone     *string `json:"phone"`
			Email     *string `json:"email"`
			AvatarURL *string `json:"avatar_url"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		var sets []string
		var args []any
		if body.Name != nil && strings.TrimSpace(*body.Name) != "" {
			sets = append(sets, "name = ?")
			args = append(args, strings.TrimSpace(*body.Name))
		}
		if body.Phone != nil && strings.TrimSpace(*body.Phone) != "" {
			sets = append(sets, "phone = ?")
			args = append(args, normalizePhone(*body.Phone))
		}
		if body.Email != nil && strings.TrimSpace(*body.Email) != "" {
			sets = append(sets, "email = ?")
			args = append(args, strings.ToLower(strings.TrimSpace(*body.Email)))
		}
		if body.AvatarURL != nil && strings.TrimSpace(*body.AvatarURL) != "" {
			sets = append(sets, "avatar_url = ?")
			args = append(args, strings.TrimSpace(*body.AvatarURL))
		}
		if len(sets) > 0 {
			args = append(args, claims.UserID)
			if _, uErr := s.db.ExecContext(r.Context(), "UPDATE users SET "+strings.Join(sets, ", ")+" WHERE id = ?", args...); uErr != nil {
				status := http.StatusInternalServerError
				if strings.Contains(uErr.Error(), "Duplicate") {
					status = http.StatusConflict
				}
				writeJSON(w, status, map[string]any{"error": uErr.Error()})
				return
			}
		}
	}

	var (
		email, phone, avatar sql.NullString
		name, role, status   string
	)
	err = s.db.QueryRowContext(r.Context(), `
		SELECT email, phone, name, role, status, avatar_url FROM users WHERE id = ?
	`, claims.UserID).Scan(&email, &phone, &name, &role, &status, &avatar)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "user not found"})
		return
	}
	profile := s.buildUserProfile(r.Context(), claims.UserID, email.String, phone.String, name, role, status, avatar.String)
	writeJSON(w, http.StatusOK, map[string]any{"user": profile})
}

func (s *Server) buildUserProfile(ctx context.Context, userID, email, phone, name, role, status, avatarURL string) map[string]any {
	profile := map[string]any{
		"id":         userID,
		"email":      email,
		"phone":      phone,
		"name":       name,
		"role":       role,
		"status":     status,
		"avatar_url": avatarURL,
	}

	if role == "DRIVER" {
		var (
			dID, vType, vBrand, vPlate string
			isOnline                   int
			cashFloat                  int64
			ratingAvg                  float64
			totalTrips                 int
		)
		if err := s.db.QueryRowContext(ctx, `
			SELECT id, vehicle_type, vehicle_brand, vehicle_plate, is_online, cash_float_amount, rating_avg, total_trips
			FROM drivers WHERE user_id = ? LIMIT 1
		`, userID).Scan(&dID, &vType, &vBrand, &vPlate, &isOnline, &cashFloat, &ratingAvg, &totalTrips); err == nil {
			var bal int64
			_ = s.db.QueryRowContext(ctx, `SELECT balance FROM wallets WHERE owner_type = 'DRIVER' AND owner_id = ? LIMIT 1`, dID).Scan(&bal)
			profile["driver"] = map[string]any{
				"id":                dID,
				"vehicle_type":      vType,
				"vehicle_brand":     vBrand,
				"vehicle_plate":     vPlate,
				"is_online":         isOnline == 1,
				"cash_float_amount": cashFloat,
				"rating_avg":        ratingAvg,
				"total_trips":       totalTrips,
				"wallet_balance":    bal,
			}
		}
	} else if role == "STORE" {
		var (
			sID, sName, cat, addr string
			lat, lng, ratingAvg   float64
			isOpen                int
		)
		if err := s.db.QueryRowContext(ctx, `
			SELECT id, store_name, category, address, lat, lng, is_open, rating_avg
			FROM stores WHERE user_id = ? LIMIT 1
		`, userID).Scan(&sID, &sName, &cat, &addr, &lat, &lng, &isOpen, &ratingAvg); err == nil {
			var bal int64
			_ = s.db.QueryRowContext(ctx, `SELECT balance FROM wallets WHERE owner_type = 'STORE' AND owner_id = ? LIMIT 1`, sID).Scan(&bal)
			profile["store"] = map[string]any{
				"id":             sID,
				"store_name":     sName,
				"category":       cat,
				"address":        addr,
				"lat":            lat,
				"lng":            lng,
				"is_open":        isOpen == 1,
				"rating_avg":     ratingAvg,
				"wallet_balance": bal,
			}
		}
	}
	return profile
}

