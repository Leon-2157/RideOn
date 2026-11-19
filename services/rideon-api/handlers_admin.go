package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func (s *Server) handleAdminOverview(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	ctx := r.Context()

	var (
		totalOrders        int
		activeOrders       int
		completedOrders    int
		totalDrivers       int
		onlineDrivers      int
		totalStores        int
		openStores         int
		totalCustomers     int
		pendingRegs        int
		pendingWithdrawals int
		pendingTalangan    int
		platformRevenue    int64
	)

	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM orders`).Scan(&totalOrders)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM orders WHERE status NOT IN ('COMPLETED', 'CANCELLED')`).Scan(&activeOrders)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM orders WHERE status = 'COMPLETED'`).Scan(&completedOrders)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM drivers`).Scan(&totalDrivers)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM drivers d JOIN users u ON u.id = d.user_id WHERE d.is_online = 1 AND u.status = 'ACTIVE'`).Scan(&onlineDrivers)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM stores`).Scan(&totalStores)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM stores st JOIN users u ON u.id = st.user_id WHERE st.is_open = 1 AND u.status = 'ACTIVE'`).Scan(&openStores)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM users WHERE role = 'CUSTOMER'`).Scan(&totalCustomers)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM registrations WHERE status = 'PENDING'`).Scan(&pendingRegs)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM withdrawals WHERE status = 'PENDING'`).Scan(&pendingWithdrawals)
	_ = s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM talangan_claims WHERE status IN ('SUBMITTED_STEP1', 'APPROVED_FOR_DONATION')`).Scan(&pendingTalangan)
	_ = s.db.QueryRowContext(ctx, `SELECT COALESCE(SUM(platform_commission_driver + platform_commission_store), 0) FROM orders WHERE status = 'COMPLETED'`).Scan(&platformRevenue)

	writeJSON(w, http.StatusOK, map[string]any{
		"metrics": map[string]any{
			"total_orders":        totalOrders,
			"active_orders":       activeOrders,
			"completed_orders":    completedOrders,
			"total_drivers":       totalDrivers,
			"online_drivers":      onlineDrivers,
			"total_stores":        totalStores,
			"open_stores":         openStores,
			"total_customers":     totalCustomers,
			"pending_registrations": pendingRegs,
			"pending_withdrawals": pendingWithdrawals,
			"pending_talangan":    pendingTalangan,
			"platform_revenue":    platformRevenue,
		},
	})
}

func (s *Server) handleAdminMap(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	ctx := r.Context()

	var points []map[string]any

	dRows, err := s.db.QueryContext(ctx, `
		SELECT d.id, u.name, d.vehicle_type, d.vehicle_brand, d.vehicle_plate, d.is_online,
		       COALESCE(d.last_lat, 5.2039), COALESCE(d.last_lng, 97.0642), d.rating_avg
		FROM drivers d
		JOIN users u ON u.id = d.user_id
		WHERE u.status = 'ACTIVE'
	`)
	if err == nil {
		defer dRows.Close()
		for dRows.Next() {
			var (
				id, name, vType, vBrand, vPlate string
				isOnline                        int
				lat, lng, rating                float64
			)
			if dRows.Scan(&id, &name, &vType, &vBrand, &vPlate, &isOnline, &lat, &lng, &rating) == nil {
				stLabel := "Offline"
				if isOnline == 1 {
					stLabel = "Online"
				}
				points = append(points, map[string]any{
					"id":           id,
					"name":         name,
					"kind":         "driver",
					"vehicle_type": vType,
					"city":         "Lhokseumawe & Aceh Utara",
					"status":       stLabel,
					"latitude":     lat,
					"longitude":    lng,
					"detail":       fmt.Sprintf("%s · %s (%s) · ★%.2f", vType, vBrand, vPlate, rating),
				})
			}
		}
	}

	sRows, err := s.db.QueryContext(ctx, `
		SELECT st.id, st.store_name, st.category, st.address, st.lat, st.lng, st.is_open, st.rating_avg
		FROM stores st
		JOIN users u ON u.id = st.user_id
		WHERE u.status = 'ACTIVE'
	`)
	if err == nil {
		defer sRows.Close()
		for sRows.Next() {
			var (
				id, name, cat, addr string
				lat, lng, rating    float64
				isOpen              int
			)
			if sRows.Scan(&id, &name, &cat, &addr, &lat, &lng, &isOpen, &rating) == nil {
				stLabel := "Tutup"
				if isOpen == 1 {
					stLabel = "Buka"
				}
				points = append(points, map[string]any{
					"id":        id,
					"name":      name,
					"kind":      "store",
					"city":      addr,
					"status":    stLabel,
					"latitude":  lat,
					"longitude": lng,
					"detail":    fmt.Sprintf("%s · ★%.2f", cat, rating),
				})
			}
		}
	}
	if points == nil {
		points = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"points": points})
}

func (s *Server) handleAdminRegistrations(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	rows, err := s.db.QueryContext(r.Context(), `
		SELECT r.id, r.user_id, u.name, COALESCE(u.email, ''), COALESCE(u.phone, ''),
		       r.applicant_role, r.status, r.payload_json, COALESCE(r.rejection_reason, ''), r.created_at
		FROM registrations r
		JOIN users u ON u.id = r.user_id
		ORDER BY FIELD(r.status, 'PENDING', 'APPROVED', 'REJECTED'), r.created_at DESC
	`)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var (
			id, uID, name, email, phone, role, st, payloadStr, rejReason string
			createdAt                                                    time.Time
		)
		if rows.Scan(&id, &uID, &name, &email, &phone, &role, &st, &payloadStr, &rejReason, &createdAt) == nil {
			var payload map[string]any
			_ = json.Unmarshal([]byte(payloadStr), &payload)
			if payload == nil {
				payload = map[string]any{}
			}
			list = append(list, map[string]any{
				"id":               id,
				"user_id":          uID,
				"name":             name,
				"email":            email,
				"phone":            phone,
				"applicant_role":   role,
				"status":           st,
				"payload":          payload,
				"rejection_reason": rejReason,
				"created_at":       createdAt.Format(time.RFC3339),
			})
		}
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"registrations": list})
}

func (s *Server) handleAdminRegistrationAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/registrations/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "registration id and action are required"})
		return
	}
	regID := parts[0]
	action := parts[1]

	claims, _ := s.extractClaims(r)
	adminID := "00000000-0000-4000-8000-000000000001"
	if claims != nil && claims.UserID != "" {
		adminID = claims.UserID
	}

	var userID, applicantRole string
	err := s.db.QueryRowContext(r.Context(), `
		SELECT user_id, applicant_role FROM registrations WHERE id = ?
	`, regID).Scan(&userID, &applicantRole)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Registration not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	switch action {
	case "approve":
		_, _ = s.db.ExecContext(r.Context(), `
			UPDATE registrations SET status = 'APPROVED', reviewed_by = ?, reviewed_at = NOW(), rejection_reason = NULL WHERE id = ?
		`, adminID, regID)
		_, _ = s.db.ExecContext(r.Context(), `UPDATE users SET status = 'ACTIVE' WHERE id = ?`, userID)
		if applicantRole == "DRIVER" {
			_, _ = s.db.ExecContext(r.Context(), `UPDATE drivers SET approved_by = ?, approved_at = NOW(), is_online = 1 WHERE user_id = ?`, adminID, userID)
		} else if applicantRole == "STORE" {
			_, _ = s.db.ExecContext(r.Context(), `UPDATE stores SET approved_by = ?, approved_at = NOW(), is_open = 1 WHERE user_id = ?`, adminID, userID)
		}
		s.notifyUserAsync(
			userID,
			"Akun Mitra RideOn Disetujui",
			fmt.Sprintf("Pendaftaran mitra %s Anda telah disetujui Admin.", applicantRole),
			"Pendaftaran Mitra RideOn Disetujui",
			fmt.Sprintf("<p>Selamat! Pendaftaran mitra <strong>%s</strong> Anda telah disetujui oleh Admin RideOn. Anda sekarang dapat mulai menerima pesanan.</p>", applicantRole),
		)
		writeJSON(w, http.StatusOK, map[string]any{"id": regID, "user_id": userID, "status": "APPROVED"})

	case "reject":
		var body struct {
			Reason string `json:"reason"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		if strings.TrimSpace(body.Reason) == "" {
			body.Reason = "Dokumen pendaftaran belum lengkap atau tidak sesuai."
		}
		_, _ = s.db.ExecContext(r.Context(), `
			UPDATE registrations SET status = 'REJECTED', rejection_reason = ?, reviewed_by = ?, reviewed_at = NOW() WHERE id = ?
		`, body.Reason, adminID, regID)
		_, _ = s.db.ExecContext(r.Context(), `UPDATE users SET status = 'REJECTED' WHERE id = ?`, userID)
		s.notifyUserAsync(
			userID,
			"Pendaftaran Mitra Ditolak",
			body.Reason,
			"Informasi Pendaftaran Mitra RideOn",
			fmt.Sprintf("<p>Mohon maaf, pendaftaran mitra Anda belum dapat disetujui dengan alasan:</p><blockquote>%s</blockquote>", body.Reason),
		)
		writeJSON(w, http.StatusOK, map[string]any{"id": regID, "user_id": userID, "status": "REJECTED", "reason": body.Reason})

	default:
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Unknown registration action"})
	}
}

