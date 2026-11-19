package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"rideon-api/internal/auth"
)

func (s *Server) handleWalletsSubtree(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/wallets/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 || parts[0] == "" || parts[1] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "path must be /v1/wallets/:ownerType/:ownerId"})
		return
	}
	ownerType := strings.ToUpper(parts[0])
	ownerID := parts[1]

	var (
		walletID, bankName, bankAcc, bankHolder string
		balance                                 int64
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT id, balance, COALESCE(bank_name, ''), COALESCE(bank_account_number, ''), COALESCE(bank_account_holder, '')
		FROM wallets
		WHERE owner_type = ? AND owner_id = ?
		LIMIT 1
	`, ownerType, ownerID).Scan(&walletID, &balance, &bankName, &bankAcc, &bankHolder)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Wallet not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	rows, err := s.db.QueryContext(r.Context(), `
		SELECT id, tx_type, amount, balance_before, balance_after, COALESCE(reference_type, ''), COALESCE(reference_id, ''), description, created_at
		FROM wallet_transactions
		WHERE wallet_id = ?
		ORDER BY created_at DESC
		LIMIT 50
	`, walletID)
	var txs []map[string]any
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var (
				id, txType, refType, refID, desc string
				amt, bBefore, bAfter             int64
				createdAt                        time.Time
			)
			if rows.Scan(&id, &txType, &amt, &bBefore, &bAfter, &refType, &refID, &desc, &createdAt) == nil {
				txs = append(txs, map[string]any{
					"id":             id,
					"tx_type":        txType,
					"amount":         amt,
					"balance_before": bBefore,
					"balance_after":  bAfter,
					"reference_type": refType,
					"reference_id":   refID,
					"description":    desc,
					"created_at":     createdAt.Format(time.RFC3339),
				})
			}
		}
	}
	if txs == nil {
		txs = []map[string]any{}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"wallet": map[string]any{
			"id":                  walletID,
			"owner_type":          ownerType,
			"owner_id":            ownerID,
			"balance":             balance,
			"bank_name":           bankName,
			"bank_account_number": bankAcc,
			"bank_account_holder": bankHolder,
			"transactions":        txs,
		},
	})
}

type withdrawalCreateRequest struct {
	OwnerType         string `json:"owner_type"` // DRIVER or STORE
	OwnerID           string `json:"owner_id"`
	RequesterUserID   string `json:"requester_user_id"`
	Amount            int64  `json:"amount"`
	BankName          string `json:"bank_name"`
	BankAccountNumber string `json:"bank_account_number"`
	BankAccountHolder string `json:"bank_account_holder"`
	Pin               string `json:"pin"` // 6-digit PIN for STORE
}

func (s *Server) handleWithdrawals(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		rows, err := s.db.QueryContext(r.Context(), `
			SELECT w.id, w.wallet_id, w.requester_user_id, u.name, w.amount, w.admin_fee, w.net_amount,
			       w.bank_name, w.bank_account_number, w.bank_account_holder, w.status, w.created_at
			FROM withdrawals w
			JOIN users u ON u.id = w.requester_user_id
			ORDER BY w.created_at DESC LIMIT 50
		`)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()
		var list []map[string]any
		for rows.Next() {
			var (
				id, wID, uID, uName, bName, bAcc, bHolder, st string
				amt, fee, net                                 int64
				createdAt                                     time.Time
			)
			if rows.Scan(&id, &wID, &uID, &uName, &amt, &fee, &net, &bName, &bAcc, &bHolder, &st, &createdAt) == nil {
				list = append(list, map[string]any{
					"id":                  id,
					"wallet_id":           wID,
					"requester_user_id":   uID,
					"requester_name":      uName,
					"amount":              amt,
					"admin_fee":           fee,
					"net_amount":          net,
					"bank_name":           bName,
					"bank_account_number": bAcc,
					"bank_account_holder": bHolder,
					"status":              st,
					"created_at":          createdAt.Format(time.RFC3339),
				})
			}
		}
		if list == nil {
			list = []map[string]any{}
		}
		writeJSON(w, http.StatusOK, map[string]any{"withdrawals": list})
		return
	}

	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	var req withdrawalCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	ownerType := strings.ToUpper(strings.TrimSpace(req.OwnerType))
	if ownerType != "STORE" {
		ownerType = "DRIVER"
	}
	ownerID := strings.TrimSpace(req.OwnerID)
	requesterID := strings.TrimSpace(req.RequesterUserID)
	if requesterID == "" {
		if claims, err := s.extractClaims(r); err == nil {
			requesterID = claims.UserID
		}
	}
	if ownerID == "" || requesterID == "" || req.Amount <= 0 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "owner_id, requester_user_id, and positive amount are required"})
		return
	}

	if ownerType == "STORE" {
		var pinHash sql.NullString
		_ = s.db.QueryRowContext(r.Context(), `SELECT pin_hash FROM stores WHERE id = ?`, ownerID).Scan(&pinHash)
		if pinHash.Valid && pinHash.String != "" {
			if strings.TrimSpace(req.Pin) == "" || !auth.CheckPassword(pinHash.String, strings.TrimSpace(req.Pin)) {
				writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "PIN pencairan saldo toko tidak sesuai"})
				return
			}
		}
	}

	adminFee := s.getInt64Setting(r.Context(), "withdraw_admin_fee", s.withdrawAdminFee)
	if req.Amount <= adminFee {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": fmt.Sprintf("Nominal penarikan harus lebih besar dari biaya admin Rp %d", adminFee)})
		return
	}
	netAmount := req.Amount - adminFee

	tx, err := s.db.BeginTx(r.Context(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	var (
		walletID, bName, bAcc, bHolder string
		balance                        int64
	)
	err = tx.QueryRowContext(r.Context(), `
		SELECT id, balance, COALESCE(bank_name, 'BSI'), COALESCE(bank_account_number, '-'), COALESCE(bank_account_holder, '-')
		FROM wallets WHERE owner_type = ? AND owner_id = ? FOR UPDATE
	`, ownerType, ownerID).Scan(&walletID, &balance, &bName, &bAcc, &bHolder)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Wallet not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if balance < req.Amount {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Saldo dompet tidak mencukupi untuk penarikan"})
		return
	}

	if strings.TrimSpace(req.BankName) != "" {
		bName = strings.TrimSpace(req.BankName)
	}
	if strings.TrimSpace(req.BankAccountNumber) != "" {
		bAcc = strings.TrimSpace(req.BankAccountNumber)
	}
	if strings.TrimSpace(req.BankAccountHolder) != "" {
		bHolder = strings.TrimSpace(req.BankAccountHolder)
	}

	afterBal := balance - req.Amount
	_, err = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, walletID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	wdID := newUUIDv4()
	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO withdrawals (id, wallet_id, requester_user_id, amount, admin_fee, net_amount, bank_name, bank_account_number, bank_account_holder, status)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')
	`, wdID, walletID, requesterID, req.Amount, adminFee, netAmount, bName, bAcc, bHolder)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
		VALUES (?, ?, 'WITHDRAWAL', ?, ?, ?, 'WITHDRAWAL', ?, ?)
	`, newUUIDv4(), walletID, -req.Amount, balance, afterBal, wdID, fmt.Sprintf("Pengajuan Tarik Saldo ke %s (%s)", bName, bAcc))
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if err := tx.Commit(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"id":             wdID,
		"wallet_id":      walletID,
		"amount":         req.Amount,
		"admin_fee":      adminFee,
		"net_amount":     netAmount,
		"status":         "PENDING",
		"wallet_balance": afterBal,
	})
}

type talanganCreateRequest struct {
	OrderID         string `json:"order_id"`
	DriverID        string `json:"driver_id"`
	ClaimedAmount   int64  `json:"claimed_amount"`
	GoodsPhotoURL   string `json:"goods_photo_url"`
	ReceiptPhotoURL string `json:"receipt_photo_url"`
}

func (s *Server) handleTalanganClaims(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		rows, err := s.db.QueryContext(r.Context(), `
			SELECT tc.id, tc.order_id, o.order_code, tc.driver_id, u.name AS driver_name,
			       tc.claimed_amount, tc.goods_photo_url, tc.receipt_photo_url, tc.status,
			       COALESCE(tc.orphanage_name, ''), COALESCE(tc.donation_photo_url, ''), tc.created_at
			FROM talangan_claims tc
			JOIN orders o ON o.id = tc.order_id
			JOIN drivers d ON d.id = tc.driver_id
			JOIN users u ON u.id = d.user_id
			ORDER BY tc.created_at DESC
		`)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()
		var list []map[string]any
		for rows.Next() {
			var (
				id, oID, oCode, dID, dName, gPhoto, rPhoto, st, orph, dPhoto string
				amt                                                          int64
				createdAt                                                    time.Time
			)
			if rows.Scan(&id, &oID, &oCode, &dID, &dName, &amt, &gPhoto, &rPhoto, &st, &orph, &dPhoto, &createdAt) == nil {
				list = append(list, map[string]any{
					"id":                 id,
					"order_id":           oID,
					"order_code":         oCode,
					"driver_id":          dID,
					"driver_name":        dName,
					"claimed_amount":     amt,
					"goods_photo_url":    gPhoto,
					"receipt_photo_url":  rPhoto,
					"status":             st,
					"orphanage_name":     orph,
					"donation_photo_url": dPhoto,
					"created_at":         createdAt.Format(time.RFC3339),
				})
			}
		}
		if list == nil {
			list = []map[string]any{}
		}
		writeJSON(w, http.StatusOK, map[string]any{"talangan_claims": list})
		return
	}

	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	var req talanganCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	if strings.TrimSpace(req.OrderID) == "" || strings.TrimSpace(req.DriverID) == "" || req.ClaimedAmount <= 0 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "order_id, driver_id, and positive claimed_amount are required"})
		return
	}
	gPhoto := strings.TrimSpace(req.GoodsPhotoURL)
	if gPhoto == "" {
		gPhoto = "/uploads/talangan/goods-placeholder.jpg"
	}
	rPhoto := strings.TrimSpace(req.ReceiptPhotoURL)
	if rPhoto == "" {
		rPhoto = "/uploads/talangan/receipt-placeholder.jpg"
	}

	id := newUUIDv4()
	_, err := s.db.ExecContext(r.Context(), `
		INSERT INTO talangan_claims (id, order_id, driver_id, claimed_amount, goods_photo_url, receipt_photo_url, status)
		VALUES (?, ?, ?, ?, ?, ?, 'SUBMITTED_STEP1')
	`, id, strings.TrimSpace(req.OrderID), strings.TrimSpace(req.DriverID), req.ClaimedAmount, gPhoto, rPhoto)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	_, _ = s.db.ExecContext(r.Context(), `UPDATE orders SET status = 'TALANGAN_CLAIMED' WHERE id = ?`, strings.TrimSpace(req.OrderID))

	writeJSON(w, http.StatusCreated, map[string]any{
		"id":                id,
		"order_id":          req.OrderID,
		"driver_id":         req.DriverID,
		"claimed_amount":    req.ClaimedAmount,
		"goods_photo_url":   gPhoto,
		"receipt_photo_url": rPhoto,
		"status":            "SUBMITTED_STEP1",
	})
}

func (s *Server) handleTalanganClaimSubtree(w http.ResponseWriter, r *http.Request) {
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/talangan-claims/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "claim id and action are required"})
		return
	}
	claimID := parts[0]
	action := parts[1]

	if action == "donate" && (r.Method == http.MethodPut || r.Method == http.MethodPost) {
		var body struct {
			OrphanageName    string `json:"orphanage_name"`
			DonationPhotoURL string `json:"donation_photo_url"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		if strings.TrimSpace(body.OrphanageName) == "" {
			body.OrphanageName = "Panti Asuhan Muhammadiyah Lhokseumawe"
		}
		if strings.TrimSpace(body.DonationPhotoURL) == "" {
			body.DonationPhotoURL = "/uploads/talangan/donation-proof.jpg"
		}
		_, err := s.db.ExecContext(r.Context(), `
			UPDATE talangan_claims
			SET orphanage_name = ?, donation_photo_url = ?, status = 'APPROVED_FOR_DONATION'
			WHERE id = ?
		`, body.OrphanageName, body.DonationPhotoURL, claimID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"id":                 claimID,
			"orphanage_name":     body.OrphanageName,
			"donation_photo_url": body.DonationPhotoURL,
			"status":             "APPROVED_FOR_DONATION",
		})
		return
	}
	writeJSON(w, http.StatusNotFound, map[string]any{"error": "Endpoint not found"})
}

