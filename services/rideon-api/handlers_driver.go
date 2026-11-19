package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

func (s *Server) handleDriverSubtree(w http.ResponseWriter, r *http.Request) {
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/drivers/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "driver id is required"})
		return
	}
	driverID := parts[0]

	if len(parts) == 1 && r.Method == http.MethodGet {
		s.handleGetDriverProfile(w, r, driverID)
		return
	}
	if len(parts) == 2 && parts[1] == "status" && (r.Method == http.MethodPatch || r.Method == http.MethodPut || r.Method == http.MethodPost) {
		s.handleUpdateDriverStatus(w, r, driverID)
		return
	}
	writeJSON(w, http.StatusNotFound, map[string]any{"error": "Endpoint not found"})
}

func (s *Server) handleGetDriverProfile(w http.ResponseWriter, r *http.Request, driverID string) {
	var (
		id, userID, name, email, phone, userStatus, vType, vBrand, vPlate string
		isOnline, totalTrips                                               int
		cashFloat, walletBal                                               int64
		ratingAvg, lastLat, lastLng                                        float64
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT d.id, d.user_id, u.name, COALESCE(u.email, ''), COALESCE(u.phone, ''), u.status,
		       d.vehicle_type, d.vehicle_brand, d.vehicle_plate,
		       d.is_online, d.cash_float_amount, COALESCE(d.last_lat, 5.2039), COALESCE(d.last_lng, 97.0642),
		       d.rating_avg, d.total_trips, COALESCE(w.balance, 0)
		FROM drivers d
		JOIN users u ON u.id = d.user_id
		LEFT JOIN wallets w ON w.owner_type = 'DRIVER' AND w.owner_id = d.id
		WHERE d.id = ? OR d.user_id = ?
		LIMIT 1
	`, driverID, driverID).Scan(
		&id, &userID, &name, &email, &phone, &userStatus,
		&vType, &vBrand, &vPlate, &isOnline, &cashFloat, &lastLat, &lastLng,
		&ratingAvg, &totalTrips, &walletBal,
	)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Driver not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"driver": map[string]any{
			"id":                id,
			"user_id":           userID,
			"name":              name,
			"email":             email,
			"phone":             phone,
			"user_status":       userStatus,
			"vehicle_type":      vType,
			"vehicle_brand":     vBrand,
			"vehicle_plate":     vPlate,
			"is_online":         isOnline == 1,
			"cash_float_amount": cashFloat,
			"last_lat":          lastLat,
			"last_lng":          lastLng,
			"rating_avg":        ratingAvg,
			"total_trips":       totalTrips,
			"wallet_balance":    walletBal,
		},
	})
}

func (s *Server) handleUpdateDriverStatus(w http.ResponseWriter, r *http.Request, driverID string) {
	claims, err := s.extractClaims(r)
	if err != nil {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "Unauthorized: " + err.Error()})
		return
	}

	var (
		resolvedDriverID, ownerUserID, userStatus, name, vehicleType, vehiclePlate string
		curOnline                                                                  int
		curCashFloat                                                               int64
		curLat, curLng                                                             float64
	)
	err = s.db.QueryRowContext(r.Context(), `
		SELECT d.id, d.user_id, u.status, u.name, d.vehicle_type, d.vehicle_plate,
		       d.is_online, d.cash_float_amount, COALESCE(d.last_lat, 5.2039), COALESCE(d.last_lng, 97.0642)
		FROM drivers d
		JOIN users u ON u.id = d.user_id
		WHERE d.id = ? OR d.user_id = ?
		LIMIT 1
	`, driverID, driverID).Scan(
		&resolvedDriverID, &ownerUserID, &userStatus, &name, &vehicleType, &vehiclePlate,
		&curOnline, &curCashFloat, &curLat, &curLng,
	)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Driver not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if !strings.EqualFold(claims.Role, "ADMIN") && claims.UserID != ownerUserID {
		writeJSON(w, http.StatusForbidden, map[string]any{"error": "Forbidden: bukan pemilik akun driver"})
		return
	}
	if userStatus != "ACTIVE" {
		writeJSON(w, http.StatusForbidden, map[string]any{
			"error":  "Akun driver masih dalam proses verifikasi Admin",
			"status": userStatus,
		})
		return
	}

	var body struct {
		IsOnline        *bool    `json:"is_online"`
		CashFloatAmount *int64   `json:"cash_float_amount"`
		LastLat         *float64 `json:"last_lat"`
		LastLng         *float64 `json:"last_lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	isOnlineVal := curOnline
	if body.IsOnline != nil {
		if *body.IsOnline {
			isOnlineVal = 1
		} else {
			isOnlineVal = 0
		}
	}
	if body.CashFloatAmount != nil {
		if *body.CashFloatAmount < 0 {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "cash_float_amount cannot be negative"})
			return
		}
		curCashFloat = *body.CashFloatAmount
	}
	if body.LastLat != nil {
		curLat = *body.LastLat
	}
	if body.LastLng != nil {
		curLng = *body.LastLng
	}

	_, err = s.db.ExecContext(r.Context(), `
		UPDATE drivers
		SET is_online = ?, cash_float_amount = ?, last_lat = ?, last_lng = ?
		WHERE id = ?
	`, isOnlineVal, curCashFloat, curLat, curLng, resolvedDriverID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if s.firebase != nil {
		go func(dID, drvName, vType, vPlate string, online bool, lat, lng float64) {
			ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
			defer cancel()
			if !online {
				_ = s.firebase.DeleteRTDB(ctx, "driver_locations/"+dID)
				return
			}
			_ = s.firebase.SetRTDB(ctx, "driver_locations/"+dID, map[string]any{
				"driver_id":     dID,
				"name":          drvName,
				"vehicle_type":  vType,
				"vehicle_plate": vPlate,
				"is_online":     true,
				"lat":           lat,
				"lng":           lng,
				"updated_at":    time.Now().Format(time.RFC3339),
			})
		}(resolvedDriverID, name, vehicleType, vehiclePlate, isOnlineVal == 1, curLat, curLng)
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"id":                resolvedDriverID,
		"is_online":         isOnlineVal == 1,
		"cash_float_amount": curCashFloat,
		"last_lat":          curLat,
		"last_lng":          curLng,
		"status":            userStatus,
	})
}