func (s *Server) handleAdminOrders(w http.ResponseWriter, r *http.Request) {
	s.handleListOrders(w, r)
}

func (s *Server) handleAdminDrivers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	rows, err := s.db.QueryContext(r.Context(), `
		SELECT d.id, d.user_id, u.name, COALESCE(u.email, ''), COALESCE(u.phone, ''), u.status,
		       d.vehicle_type, d.vehicle_brand, d.vehicle_plate, COALESCE(d.ktp_number, ''), COALESCE(d.sim_number, ''),
		       d.is_online, d.cash_float_amount, d.rating_avg, d.total_trips, COALESCE(w.balance, 0), d.created_at
		FROM drivers d
		JOIN users u ON u.id = d.user_id
		LEFT JOIN wallets w ON w.owner_type = 'DRIVER' AND w.owner_id = d.id
		ORDER BY d.created_at DESC
	`)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var (
			id, uID, name, email, phone, uStat, vType, vBrand, vPlate, ktp, sim string
			isOnline, totalTrips                                                int
			cashFloat, balance                                                  int64
			ratingAvg                                                           float64
			createdAt                                                           time.Time
		)
		if rows.Scan(&id, &uID, &name, &email, &phone, &uStat, &vType, &vBrand, &vPlate, &ktp, &sim, &isOnline, &cashFloat, &ratingAvg, &totalTrips, &balance, &createdAt) == nil {
			list = append(list, map[string]any{
				"id":                id,
				"user_id":           uID,
				"name":              name,
				"email":             email,
				"phone":             phone,
				"user_status":       uStat,
				"vehicle_type":      vType,
				"vehicle_brand":     vBrand,
				"vehicle_plate":     vPlate,
				"ktp_number":        ktp,
				"sim_number":        sim,
				"is_online":         isOnline == 1,
				"cash_float_amount": cashFloat,
				"rating_avg":        ratingAvg,
				"total_trips":       totalTrips,
				"wallet_balance":    balance,
				"created_at":        createdAt.Format(time.RFC3339),
			})
		}
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"drivers": list})
}