func (s *Server) handleSupportTickets(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		rows, err := s.db.QueryContext(r.Context(), `
			SELECT t.id, COALESCE(t.user_id, ''), COALESCE(u.name, 'Pengguna RideOn'),
			       COALESCE(t.order_id, ''), t.channel, t.sender_contact, t.subject, t.body,
			       t.status, COALESCE(t.admin_reply, ''), t.created_at
			FROM support_tickets t
			LEFT JOIN users u ON u.id = t.user_id
			ORDER BY t.created_at DESC
			LIMIT 100
		`)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()
		var list []map[string]any
		for rows.Next() {
			var (
				id, uID, uName, oID, ch, contact, subj, body, st, reply string
				createdAt                                               time.Time
			)
			if rows.Scan(&id, &uID, &uName, &oID, &ch, &contact, &subj, &body, &st, &reply, &createdAt) == nil {
				list = append(list, map[string]any{
					"id":             id,
					"user_id":        uID,
					"user_name":      uName,
					"order_id":       oID,
					"channel":        ch,
					"sender_contact": contact,
					"subject":        subj,
					"body":           body,
					"status":         st,
					"admin_reply":    reply,
					"created_at":     createdAt.Format(time.RFC3339),
				})
			}
		}
		if list == nil {
			list = []map[string]any{}
		}
		writeJSON(w, http.StatusOK, map[string]any{"support_tickets": list})

	case http.MethodPost:
		var in struct {
			UserID        *string `json:"user_id"`
			OrderID       *string `json:"order_id"`
			Channel       string  `json:"channel"`
			SenderContact string  `json:"sender_contact"`
			Subject       string  `json:"subject"`
			Body          string  `json:"body"`
		}
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		if strings.TrimSpace(in.Subject) == "" || strings.TrimSpace(in.Body) == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "subject and body are required"})
			return
		}
		ch := strings.ToUpper(strings.TrimSpace(in.Channel))
		if ch != "EMAIL" && ch != "WHATSAPP" {
			ch = "IN_APP"
		}
		contact := strings.TrimSpace(in.SenderContact)
		if contact == "" {
			contact = "user@rideons.app"
		}
		var uVal, oVal any
		if in.UserID != nil && strings.TrimSpace(*in.UserID) != "" {
			uVal = strings.TrimSpace(*in.UserID)
		}
		if in.OrderID != nil && strings.TrimSpace(*in.OrderID) != "" {
			oVal = strings.TrimSpace(*in.OrderID)
		}

		id := newUUIDv4()
		_, err := s.db.ExecContext(r.Context(), `
			INSERT INTO support_tickets (id, user_id, order_id, channel, sender_contact, subject, body, status)
			VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN')
		`, id, uVal, oVal, ch, contact, strings.TrimSpace(in.Subject), strings.TrimSpace(in.Body))
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, map[string]any{
			"id":      id,
			"channel": ch,
			"subject": in.Subject,
			"status":  "OPEN",
		})

	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
	}
}