func (s *Server) handleAdminDriverAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch && r.Method != http.MethodPut && r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/drivers/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "driver id is required"})
		return
	}
	driverID := parts[0]

	var body struct {
		Status   *string `json:"status"`
		IsOnline *bool   `json:"is_online"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	var userID string
	_ = s.db.QueryRowContext(r.Context(), `SELECT user_id FROM drivers WHERE id = ?`, driverID).Scan(&userID)
	if body.Status != nil && userID != "" {
		st := strings.ToUpper(strings.TrimSpace(*body.Status))
		_, _ = s.db.ExecContext(r.Context(), `UPDATE users SET status = ? WHERE id = ?`, st, userID)
	}
	if body.IsOnline != nil {
		val := 0
		if *body.IsOnline {
			val = 1
		}
		_, _ = s.db.ExecContext(r.Context(), `UPDATE drivers SET is_online = ? WHERE id = ?`, val, driverID)
	}
	writeJSON(w, http.StatusOK, map[string]any{"id": driverID, "updated": true})
}

func (s *Server) handleAdminStores(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	rows, err := s.db.QueryContext(r.Context(), `
		SELECT st.id, st.user_id, st.store_name, u.name AS owner_name, COALESCE(u.email, ''), COALESCE(u.phone, ''),
		       u.status, st.category, st.address, st.lat, st.lng, st.is_open, st.open_time, st.close_time,
		       st.rating_avg, COALESCE(w.balance, 0),
		       (SELECT COUNT(*) FROM store_menus m WHERE m.store_id = st.id) AS menu_count,
		       st.created_at
		FROM stores st
		JOIN users u ON u.id = st.user_id
		LEFT JOIN wallets w ON w.owner_type = 'STORE' AND w.owner_id = st.id
		ORDER BY st.created_at DESC
	`)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var (
			id, uID, sName, oName, email, phone, uStat, cat, addr, openT, closeT string
			lat, lng, ratingAvg                                                  float64
			isOpen, menuCount                                                    int
			balance                                                              int64
			createdAt                                                            time.Time
		)
		if rows.Scan(&id, &uID, &sName, &oName, &email, &phone, &uStat, &cat, &addr, &lat, &lng, &isOpen, &openT, &closeT, &ratingAvg, &balance, &menuCount, &createdAt) == nil {
			list = append(list, map[string]any{
				"id":             id,
				"user_id":        uID,
				"store_name":     sName,
				"owner_name":     oName,
				"email":          email,
				"phone":          phone,
				"user_status":    uStat,
				"category":       cat,
				"address":        addr,
				"lat":            lat,
				"lng":            lng,
				"is_open":        isOpen == 1,
				"open_time":      openT,
				"close_time":     closeT,
				"rating_avg":     ratingAvg,
				"wallet_balance": balance,
				"menu_count":     menuCount,
				"created_at":     createdAt.Format(time.RFC3339),
			})
		}
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"stores": list})
}

func (s *Server) handleAdminStoreAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch && r.Method != http.MethodPut && r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/stores/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "store id is required"})
		return
	}
	storeID := parts[0]
	var body struct {
		Status *string `json:"status"`
		IsOpen *bool   `json:"is_open"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	var userID string
	_ = s.db.QueryRowContext(r.Context(), `SELECT user_id FROM stores WHERE id = ?`, storeID).Scan(&userID)
	if body.Status != nil && userID != "" {
		st := strings.ToUpper(strings.TrimSpace(*body.Status))
		_, _ = s.db.ExecContext(r.Context(), `UPDATE users SET status = ? WHERE id = ?`, st, userID)
	}
	if body.IsOpen != nil {
		val := 0
		if *body.IsOpen {
			val = 1
		}
		_, _ = s.db.ExecContext(r.Context(), `UPDATE stores SET is_open = ? WHERE id = ?`, val, storeID)
	}
	writeJSON(w, http.StatusOK, map[string]any{"id": storeID, "updated": true})
}

func (s *Server) handleAdminCustomers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	rows, err := s.db.QueryContext(r.Context(), `
		SELECT u.id, u.name, COALESCE(u.email, ''), COALESCE(u.phone, ''), u.status,
		       COALESCE(w.balance, 0),
		       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = u.id) AS order_count,
		       u.created_at
		FROM users u
		LEFT JOIN wallets w ON w.owner_type = 'CUSTOMER' AND w.owner_id = u.id
		WHERE u.role = 'CUSTOMER'
		ORDER BY u.created_at DESC
	`)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var (
			id, name, email, phone, st string
			balance                    int64
			orderCount                 int
			createdAt                  time.Time
		)
		if rows.Scan(&id, &name, &email, &phone, &st, &balance, &orderCount, &createdAt) == nil {
			list = append(list, map[string]any{
				"id":             id,
				"name":           name,
				"email":          email,
				"phone":          phone,
				"status":         st,
				"wallet_balance": balance,
				"order_count":    orderCount,
				"created_at":     createdAt.Format(time.RFC3339),
			})
		}
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"customers": list})
}

func (s *Server) handleAdminFinance(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	ctx := r.Context()

	// 1. Withdrawals
	var withdrawals []map[string]any
	wRows, err := s.db.QueryContext(ctx, `
		SELECT wd.id, wd.wallet_id, w.owner_type, wd.requester_user_id, u.name,
		       wd.amount, wd.admin_fee, wd.net_amount, wd.bank_name, wd.bank_account_number,
		       wd.bank_account_holder, wd.status, COALESCE(wd.transfer_proof_url, ''),
		       COALESCE(wd.admin_notes, ''), wd.created_at
		FROM withdrawals wd
		JOIN wallets w ON w.id = wd.wallet_id
		JOIN users u ON u.id = wd.requester_user_id
		ORDER BY wd.created_at DESC LIMIT 50
	`)
	if err == nil {
		defer wRows.Close()
		for wRows.Next() {
			var (
				id, wID, oType, uID, uName, bName, bAcc, bHold, st, proof, notes string
				amt, fee, net                                                    int64
				createdAt                                                        time.Time
			)
			if wRows.Scan(&id, &wID, &oType, &uID, &uName, &amt, &fee, &net, &bName, &bAcc, &bHold, &st, &proof, &notes, &createdAt) == nil {
				withdrawals = append(withdrawals, map[string]any{
					"id":                  id,
					"wallet_id":           wID,
					"owner_type":          oType,
					"requester_user_id":   uID,
					"requester_name":      uName,
					"amount":              amt,
					"admin_fee":           fee,
					"net_amount":          net,
					"bank_name":           bName,
					"bank_account_number": bAcc,
					"bank_account_holder": bHold,
					"status":              st,
					"transfer_proof_url":  proof,
					"admin_notes":         notes,
					"created_at":          createdAt.Format(time.RFC3339),
				})
			}
		}
	}
	if withdrawals == nil {
		withdrawals = []map[string]any{}
	}

	// 2. Talangan Claims
	var claims []map[string]any
	cRows, err := s.db.QueryContext(ctx, `
		SELECT tc.id, tc.order_id, o.order_code, tc.driver_id, u.name AS driver_name,
		       tc.claimed_amount, tc.goods_photo_url, tc.receipt_photo_url, tc.status,
		       COALESCE(tc.orphanage_name, ''), COALESCE(tc.donation_photo_url, ''),
		       COALESCE(tc.admin_notes, ''), tc.created_at
		FROM talangan_claims tc
		JOIN orders o ON o.id = tc.order_id
		JOIN drivers d ON d.id = tc.driver_id
		JOIN users u ON u.id = d.user_id
		ORDER BY tc.created_at DESC LIMIT 50
	`)
	if err == nil {
		defer cRows.Close()
		for cRows.Next() {
			var (
				id, oID, oCode, dID, dName, gPhoto, rPhoto, st, orph, dPhoto, notes string
				amt                                                                 int64
				createdAt                                                           time.Time
			)
			if cRows.Scan(&id, &oID, &oCode, &dID, &dName, &amt, &gPhoto, &rPhoto, &st, &orph, &dPhoto, &notes, &createdAt) == nil {
				claims = append(claims, map[string]any{
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
					"admin_notes":        notes,
					"created_at":         createdAt.Format(time.RFC3339),
				})
			}
		}
	}
	if claims == nil {
		claims = []map[string]any{}
	}

	// 3. QRIS Transactions
	var qrisTxs []map[string]any
	qRows, err := s.db.QueryContext(ctx, `
		SELECT q.id, q.reference_id, q.purpose, COALESCE(q.order_id, ''), q.user_id, u.name,
		       q.amount, q.status, q.expires_at, q.paid_at, q.created_at
		FROM qris_transactions q
		JOIN users u ON u.id = q.user_id
		ORDER BY q.created_at DESC LIMIT 50
	`)
	if err == nil {
		defer qRows.Close()
		for qRows.Next() {
			var (
				id, refID, purp, oID, uID, uName, st string
				amt                                  int64
				expAt, createdAt                     time.Time
				paidAt                               sql.NullTime
			)
			if qRows.Scan(&id, &refID, &purp, &oID, &uID, &uName, &amt, &st, &expAt, &paidAt, &createdAt) == nil {
				var pStr any
				if paidAt.Valid {
					pStr = paidAt.Time.Format(time.RFC3339)
				}
				qrisTxs = append(qrisTxs, map[string]any{
					"id":           id,
					"reference_id": refID,
					"purpose":      purp,
					"order_id":     oID,
					"user_id":      uID,
					"user_name":    uName,
					"amount":       amt,
					"status":       st,
					"expires_at":   expAt.Format(time.RFC3339),
					"paid_at":      pStr,
					"created_at":   createdAt.Format(time.RFC3339),
				})
			}
		}
	}
	if qrisTxs == nil {
		qrisTxs = []map[string]any{}
	}

	// 4. Wallet Transactions
	var walletTxs []map[string]any
	wtRows, err := s.db.QueryContext(ctx, `
		SELECT wt.id, wt.wallet_id, w.owner_type, w.owner_id, wt.tx_type,
		       wt.amount, wt.balance_before, wt.balance_after,
		       COALESCE(wt.reference_type, ''), COALESCE(wt.reference_id, ''),
		       wt.description, wt.created_at
		FROM wallet_transactions wt
		JOIN wallets w ON w.id = wt.wallet_id
		ORDER BY wt.created_at DESC LIMIT 80
	`)
	if err == nil {
		defer wtRows.Close()
		for wtRows.Next() {
			var (
				id, wID, oType, oID, txType, rType, rID, desc string
				amt, bBef, bAft                               int64
				createdAt                                     time.Time
			)
			if wtRows.Scan(&id, &wID, &oType, &oID, &txType, &amt, &bBef, &bAft, &rType, &rID, &desc, &createdAt) == nil {
				walletTxs = append(walletTxs, map[string]any{
					"id":             id,
					"wallet_id":      wID,
					"owner_type":     oType,
					"owner_id":       oID,
					"tx_type":        txType,
					"amount":         amt,
					"balance_before": bBef,
					"balance_after":  bAft,
					"reference_type": rType,
					"reference_id":   rID,
					"description":    desc,
					"created_at":     createdAt.Format(time.RFC3339),
				})
			}
		}
	}
	if walletTxs == nil {
		walletTxs = []map[string]any{}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"withdrawals":         withdrawals,
		"talangan_claims":     claims,
		"qris_transactions":   qrisTxs,
		"wallet_transactions": walletTxs,
	})
}

func (s *Server) handleAdminWithdrawalAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/withdrawals/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "withdrawal id and action are required"})
		return
	}
	wdID := parts[0]
	action := parts[1]

	claims, _ := s.extractClaims(r)
	adminID := "00000000-0000-4000-8000-000000000001"
	if claims != nil && claims.UserID != "" {
		adminID = claims.UserID
	}

	var body struct {
		TransferProofURL string `json:"transfer_proof_url"`
		AdminNotes       string `json:"admin_notes"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	tx, err := s.db.BeginTx(r.Context(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	var (
		walletID, requesterUserID, status string
		amount                            int64
	)
	err = tx.QueryRowContext(r.Context(), `
		SELECT wallet_id, requester_user_id, amount, status FROM withdrawals WHERE id = ? FOR UPDATE
	`, wdID).Scan(&walletID, &requesterUserID, &amount, &status)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Withdrawal not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	if status != "PENDING" {
		writeJSON(w, http.StatusConflict, map[string]any{"error": "Withdrawal already processed"})
		return
	}

	if action == "approve" {
		_, err = tx.ExecContext(r.Context(), `
			UPDATE withdrawals
			SET status = 'APPROVED', transfer_proof_url = ?, admin_notes = ?, processed_by = ?, processed_at = NOW()
			WHERE id = ?
		`, body.TransferProofURL, body.AdminNotes, adminID, wdID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		_ = tx.Commit()
		s.notifyUserAsync(
			requesterUserID,
			"Penarikan Saldo Disetujui",
			fmt.Sprintf("Penarikan Rp %d telah ditransfer oleh Admin.", amount),
			"Penarikan Saldo RideOn Disetujui",
			fmt.Sprintf("<p>Pengajuan penarikan saldo sebesar <strong>Rp %d</strong> telah disetujui dan diproses oleh Admin RideOn.</p>", amount),
		)
		writeJSON(w, http.StatusOK, map[string]any{"id": wdID, "status": "APPROVED"})
		return
	}

	if action == "reject" {
		var balBefore int64
		if err := tx.QueryRowContext(r.Context(), `SELECT balance FROM wallets WHERE id = ? FOR UPDATE`, walletID).Scan(&balBefore); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		afterBal := balBefore + amount
		_, _ = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, walletID)
		_, _ = tx.ExecContext(r.Context(), `
			UPDATE withdrawals
			SET status = 'REJECTED', admin_notes = ?, processed_by = ?, processed_at = NOW()
			WHERE id = ?
		`, body.AdminNotes, adminID, wdID)
		_, _ = tx.ExecContext(r.Context(), `
			INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
			VALUES (?, ?, 'MANUAL_ADJUST', ?, ?, ?, 'WITHDRAWAL', ?, 'Pengembalian Saldo Penarikan Ditolak Admin')
		`, newUUIDv4(), walletID, amount, balBefore, afterBal, wdID)
		_ = tx.Commit()
		s.notifyUserAsync(
			requesterUserID,
			"Penarikan Saldo Ditolak",
			"Saldo Anda telah dikembalikan ke dompet RideOn.",
			"Penarikan Saldo RideOn Ditolak",
			fmt.Sprintf("<p>Pengajuan penarikan saldo Anda ditolak (%s). Dana sebesar <strong>Rp %d</strong> telah dikembalikan ke saldo dompet Anda.</p>", body.AdminNotes, amount),
		)
		writeJSON(w, http.StatusOK, map[string]any{"id": wdID, "status": "REJECTED", "refunded_amount": amount})
		return
	}

	writeJSON(w, http.StatusNotFound, map[string]any{"error": "Unknown withdrawal action"})
}

func (s *Server) handleAdminTalanganAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/talangan-claims/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "claim id and action are required"})
		return
	}
	claimID := parts[0]
	action := parts[1]

	claims, _ := s.extractClaims(r)
	adminID := "00000000-0000-4000-8000-000000000001"
	if claims != nil && claims.UserID != "" {
		adminID = claims.UserID
	}

	var body struct {
		AdminNotes string `json:"admin_notes"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	switch action {
	case "approve-step1":
		_, err := s.db.ExecContext(r.Context(), `
			UPDATE talangan_claims
			SET status = 'APPROVED_FOR_DONATION', admin_notes = ?, reviewed_by = ?, step1_approved_at = NOW()
			WHERE id = ?
		`, body.AdminNotes, adminID, claimID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"id": claimID, "status": "APPROVED_FOR_DONATION"})

	case "reimburse":
		tx, err := s.db.BeginTx(r.Context(), nil)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer tx.Rollback()

		var (
			driverID, status string
			claimedAmount    int64
		)
		err = tx.QueryRowContext(r.Context(), `
			SELECT driver_id, claimed_amount, status FROM talangan_claims WHERE id = ? FOR UPDATE
		`, claimID).Scan(&driverID, &claimedAmount, &status)
		if errors.Is(err, sql.ErrNoRows) {
			writeJSON(w, http.StatusNotFound, map[string]any{"error": "Talangan claim not found"})
			return
		}
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		if status == "COMPLETED_REIMBURSED" {
			_ = tx.Commit()
			writeJSON(w, http.StatusOK, map[string]any{"id": claimID, "status": "COMPLETED_REIMBURSED", "idempotent": true})
			return
		}

		walletID, balBefore, wErr := s.getOrCreateWalletTx(r.Context(), tx, "DRIVER", driverID)
		if wErr != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": wErr.Error()})
			return
		}
		afterBal := balBefore + claimedAmount
		_, _ = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, walletID)
		_, _ = tx.ExecContext(r.Context(), `
			UPDATE talangan_claims
			SET status = 'COMPLETED_REIMBURSED', admin_notes = ?, reviewed_by = ?, reimbursed_at = NOW()
			WHERE id = ?
		`, body.AdminNotes, adminID, claimID)
		_, _ = tx.ExecContext(r.Context(), `
			INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
			VALUES (?, ?, 'TALANGAN_REIMBURSE', ?, ?, ?, 'TALANGAN_CLAIM', ?, 'Penggantian Klaim Talangan Donasi Panti Asuhan')
		`, newUUIDv4(), walletID, claimedAmount, balBefore, afterBal, claimID)
		var drvUserID string
		_ = tx.QueryRowContext(r.Context(), `SELECT user_id FROM drivers WHERE id = ?`, driverID).Scan(&drvUserID)
		_ = tx.Commit()

		s.notifyUserAsync(
			drvUserID,
			"Klaim Talangan Diganti",
			fmt.Sprintf("Penggantian talangan Rp %d telah dikreditkan ke dompet Anda.", claimedAmount),
			"Penggantian Klaim Talangan RideOn",
			fmt.Sprintf("<p>Terima kasih atas amanah donasi Anda. Dana talangan sebesar <strong>Rp %d</strong> telah dikreditkan ke dompet driver Anda.</p>", claimedAmount),
		)
		writeJSON(w, http.StatusOK, map[string]any{
			"id":                    claimID,
			"status":                "COMPLETED_REIMBURSED",
			"reimbursed_amount":     claimedAmount,
			"driver_wallet_balance": afterBal,
		})

	case "reject":
		_, err := s.db.ExecContext(r.Context(), `
			UPDATE talangan_claims SET status = 'REJECTED', admin_notes = ?, reviewed_by = ? WHERE id = ?
		`, body.AdminNotes, adminID, claimID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"id": claimID, "status": "REJECTED"})

	default:
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Unknown talangan action"})
	}
}