func isWAEscalationMessage(msg string) bool {
	lower := strings.ToLower(msg)
	for _, kw := range []string{"komplain", "cs", "admin", "bantuan", "keluhan", "penipuan", "batal", "refund", "gagal", "lapor", "talangan"} {
		if strings.Contains(lower, kw) {
			return true
		}
	}
	return false
}

func (s *Server) handleWAWebhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var payload struct {
		Sender  string `json:"sender"`
		From    string `json:"from"`
		Phone   string `json:"phone"`
		Name    string `json:"name"`
		Message string `json:"message"`
		Text    string `json:"text"`
		Body    string `json:"body"`
	}
	_ = json.NewDecoder(r.Body).Decode(&payload)

	sender := strings.TrimSpace(payload.Sender)
	if sender == "" {
		sender = strings.TrimSpace(payload.From)
	}
	if sender == "" {
		sender = strings.TrimSpace(payload.Phone)
	}
	msgText := strings.TrimSpace(payload.Message)
	if msgText == "" {
		msgText = strings.TrimSpace(payload.Text)
	}
	if msgText == "" {
		msgText = strings.TrimSpace(payload.Body)
	}

	if msgText == "" {
		writeJSON(w, http.StatusOK, map[string]any{"received": true, "ai_replied": false, "ticket_created": false})
		return
	}

	normSender := normalizePhone(sender)
	if normSender == "" {
		normSender = sender
	}

	var matchedUserID sql.NullString
	if normSender != "" {
		_ = s.db.QueryRowContext(r.Context(), `SELECT id FROM users WHERE phone = ? LIMIT 1`, normSender).Scan(&matchedUserID)
	}

	sessionID := "wa-" + normSender
	if len(sessionID) > 64 {
		sessionID = sessionID[:64]
	}

	aiReply := ""
	aiReplied := false
	client := &http.Client{Timeout: 8 * time.Second}
	aiReqBody, _ := json.Marshal(map[string]any{
		"session_id": sessionID,
		"user_id":    matchedUserID.String,
		"app_role":   "WHATSAPP",
		"message":    msgText,
	})
	if aiReq, err := http.NewRequestWithContext(r.Context(), http.MethodPost, s.aiServiceURL+"/ai/chat", bytes.NewReader(aiReqBody)); err == nil {
		aiReq.Header.Set("Content-Type", "application/json")
		if aiResp, dErr := client.Do(aiReq); dErr == nil {
			var parsed struct {
				Reply string `json:"reply"`
			}
			_ = json.NewDecoder(aiResp.Body).Decode(&parsed)
			aiResp.Body.Close()
			if strings.TrimSpace(parsed.Reply) != "" {
				aiReply = strings.TrimSpace(parsed.Reply)
			}
		}
	}

	if aiReply != "" && normSender != "" {
		waPayload, _ := json.Marshal(map[string]any{
			"target":  normSender,
			"message": aiReply,
		})
		if waReq, err := http.NewRequestWithContext(r.Context(), http.MethodPost, s.waGatewayURL+"/send", bytes.NewReader(waPayload)); err == nil {
			waReq.Header.Set("Content-Type", "application/json")
			waReq.Header.Set("X-Gateway-Secret", s.waGatewaySecret)
			if waResp, dErr := client.Do(waReq); dErr == nil {
				waResp.Body.Close()
				if waResp.StatusCode >= 200 && waResp.StatusCode < 300 {
					aiReplied = true
				}
			}
		}
	}

	ticketCreated := false
	if isWAEscalationMessage(msgText) {
		ctx := r.Context()
		senderLabel := strings.TrimSpace(payload.Name)
		if senderLabel == "" {
			senderLabel = normSender
		}
		subj := fmt.Sprintf("Pesan WhatsApp dari %s (%s)", senderLabel, normSender)
		var uVal any
		if matchedUserID.Valid && matchedUserID.String != "" {
			uVal = matchedUserID.String
		}
		if _, err := s.db.ExecContext(ctx, `
			INSERT INTO support_tickets (id, user_id, channel, sender_contact, subject, body, status)
			VALUES (?, ?, 'WHATSAPP', ?, ?, ?, 'OPEN')
		`, newUUIDv4(), uVal, normSender, subj, msgText); err == nil {
			ticketCreated = true
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"received":       true,
		"ai_replied":     aiReplied,
		"ticket_created": ticketCreated,
		"reply":          aiReply,
	})
}