func (s *Server) handleAdminSettings(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		rows, err := s.db.QueryContext(r.Context(), "SELECT `key`, `value` FROM system_settings ORDER BY `key` ASC")
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()
		settings := map[string]string{}
		for rows.Next() {
			var k, v string
			if rows.Scan(&k, &v) == nil {
				settings[k] = v
			}
		}
		writeJSON(w, http.StatusOK, map[string]any{"settings": settings})

	case http.MethodPut:
		var in map[string]any
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		// Accept either {"settings": {...}} or flat key-value object
		if nested, ok := in["settings"].(map[string]any); ok {
			in = nested
		}
		for k, rawV := range in {
			key := strings.TrimSpace(k)
			if key == "" {
				continue
			}
			var valStr string
			switch v := rawV.(type) {
			case string:
				valStr = v
			case float64:
				valStr = strconv.FormatInt(int64(v), 10)
			default:
				valStr = fmt.Sprintf("%v", v)
			}
			_, _ = s.db.ExecContext(r.Context(), "INSERT INTO system_settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)", key, valStr)
		}
		writeJSON(w, http.StatusOK, map[string]any{"updated": true})

	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
	}
}

func (s *Server) handleAdminPricingRules(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	rows, err := s.db.QueryContext(r.Context(), `
		SELECT id, service_type, base_fare, per_km_fare, min_fare, driver_commission_pct, store_commission_pct, platform_fee_fixed, is_active
		FROM pricing_rules ORDER BY service_type ASC
	`)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var (
			id, sType                     string
			base, perKm, minF, platFixed int64
			dPct, sPct                    float64
			isActive                      int
		)
		if rows.Scan(&id, &sType, &base, &perKm, &minF, &dPct, &sPct, &platFixed, &isActive) == nil {
			list = append(list, map[string]any{
				"id":                    id,
				"service_type":          sType,
				"base_fare":             base,
				"per_km_fare":           perKm,
				"min_fare":              minF,
				"driver_commission_pct": dPct,
				"store_commission_pct":  sPct,
				"platform_fee_fixed":    platFixed,
				"is_active":             isActive == 1,
			})
		}
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"pricing_rules": list})
}

func (s *Server) handleAdminPricingRuleByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	id := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/pricing-rules/"), "/")
	var in struct {
		BaseFare            *int64   `json:"base_fare"`
		PerKmFare           *int64   `json:"per_km_fare"`
		MinFare             *int64   `json:"min_fare"`
		DriverCommissionPct *float64 `json:"driver_commission_pct"`
		StoreCommissionPct  *float64 `json:"store_commission_pct"`
		PlatformFeeFixed    *int64   `json:"platform_fee_fixed"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	if in.BaseFare != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE pricing_rules SET base_fare = ? WHERE id = ? OR service_type = ?`, *in.BaseFare, id, id)
	}
	if in.PerKmFare != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE pricing_rules SET per_km_fare = ? WHERE id = ? OR service_type = ?`, *in.PerKmFare, id, id)
	}
	if in.MinFare != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE pricing_rules SET min_fare = ? WHERE id = ? OR service_type = ?`, *in.MinFare, id, id)
	}
	if in.DriverCommissionPct != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE pricing_rules SET driver_commission_pct = ? WHERE id = ? OR service_type = ?`, *in.DriverCommissionPct, id, id)
	}
	if in.StoreCommissionPct != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE pricing_rules SET store_commission_pct = ? WHERE id = ? OR service_type = ?`, *in.StoreCommissionPct, id, id)
	}
	if in.PlatformFeeFixed != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE pricing_rules SET platform_fee_fixed = ? WHERE id = ? OR service_type = ?`, *in.PlatformFeeFixed, id, id)
	}
	writeJSON(w, http.StatusOK, map[string]any{"id": id, "updated": true})
}

func (s *Server) handleAdminSupportTicketReply(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/admin/support-tickets/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "ticket id and reply action are required"})
		return
	}
	ticketID := parts[0]

	var body struct {
		Reply  string `json:"reply"`
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	if strings.TrimSpace(body.Reply) == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "reply text is required"})
		return
	}
	st := strings.ToUpper(strings.TrimSpace(body.Status))
	if st != "IN_PROGRESS" && st != "CLOSED" {
		st = "RESOLVED"
	}

	claims, _ := s.extractClaims(r)
	adminID := "00000000-0000-4000-8000-000000000001"
	if claims != nil && claims.UserID != "" {
		adminID = claims.UserID
	}

	var senderContact, subject string
	_ = s.db.QueryRowContext(r.Context(), `SELECT sender_contact, subject FROM support_tickets WHERE id = ?`, ticketID).Scan(&senderContact, &subject)

	_, err := s.db.ExecContext(r.Context(), `
		UPDATE support_tickets
		SET admin_reply = ?, status = ?, replied_by = ?, replied_at = NOW()
		WHERE id = ?
	`, strings.TrimSpace(body.Reply), st, adminID, ticketID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	emailProvider := "none"
	if strings.Contains(senderContact, "@") {
		html := fmt.Sprintf(`<p>Halo,</p><p>Berikut balasan dari <strong>Tim Bantuan RideOn</strong> atas laporan Anda (<em>%s</em>):</p><blockquote>%s</blockquote><p>Anda dapat membalas email ini secara langsung jika masih memerlukan bantuan.</p>`,
			subject, strings.TrimSpace(body.Reply))
		emailProvider, _ = s.sendEmailMessage(senderContact, "Re: "+subject+" [Tiket Bantuan RideOn]", html)
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"id":             ticketID,
		"status":         st,
		"admin_reply":    body.Reply,
		"email_provider": emailProvider,
	})
}

