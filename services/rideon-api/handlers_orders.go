package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"rideon-api/internal/finance"
)

type orderItemInput struct {
	MenuID    *string `json:"menu_id"`
	ItemName  string  `json:"item_name"`
	UnitPrice int64   `json:"unit_price"`
	Qty       int     `json:"qty"`
	Notes     string  `json:"notes"`
}

type estimateOrderRequest struct {
	ServiceType       string           `json:"service_type"`
	VehicleType       string           `json:"vehicle_type"`
	PickupLat         float64          `json:"pickup_lat"`
	PickupLng         float64          `json:"pickup_lng"`
	DropoffLat        float64          `json:"dropoff_lat"`
	DropoffLng        float64          `json:"dropoff_lng"`
	ItemsSubtotal     int64            `json:"items_subtotal"`
	Items             []orderItemInput `json:"items"`
	TalanganEstAmount int64            `json:"talangan_est_amount"`
	PromoCode         string           `json:"promo_code"`
}

func (s *Server) handleOrderEstimate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	var req estimateOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	serviceType, vehicleType := normalizeServiceAndVehicle(req.ServiceType, req.VehicleType)
	distanceKm, durationMin := s.estimateOSRMDistance(r.Context(), req.PickupLat, req.PickupLng, req.DropoffLat, req.DropoffLng)

	rule, err := s.loadPricingRule(r.Context(), serviceType)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	deliveryFee := finance.ComputeFare(distanceKm, rule.BaseFare, rule.PerKmFare, rule.MinFare, rule.PlatformFeeFixed)
	itemsSubtotal := req.ItemsSubtotal
	if itemsSubtotal == 0 && len(req.Items) > 0 {
		for _, it := range req.Items {
			qty := it.Qty
			if qty <= 0 {
				qty = 1
			}
			itemsSubtotal += it.UnitPrice * int64(qty)
		}
	}

	grossAmount := deliveryFee + itemsSubtotal + req.TalanganEstAmount
	discount := s.calculatePromoDiscount(r.Context(), req.PromoCode, grossAmount)
	totalCustomerPay := grossAmount - discount
	if totalCustomerPay < 0 {
		totalCustomerPay = 0
	}

	split := finance.CalculateCommission5Pct5Pct(deliveryFee, itemsSubtotal, rule.DriverCommissionPct, rule.StoreCommissionPct)

	writeJSON(w, http.StatusOK, map[string]any{
		"service_type":               serviceType,
		"vehicle_type":               vehicleType,
		"distance_km":                distanceKm,
		"duration_min":               durationMin,
		"delivery_fee":               deliveryFee,
		"items_subtotal":             itemsSubtotal,
		"talangan_est_amount":        req.TalanganEstAmount,
		"discount_amount":            discount,
		"total_customer_pay":         totalCustomerPay,
		"platform_commission_driver": split.DriverCommission,
		"platform_commission_store":  split.StoreCommission,
	})
}

type pricingRuleRow struct {
	BaseFare            int64
	PerKmFare           int64
	MinFare             int64
	DriverCommissionPct float64
	StoreCommissionPct  float64
	PlatformFeeFixed    int64
}

func (s *Server) loadPricingRule(ctx context.Context, serviceType string) (pricingRuleRow, error) {
	var row pricingRuleRow
	err := s.db.QueryRowContext(ctx, `
		SELECT base_fare, per_km_fare, min_fare, driver_commission_pct, store_commission_pct, platform_fee_fixed
		FROM pricing_rules WHERE service_type = ? LIMIT 1
	`, serviceType).Scan(&row.BaseFare, &row.PerKmFare, &row.MinFare, &row.DriverCommissionPct, &row.StoreCommissionPct, &row.PlatformFeeFixed)
	if errors.Is(err, sql.ErrNoRows) {
		return pricingRuleRow{BaseFare: 5000, PerKmFare: 2200, MinFare: 8000, DriverCommissionPct: 5.0, StoreCommissionPct: 5.0}, nil
	}
	return row, err
}

func (s *Server) calculatePromoDiscount(ctx context.Context, code string, orderAmount int64) int64 {
	code = strings.ToUpper(strings.TrimSpace(code))
	if code == "" {
		return 0
	}
	var (
		dType                 string
		dVal, minOrd, maxDisc int64
		quota, used, active   int
	)
	err := s.db.QueryRowContext(ctx, `
		SELECT discount_type, discount_value, min_order_amount, COALESCE(max_discount_amount, 0), quota, used_count, is_active
		FROM promotions
		WHERE code = ? AND is_active = 1 AND (end_at IS NULL OR end_at >= NOW())
		LIMIT 1
	`, code).Scan(&dType, &dVal, &minOrd, &maxDisc, &quota, &used, &active)
	if err != nil || active == 0 || orderAmount < minOrd || (quota > 0 && used >= quota) {
		return 0
	}
	var disc int64
	if dType == "PERCENTAGE" {
		disc = (orderAmount * dVal) / 100
	} else {
		disc = dVal
	}
	if maxDisc > 0 && disc > maxDisc {
		disc = maxDisc
	}
	if disc > orderAmount {
		disc = orderAmount
	}
	return disc
}

func normalizeServiceAndVehicle(rawService, rawVehicle string) (string, string) {
	st := strings.ToUpper(strings.TrimSpace(rawService))
	vt := strings.ToUpper(strings.TrimSpace(rawVehicle))
	switch st {
	case "RIDE_MOBIL":
		vt = "MOBIL"
	case "RIDE_MOTOR", "FLEX_FOOD", "FLEX_SEND":
		if vt != "MOBIL" {
			vt = "MOTOR"
		}
	default:
		if vt == "MOBIL" {
			st = "RIDE_MOBIL"
		} else {
			st = "RIDE_MOTOR"
			vt = "MOTOR"
		}
	}
	return st, vt
}

type createOrderRequest struct {
	ServiceType       string           `json:"service_type"`
	CustomerID        string           `json:"customer_id"`
	StoreID           *string          `json:"store_id"`
	VehicleType       string           `json:"vehicle_type"`
	PaymentMethod     string           `json:"payment_method"` // CASH or QRIS
	PickupAddress     string           `json:"pickup_address"`
	PickupLat         float64          `json:"pickup_lat"`
	PickupLng         float64          `json:"pickup_lng"`
	DropoffAddress    string           `json:"dropoff_address"`
	DropoffLat        float64          `json:"dropoff_lat"`
	DropoffLng        float64          `json:"dropoff_lng"`
	ItemsSubtotal     int64            `json:"items_subtotal"`
	Items             []orderItemInput `json:"items"`
	TalanganEstAmount int64            `json:"talangan_est_amount"`
	PromoCode         string           `json:"promo_code"`
	Notes             string           `json:"notes"`
}

func (s *Server) handleOrders(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		s.handleListOrders(w, r)
	case http.MethodPost:
		s.handleCreateOrder(w, r)
	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
	}
}

func (s *Server) handleListOrders(w http.ResponseWriter, r *http.Request) {
	customerID := strings.TrimSpace(r.URL.Query().Get("customer_id"))
	driverID := strings.TrimSpace(r.URL.Query().Get("driver_id"))
	storeID := strings.TrimSpace(r.URL.Query().Get("store_id"))
	statusParam := strings.TrimSpace(r.URL.Query().Get("status"))
	vehicleType := strings.ToUpper(strings.TrimSpace(r.URL.Query().Get("vehicle_type")))
	availableOnly := strings.EqualFold(strings.TrimSpace(r.URL.Query().Get("available")), "true")

	query := `
		SELECT o.id, o.order_code, o.service_type, o.customer_id, u.name AS customer_name, COALESCE(u.phone, ''),
		       COALESCE(o.driver_id, ''), COALESCE(du.name, ''), COALESCE(o.store_id, ''), COALESCE(st.store_name, ''), COALESCE(st.address, ''),
		       o.vehicle_type, o.status, o.payment_method, o.payment_status,
		       o.pickup_address, o.pickup_lat, o.pickup_lng, o.dropoff_address, o.dropoff_lat, o.dropoff_lng,
		       o.distance_km, o.duration_min, o.delivery_fee, o.items_subtotal,
		       o.talangan_est_amount, o.talangan_actual_amount, o.parking_fee, o.discount_amount,
		       o.platform_commission_driver, o.platform_commission_store, o.total_customer_pay,
		       o.offer_expires_at, o.created_at
		FROM orders o
		JOIN users u ON u.id = o.customer_id
		LEFT JOIN drivers d ON d.id = o.driver_id
		LEFT JOIN users du ON du.id = d.user_id
		LEFT JOIN stores st ON st.id = o.store_id
		WHERE 1=1
	`
	var args []any
	if customerID != "" {
		query += ` AND o.customer_id = ?`
		args = append(args, customerID)
	}
	if driverID != "" {
		query += ` AND o.driver_id = ?`
		args = append(args, driverID)
	}
	if storeID != "" {
		query += ` AND o.store_id = ?`
		args = append(args, storeID)
	}
	if statusParam != "" {
		parts := strings.Split(statusParam, ",")
		var placeholders []string
		for _, p := range parts {
			st := strings.ToUpper(strings.TrimSpace(p))
			if st != "" {
				placeholders = append(placeholders, "?")
				args = append(args, st)
			}
		}
		if len(placeholders) == 1 {
			query += ` AND o.status = ?`
		} else if len(placeholders) > 1 {
			query += ` AND o.status IN (` + strings.Join(placeholders, ",") + `)`
		}
	}
	if vehicleType == "MOTOR" || vehicleType == "MOBIL" {
		query += ` AND o.vehicle_type = ?`
		args = append(args, vehicleType)
	}
	if availableOnly {
		query += ` AND o.status = 'SEARCHING_DRIVER' AND o.driver_id IS NULL`
	}
	query += ` ORDER BY o.created_at DESC LIMIT 100`

	rows, err := s.db.QueryContext(r.Context(), query, args...)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var list []map[string]any
	var orderIDs []string
	for rows.Next() {
		var (
			id, code, sType, cID, cName, cPhone, dID, dName, stID, stName, stAddr, vType, st, pMethod, pStat string
			pAddr, dAddr                                                                                     string
			pLat, pLng, dLat, dLng, distKm                                                                   float64
			durMin                                                                                           int
			delFee, itSub, talEst, talAct, parkFee, disc, commDrv, commSt, totalPay                          int64
			offerExp                                                                                         sql.NullTime
			createdAt                                                                                        time.Time
		)
		if err := rows.Scan(
			&id, &code, &sType, &cID, &cName, &cPhone, &dID, &dName, &stID, &stName, &stAddr, &vType, &st, &pMethod, &pStat,
			&pAddr, &pLat, &pLng, &dAddr, &dLat, &dLng, &distKm, &durMin, &delFee, &itSub,
			&talEst, &talAct, &parkFee, &disc, &commDrv, &commSt, &totalPay, &offerExp, &createdAt,
		); err != nil {
			continue
		}
		var offerExpStr any
		if offerExp.Valid {
			offerExpStr = offerExp.Time.Format(time.RFC3339)
		}
		orderIDs = append(orderIDs, id)
		list = append(list, map[string]any{
			"id":                         id,
			"order_code":                 code,
			"service_type":               sType,
			"customer_id":                cID,
			"customer_name":              cName,
			"customer_phone":             cPhone,
			"driver_id":                  dID,
			"driver_name":                dName,
			"store_id":                   stID,
			"store_name":                 stName,
			"store_address":              stAddr,
			"vehicle_type":               vType,
			"status":                     st,
			"payment_method":             pMethod,
			"payment_status":             pStat,
			"pickup_address":             pAddr,
			"pickup_lat":                 pLat,
			"pickup_lng":                 pLng,
			"dropoff_address":            dAddr,
			"dropoff_lat":                dLat,
			"dropoff_lng":                dLng,
			"distance_km":                distKm,
			"duration_min":               durMin,
			"delivery_fee":               delFee,
			"items_subtotal":             itSub,
			"talangan_est_amount":        talEst,
			"talangan_actual_amount":     talAct,
			"parking_fee":                parkFee,
			"discount_amount":            disc,
			"platform_commission_driver": commDrv,
			"platform_commission_store":  commSt,
			"total_customer_pay":         totalPay,
			"offer_expires_at":           offerExpStr,
			"created_at":                 createdAt.Format(time.RFC3339),
		})
	}
	rows.Close()
	itemsByOrder := s.fetchOrderItemsMap(r.Context(), orderIDs)
	for _, ord := range list {
		oid, _ := ord["id"].(string)
		if items, ok := itemsByOrder[oid]; ok {
			ord["items"] = items
		} else {
			ord["items"] = []map[string]any{}
		}
	}
	if list == nil {
		list = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"orders": list})
}

func (s *Server) fetchOrderItemsMap(ctx context.Context, orderIDs []string) map[string][]map[string]any {
	out := map[string][]map[string]any{}
	if len(orderIDs) == 0 {
		return out
	}
	placeholders := make([]string, len(orderIDs))
	args := make([]any, len(orderIDs))
	for i, id := range orderIDs {
		placeholders[i] = "?"
		args[i] = id
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, order_id, COALESCE(menu_id, ''), item_name, unit_price, qty, subtotal, COALESCE(notes, '')
		FROM order_items
		WHERE order_id IN (`+strings.Join(placeholders, ",")+`)
	`, args...)
	if err != nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var (
			id, oID, mID, name, notes string
			unitPrice, subtotal       int64
			qty                       int
		)
		if rows.Scan(&id, &oID, &mID, &name, &unitPrice, &qty, &subtotal, &notes) == nil {
			out[oID] = append(out[oID], map[string]any{
				"id":         id,
				"menu_id":    mID,
				"item_name":  name,
				"unit_price": unitPrice,
				"qty":        qty,
				"subtotal":   subtotal,
				"notes":      notes,
			})
		}
	}
	return out
}

func (s *Server) handleCreateOrder(w http.ResponseWriter, r *http.Request) {
	var req createOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	customerID := strings.TrimSpace(req.CustomerID)
	if customerID == "" {
		if claims, err := s.extractClaims(r); err == nil {
			customerID = claims.UserID
		}
	}
	if customerID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "customer_id is required"})
		return
	}

	serviceType, vehicleType := normalizeServiceAndVehicle(req.ServiceType, req.VehicleType)
	payMethod := strings.ToUpper(strings.TrimSpace(req.PaymentMethod))
	if payMethod != "QRIS" {
		payMethod = "CASH"
	}

	if req.PickupLat == 0 {
		req.PickupLat = 5.2041
	}
	if req.PickupLng == 0 {
		req.PickupLng = 97.0638
	}
	if req.DropoffLat == 0 {
		req.DropoffLat = 5.2015
	}
	if req.DropoffLng == 0 {
		req.DropoffLng = 97.0619
	}
	if strings.TrimSpace(req.PickupAddress) == "" {
		req.PickupAddress = "Kampus Bukit Indah, Lhokseumawe"
	}
	if strings.TrimSpace(req.DropoffAddress) == "" {
		req.DropoffAddress = "Blang Pulo, Lhokseumawe"
	}

	distanceKm, durationMin := s.estimateOSRMDistance(r.Context(), req.PickupLat, req.PickupLng, req.DropoffLat, req.DropoffLng)
	rule, err := s.loadPricingRule(r.Context(), serviceType)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	deliveryFee := finance.ComputeFare(distanceKm, rule.BaseFare, rule.PerKmFare, rule.MinFare, rule.PlatformFeeFixed)
	itemsSubtotal := req.ItemsSubtotal
	if itemsSubtotal == 0 && len(req.Items) > 0 {
		for _, it := range req.Items {
			qty := it.Qty
			if qty <= 0 {
				qty = 1
			}
			itemsSubtotal += it.UnitPrice * int64(qty)
		}
	}
	if serviceType != "FLEX_FOOD" {
		storePctZero := 0.0
		rule.StoreCommissionPct = storePctZero
	}

	grossAmount := deliveryFee + itemsSubtotal + req.TalanganEstAmount
	discount := s.calculatePromoDiscount(r.Context(), req.PromoCode, grossAmount)
	totalCustomerPay := grossAmount - discount
	if totalCustomerPay < 0 {
		totalCustomerPay = 0
	}

	split := finance.CalculateCommission5Pct5Pct(deliveryFee, itemsSubtotal, rule.DriverCommissionPct, rule.StoreCommissionPct)

	// FlexFood starts at WAITING_STORE_CONFIRM so store accepts before broadcasting to drivers.
	// FlexRide & FlexSend start directly at SEARCHING_DRIVER with 16-second offer window.
	initialStatus := "SEARCHING_DRIVER"
	offerSec := s.getIntSetting(r.Context(), "driver_offer_seconds", s.offerSeconds)
	var offerExpiresAt any = time.Now().Add(time.Duration(offerSec) * time.Second)
	if serviceType == "FLEX_FOOD" {
		initialStatus = "WAITING_STORE_CONFIRM"
		offerExpiresAt = nil
	}

	payStatus := "UNPAID"
	if payMethod == "QRIS" {
		payStatus = "PENDING"
	}

	orderID := newUUIDv4()
	orderCode := fmt.Sprintf("ORD-%s", strings.ToUpper(orderID[:6]))

	var storeIDVal any = nil
	if req.StoreID != nil && strings.TrimSpace(*req.StoreID) != "" {
		storeIDVal = strings.TrimSpace(*req.StoreID)
	}

	tx, err := s.db.BeginTx(r.Context(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(r.Context(), `
		INSERT INTO orders (
			id, order_code, service_type, customer_id, store_id, vehicle_type,
			status, payment_method, payment_status,
			pickup_address, pickup_lat, pickup_lng, dropoff_address, dropoff_lat, dropoff_lng,
			distance_km, duration_min, delivery_fee, items_subtotal,
			talangan_est_amount, discount_amount,
			platform_commission_driver, platform_commission_store, total_customer_pay,
			notes, promo_code, offer_expires_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`,
		orderID, orderCode, serviceType, customerID, storeIDVal, vehicleType,
		initialStatus, payMethod, payStatus,
		req.PickupAddress, req.PickupLat, req.PickupLng, req.DropoffAddress, req.DropoffLat, req.DropoffLng,
		distanceKm, durationMin, deliveryFee, itemsSubtotal,
		req.TalanganEstAmount, discount,
		split.DriverCommission, split.StoreCommission, totalCustomerPay,
		req.Notes, strings.ToUpper(strings.TrimSpace(req.PromoCode)), offerExpiresAt,
	)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to create order: " + err.Error()})
		return
	}

	for _, it := range req.Items {
		qty := it.Qty
		if qty <= 0 {
			qty = 1
		}
		var mVal any = nil
		if it.MenuID != nil && strings.TrimSpace(*it.MenuID) != "" {
			mVal = strings.TrimSpace(*it.MenuID)
		}
		_, err = tx.ExecContext(r.Context(), `
			INSERT INTO order_items (id, order_id, menu_id, item_name, unit_price, qty, subtotal, notes)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		`, newUUIDv4(), orderID, mVal, it.ItemName, it.UnitPrice, qty, it.UnitPrice*int64(qty), it.Notes)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to insert order item: " + err.Error()})
			return
		}
	}

	if err := tx.Commit(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	// Eligible candidate drivers matching vehicle_type, cash_float_amount (for FLEX_SEND), and negative balance limit (for CASH).
	eligibleDrivers := s.findEligibleDrivers(r.Context(), vehicleType, payMethod, req.TalanganEstAmount)

	resp := map[string]any{
		"id":                         orderID,
		"order_code":                 orderCode,
		"service_type":               serviceType,
		"vehicle_type":               vehicleType,
		"status":                     initialStatus,
		"payment_method":             payMethod,
		"payment_status":             payStatus,
		"distance_km":                distanceKm,
		"duration_min":               durationMin,
		"delivery_fee":               deliveryFee,
		"items_subtotal":             itemsSubtotal,
		"talangan_est_amount":        req.TalanganEstAmount,
		"discount_amount":            discount,
		"platform_commission_driver": split.DriverCommission,
		"platform_commission_store":  split.StoreCommission,
		"total_customer_pay":         totalCustomerPay,
		"eligible_driver_ids":        eligibleDrivers,
	}

	if payMethod == "QRIS" && totalCustomerPay > 0 {
		if qrisData, qErr := s.callPayGGenerate(r.Context(), orderID, customerID, totalCustomerPay); qErr == nil {
			resp["qris"] = qrisData
		}
	}

	s.pingOrderRTDBAsync(orderID, initialStatus, "", req.PickupAddress, req.DropoffAddress, totalCustomerPay, eligibleDrivers)
	writeJSON(w, http.StatusCreated, resp)
}

func (s *Server) findEligibleDrivers(ctx context.Context, vehicleType, payMethod string, talanganEst int64) []string {
	negLimit := s.getInt64Setting(ctx, "driver_negative_balance_limit", s.negativeBalanceLimit)
	minBal := -negLimit

	rows, err := s.db.QueryContext(ctx, `
		SELECT d.id, d.cash_float_amount, COALESCE(w.balance, 0)
		FROM drivers d
		JOIN users u ON u.id = d.user_id
		LEFT JOIN wallets w ON w.owner_type = 'DRIVER' AND w.owner_id = d.id
		WHERE u.status = 'ACTIVE' AND d.is_online = 1 AND d.vehicle_type = ?
	`, vehicleType)
	if err != nil {
		return []string{}
	}
	defer rows.Close()

	var ids []string
	for rows.Next() {
		var (
			id        string
			cashFloat int64
			balance   int64
		)
		if err := rows.Scan(&id, &cashFloat, &balance); err != nil {
			continue
		}
		if payMethod == "CASH" && balance <= minBal {
			continue
		}
		if talanganEst > 0 && cashFloat < talanganEst {
			continue
		}
		ids = append(ids, id)
	}
	if ids == nil {
		ids = []string{}
	}
	return ids
}

func (s *Server) callPayGGenerate(ctx context.Context, orderID, userID string, amount int64) (map[string]any, error) {
	payload, _ := json.Marshal(map[string]any{
		"purpose":  "ORDER_PAYMENT",
		"order_id": orderID,
		"user_id":  userID,
		"amount":   amount,
	})
	client := &http.Client{Timeout: 5 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.paygBaseURL+"/pay/qris/generate", bytes.NewReader(payload))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var out map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *Server) handleOrderSubtree(w http.ResponseWriter, r *http.Request) {
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/orders/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "order id is required"})
		return
	}
	orderID := parts[0]

	if len(parts) == 1 && r.Method == http.MethodGet {
		s.handleGetOrderDetail(w, r, orderID)
		return
	}
	if len(parts) == 2 {
		if parts[1] == "status" && (r.Method == http.MethodPost || r.Method == http.MethodPatch) {
			s.handleUpdateOrderStatus(w, r, orderID)
			return
		}
		if r.Method == http.MethodPost {
			switch parts[1] {
			case "store-confirm":
				s.handleStoreConfirmOrder(w, r, orderID)
			case "store-reject":
				s.handleStoreRejectOrder(w, r, orderID)
			case "accept-driver", "driver-accept":
				s.handleAcceptDriverOrder(w, r, orderID)
			case "driver-reject":
				s.handleRejectDriverOrder(w, r, orderID)
			case "flexsend-receipt":
				s.handleFlexSendReceipt(w, r, orderID)
			case "complete":
				s.handleCompleteOrder(w, r, orderID)
			case "rating":
				s.handleOrderRating(w, r, orderID)
			default:
				writeJSON(w, http.StatusNotFound, map[string]any{"error": "Unknown order action"})
			}
			return
		}
	}
	writeJSON(w, http.StatusNotFound, map[string]any{"error": "Endpoint not found"})
}

func (s *Server) handleGetOrderDetail(w http.ResponseWriter, r *http.Request, orderID string) {
	var (
		id, code, sType, cID, cName, cPhone, dID, stID, stName, vType, st, pMethod, pStat string
		pAddr, dAddr, rPhoto, pPhoto, notes                                               string
		pLat, pLng, dLat, dLng, distKm                                                    float64
		durMin                                                                            int
		delFee, itSub, talEst, talAct, parkFee, disc, cDrv, cSt, tot                      int64
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT o.id, o.order_code, o.service_type, o.customer_id, COALESCE(u.name, ''), COALESCE(u.phone, ''),
		       COALESCE(o.driver_id, ''), COALESCE(o.store_id, ''), COALESCE(st.store_name, ''),
		       o.vehicle_type, o.status, o.payment_method, o.payment_status,
		       o.pickup_address, o.pickup_lat, o.pickup_lng, o.dropoff_address, o.dropoff_lat, o.dropoff_lng,
		       o.distance_km, o.duration_min, o.delivery_fee, o.items_subtotal,
		       o.talangan_est_amount, o.talangan_actual_amount, o.parking_fee, o.discount_amount,
		       o.platform_commission_driver, o.platform_commission_store, o.total_customer_pay,
		       COALESCE(o.receipt_photo_url, ''), COALESCE(o.parking_photo_url, ''), COALESCE(o.notes, '')
		FROM orders o
		LEFT JOIN users u ON u.id = o.customer_id
		LEFT JOIN stores st ON st.id = o.store_id
		WHERE o.id = ?
	`, orderID).Scan(
		&id, &code, &sType, &cID, &cName, &cPhone, &dID, &stID, &stName, &vType, &st, &pMethod, &pStat,
		&pAddr, &pLat, &pLng, &dAddr, &dLat, &dLng, &distKm, &durMin, &delFee, &itSub,
		&talEst, &talAct, &parkFee, &disc, &cDrv, &cSt, &tot, &rPhoto, &pPhoto, &notes,
	)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Order not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	itemsMap := s.fetchOrderItemsMap(r.Context(), []string{id})
	items := itemsMap[id]
	if items == nil {
		items = []map[string]any{}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"order": map[string]any{
			"id":                         id,
			"order_code":                 code,
			"service_type":               sType,
			"customer_id":                cID,
			"customer_name":              cName,
			"customer_phone":             cPhone,
			"driver_id":                  dID,
			"store_id":                   stID,
			"store_name":                 stName,
			"vehicle_type":               vType,
			"status":                     st,
			"payment_method":             pMethod,
			"payment_status":             pStat,
			"pickup_address":             pAddr,
			"pickup_lat":                 pLat,
			"pickup_lng":                 pLng,
			"dropoff_address":            dAddr,
			"dropoff_lat":                dLat,
			"dropoff_lng":                dLng,
			"distance_km":                distKm,
			"duration_min":               durMin,
			"delivery_fee":               delFee,
			"items_subtotal":             itSub,
			"talangan_est_amount":        talEst,
			"talangan_actual_amount":     talAct,
			"parking_fee":                parkFee,
			"discount_amount":            disc,
			"platform_commission_driver": cDrv,
			"platform_commission_store":  cSt,
			"total_customer_pay":         tot,
			"receipt_photo_url":          rPhoto,
			"parking_photo_url":          pPhoto,
			"notes":                      notes,
			"items":                      items,
		},
	})
}

func (s *Server) handleStoreConfirmOrder(w http.ResponseWriter, r *http.Request, orderID string) {
	offerSec := s.getIntSetting(r.Context(), "driver_offer_seconds", s.offerSeconds)
	offerExpiresAt := time.Now().Add(time.Duration(offerSec) * time.Second)

	res, err := s.db.ExecContext(r.Context(), `
		UPDATE orders
		SET status = 'SEARCHING_DRIVER', offer_expires_at = ?
		WHERE id = ? AND status IN ('CREATED', 'WAITING_STORE_CONFIRM', 'STORE_PREPARING')
	`, offerExpiresAt, orderID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	affected, _ := res.RowsAffected()
	if affected == 0 {
		writeJSON(w, http.StatusConflict, map[string]any{"error": "Order tidak dalam status menunggu konfirmasi toko"})
		return
	}
	var vType, pMethod, pAddr, dAddr string
	var talEst, totalPay int64
	_ = s.db.QueryRowContext(r.Context(), `SELECT vehicle_type, payment_method, talangan_est_amount, pickup_address, dropoff_address, total_customer_pay FROM orders WHERE id = ?`, orderID).
		Scan(&vType, &pMethod, &talEst, &pAddr, &dAddr, &totalPay)
	eligibleDrivers := s.findEligibleDrivers(r.Context(), vType, pMethod, talEst)
	s.pingOrderRTDBAsync(orderID, "SEARCHING_DRIVER", "", pAddr, dAddr, totalPay, eligibleDrivers)
	writeJSON(w, http.StatusOK, map[string]any{
		"id":               orderID,
		"status":           "SEARCHING_DRIVER",
		"offer_expires_at": offerExpiresAt.Format(time.RFC3339),
	})
}

func (s *Server) handleStoreRejectOrder(w http.ResponseWriter, r *http.Request, orderID string) {
	var body struct {
		Reason string `json:"reason"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	if strings.TrimSpace(body.Reason) == "" {
		body.Reason = "Stok menu sedang habis di toko"
	}
	_, err := s.db.ExecContext(r.Context(), `
		UPDATE orders SET status = 'CANCELLED', cancel_reason = ? WHERE id = ?
	`, body.Reason, orderID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"id": orderID, "status": "CANCELLED", "cancel_reason": body.Reason})
}

// handleAcceptDriverOrder enforces an Atomic Conditional UPDATE in MySQL InnoDB
// so only one driver can claim an order when multiple drivers swipe simultaneously.
func (s *Server) handleAcceptDriverOrder(w http.ResponseWriter, r *http.Request, orderID string) {
	var body struct {
		DriverID string `json:"driver_id"`
		UserID   string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	driverID := strings.TrimSpace(body.DriverID)
	if driverID == "" && strings.TrimSpace(body.UserID) != "" {
		_ = s.db.QueryRowContext(r.Context(), `SELECT id FROM drivers WHERE user_id = ? LIMIT 1`, strings.TrimSpace(body.UserID)).Scan(&driverID)
	}
	if driverID == "" {
		if claims, err := s.extractClaims(r); err == nil {
			_ = s.db.QueryRowContext(r.Context(), `SELECT id FROM drivers WHERE user_id = ? LIMIT 1`, claims.UserID).Scan(&driverID)
		}
	}
	if driverID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "driver_id is required"})
		return
	}

	var (
		orderVehicleType string
		paymentMethod    string
		talanganEst      int64
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT vehicle_type, payment_method, talangan_est_amount FROM orders WHERE id = ?
	`, orderID).Scan(&orderVehicleType, &paymentMethod, &talanganEst)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Order not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	// Verify driver vehicle match, cash float, and negative balance tolerance
	var (
		driverVehicle string
		cashFloat     int64
		walletBalance int64
	)
	err = s.db.QueryRowContext(r.Context(), `
		SELECT d.vehicle_type, d.cash_float_amount, COALESCE(w.balance, 0)
		FROM drivers d
		LEFT JOIN wallets w ON w.owner_type = 'DRIVER' AND w.owner_id = d.id
		WHERE d.id = ?
	`, driverID).Scan(&driverVehicle, &cashFloat, &walletBalance)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Driver profile not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if driverVehicle != orderVehicleType {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": fmt.Sprintf("Jenis kendaraan driver (%s) tidak cocok dengan pesanan (%s)", driverVehicle, orderVehicleType)})
		return
	}
	if paymentMethod == "CASH" {
		negLimit := s.getInt64Setting(r.Context(), "driver_negative_balance_limit", s.negativeBalanceLimit)
		if cErr := finance.CheckDriverCashEligibility(walletBalance, negLimit); cErr != nil {
			writeJSON(w, http.StatusForbidden, map[string]any{"error": cErr.Error()})
			return
		}
	}
	if talanganEst > 0 && cashFloat < talanganEst {
		writeJSON(w, http.StatusForbidden, map[string]any{"error": "Modal kas driver tidak mencukupi estimasi talangan FlexSend"})
		return
	}

	// Atomic Conditional UPDATE on MySQL InnoDB row-level lock
	res, err := s.db.ExecContext(r.Context(), `
		UPDATE orders
		SET driver_id = ?,
		    status = 'DRIVER_ASSIGNED',
		    accepted_at = NOW()
		WHERE id = ?
		  AND status = 'SEARCHING_DRIVER'
		  AND driver_id IS NULL
	`, driverID, orderID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		writeJSON(w, http.StatusConflict, map[string]any{
			"error": "Maaf, pesanan ini baru saja diambil driver lain",
			"code":  "ORDER_ALREADY_TAKEN",
		})
		return
	}

	s.clearAllDriverOffersAsync(orderID)
	s.pingOrderRTDBAsync(orderID, "DRIVER_ASSIGNED", driverID, "", "", 0, nil)
	writeJSON(w, http.StatusOK, map[string]any{
		"id":          orderID,
		"driver_id":   driverID,
		"status":      "DRIVER_ASSIGNED",
		"accepted_at": time.Now().Format(time.RFC3339),
	})
}

func (s *Server) handleRejectDriverOrder(w http.ResponseWriter, r *http.Request, orderID string) {
	var body struct {
		DriverID string `json:"driver_id"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	driverID := strings.TrimSpace(body.DriverID)
	if driverID == "" {
		if claims, err := s.extractClaims(r); err == nil {
			_ = s.db.QueryRowContext(r.Context(), `SELECT id FROM drivers WHERE user_id = ? LIMIT 1`, claims.UserID).Scan(&driverID)
		}
	}
	if driverID != "" && s.firebase != nil {
		go func(dID, oID string) {
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()
			_ = s.firebase.ClearOrderOffer(ctx, dID, oID)
		}(driverID, orderID)
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"order_id":           orderID,
		"driver_id":          driverID,
		"rejected_by_driver": true,
		"status":             "SEARCHING_DRIVER",
	})
}

func normalizeOrderStatusTransition(raw string) string {
	st := strings.ToUpper(strings.TrimSpace(raw))
	switch st {
	case "DRIVER_AT_STORE":
		return "DRIVER_AT_PICKUP"
	case "DRIVER_PICKED_UP":
		return "IN_TRANSIT"
	default:
		return st
	}
}

func (s *Server) handleUpdateOrderStatus(w http.ResponseWriter, r *http.Request, orderID string) {
	var body struct {
		Status       string `json:"status"`
		CancelReason string `json:"cancel_reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	st := normalizeOrderStatusTransition(body.Status)
	switch st {
	case "STORE_PREPARING", "SEARCHING_DRIVER", "DRIVER_ASSIGNED", "DRIVER_AT_PICKUP", "IN_TRANSIT", "DELIVERED", "CANCELLED":
	default:
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid order status transition"})
		return
	}
	_, err := s.db.ExecContext(r.Context(), `
		UPDATE orders SET status = ?, cancel_reason = COALESCE(NULLIF(?, ''), cancel_reason) WHERE id = ?
	`, st, body.CancelReason, orderID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	s.pingOrderRTDBAsync(orderID, st, "", "", "", 0, nil)
	writeJSON(w, http.StatusOK, map[string]any{"id": orderID, "status": st})
}

func (s *Server) handleFlexSendReceipt(w http.ResponseWriter, r *http.Request, orderID string) {
	var body struct {
		TalanganActualAmount int64  `json:"talangan_actual_amount"`
		ParkingFee           int64  `json:"parking_fee"`
		ReceiptPhotoURL      string `json:"receipt_photo_url"`
		ParkingPhotoURL      string `json:"parking_photo_url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	if body.TalanganActualAmount < 0 || body.ParkingFee < 0 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "amounts cannot be negative"})
		return
	}

	var deliveryFee, itemsSub, disc int64
	err := s.db.QueryRowContext(r.Context(), `
		SELECT delivery_fee, items_subtotal, discount_amount FROM orders WHERE id = ?
	`, orderID).Scan(&deliveryFee, &itemsSub, &disc)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Order not found"})
		return
	}

	newTotal := deliveryFee + itemsSub + body.TalanganActualAmount + body.ParkingFee - disc
	if newTotal < 0 {
		newTotal = 0
	}

	_, err = s.db.ExecContext(r.Context(), `
		UPDATE orders
		SET talangan_actual_amount = ?, parking_fee = ?, receipt_photo_url = ?, parking_photo_url = ?, total_customer_pay = ?
		WHERE id = ?
	`, body.TalanganActualAmount, body.ParkingFee, body.ReceiptPhotoURL, body.ParkingPhotoURL, newTotal, orderID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"id":                     orderID,
		"talangan_actual_amount": body.TalanganActualAmount,
		"parking_fee":            body.ParkingFee,
		"total_customer_pay":     newTotal,
		"receipt_photo_url":      body.ReceiptPhotoURL,
		"parking_photo_url":      body.ParkingPhotoURL,
	})
}

func (s *Server) handleCompleteOrder(w http.ResponseWriter, r *http.Request, orderID string) {
	tx, err := s.db.BeginTx(r.Context(), nil)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	var (
		orderCode      string
		serviceType    string
		driverID       sql.NullString
		storeID        sql.NullString
		status         string
		paymentMethod  string
		deliveryFee    int64
		itemsSubtotal  int64
		talanganActual int64
		parkingFee     int64
	)

	err = tx.QueryRowContext(r.Context(), `
		SELECT order_code, service_type, driver_id, store_id, status, payment_method,
		       delivery_fee, items_subtotal, talangan_actual_amount, parking_fee
		FROM orders WHERE id = ? FOR UPDATE
	`, orderID).Scan(
		&orderCode, &serviceType, &driverID, &storeID, &status, &paymentMethod,
		&deliveryFee, &itemsSubtotal, &talanganActual, &parkingFee,
	)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Order not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	if status == "COMPLETED" {
		_ = tx.Commit()
		writeJSON(w, http.StatusOK, map[string]any{"id": orderID, "status": "COMPLETED", "idempotent": true})
		return
	}

	rule, err := s.loadPricingRule(r.Context(), serviceType)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	if serviceType != "FLEX_FOOD" {
		rule.StoreCommissionPct = 0
	}
	split := finance.CalculateCommission5Pct5Pct(deliveryFee, itemsSubtotal, rule.DriverCommissionPct, rule.StoreCommissionPct)

	_, err = tx.ExecContext(r.Context(), `
		UPDATE orders
		SET status = 'COMPLETED',
		    payment_status = 'PAID',
		    platform_commission_driver = ?,
		    platform_commission_store = ?,
		    completed_at = NOW()
		WHERE id = ?
	`, split.DriverCommission, split.StoreCommission, orderID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	var driverBalanceAfter *int64
	var storeBalanceAfter *int64

	if driverID.Valid && driverID.String != "" {
		_, _ = tx.ExecContext(r.Context(), `UPDATE drivers SET total_trips = total_trips + 1 WHERE id = ?`, driverID.String)
		wID, balBefore, wErr := s.getOrCreateWalletTx(r.Context(), tx, "DRIVER", driverID.String)
		if wErr != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": wErr.Error()})
			return
		}

		if paymentMethod == "QRIS" {
			// Credit full delivery_fee (+ talangan + parking reimbursement) then deduct 5% commission
			reimburse := talanganActual + parkingFee
			earnAmount := deliveryFee + reimburse
			midBal := balBefore + earnAmount
			afterBal := midBal - split.DriverCommission

			_, err = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, wID)
			if err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
				return
			}
			_, _ = tx.ExecContext(r.Context(), `
				INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
				VALUES (?, ?, 'ORDER_EARNING', ?, ?, ?, 'ORDER', ?, ?)
			`, newUUIDv4(), wID, earnAmount, balBefore, midBal, orderID, fmt.Sprintf("Pendapatan Ongkir QRIS %s", orderCode))
			if split.DriverCommission > 0 {
				_, _ = tx.ExecContext(r.Context(), `
					INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
					VALUES (?, ?, 'COMMISSION_DEDUCT', ?, ?, ?, 'ORDER', ?, ?)
				`, newUUIDv4(), wID, -split.DriverCommission, midBal, afterBal, orderID, fmt.Sprintf("Potongan Komisi Platform 5%% (%s)", orderCode))
			}
			driverBalanceAfter = &afterBal
		} else {
			// CASH order: driver collects cash from customer; deduct 5% driver commission from driver's wallet (can go negative down to -20000).
			afterBal := balBefore - split.DriverCommission
			_, err = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, wID)
			if err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
				return
			}
			if split.DriverCommission > 0 {
				_, _ = tx.ExecContext(r.Context(), `
					INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
					VALUES (?, ?, 'COMMISSION_DEDUCT', ?, ?, ?, 'ORDER', ?, ?)
				`, newUUIDv4(), wID, -split.DriverCommission, balBefore, afterBal, orderID, fmt.Sprintf("Potongan Komisi Tunai 5%% (%s)", orderCode))
			}
			driverBalanceAfter = &afterBal
		}
	}

	if serviceType == "FLEX_FOOD" && storeID.Valid && storeID.String != "" && itemsSubtotal > 0 {
		wID, balBefore, wErr := s.getOrCreateWalletTx(r.Context(), tx, "STORE", storeID.String)
		if wErr != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": wErr.Error()})
			return
		}
		if paymentMethod == "QRIS" {
			midBal := balBefore + itemsSubtotal
			afterBal := midBal - split.StoreCommission
			_, err = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, wID)
			if err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
				return
			}
			_, _ = tx.ExecContext(r.Context(), `
				INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
				VALUES (?, ?, 'ORDER_EARNING', ?, ?, ?, 'ORDER', ?, ?)
			`, newUUIDv4(), wID, itemsSubtotal, balBefore, midBal, orderID, fmt.Sprintf("Penjualan Menu FlexFood QRIS (%s)", orderCode))
			if split.StoreCommission > 0 {
				_, _ = tx.ExecContext(r.Context(), `
					INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
					VALUES (?, ?, 'COMMISSION_DEDUCT', ?, ?, ?, 'ORDER', ?, ?)
				`, newUUIDv4(), wID, -split.StoreCommission, midBal, afterBal, orderID, fmt.Sprintf("Potongan Komisi Toko 5%% (%s)", orderCode))
			}
			storeBalanceAfter = &afterBal
		} else {
			// Cash order: deduct 5% store commission from store wallet
			afterBal := balBefore - split.StoreCommission
			_, _ = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, afterBal, wID)
			if split.StoreCommission > 0 {
				_, _ = tx.ExecContext(r.Context(), `
					INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
					VALUES (?, ?, 'COMMISSION_DEDUCT', ?, ?, ?, 'ORDER', ?, ?)
				`, newUUIDv4(), wID, -split.StoreCommission, balBefore, afterBal, orderID, fmt.Sprintf("Potongan Komisi Toko Tunai 5%% (%s)", orderCode))
			}
			storeBalanceAfter = &afterBal
		}
	}

	// Credit platform wallet with total commission earned
	if split.PlatformTotalShare > 0 {
		var platWalletID string
		var platBal int64
		if err := tx.QueryRowContext(r.Context(), `SELECT id, balance FROM wallets WHERE owner_type = 'PLATFORM' LIMIT 1 FOR UPDATE`).Scan(&platWalletID, &platBal); err == nil {
			newPlatBal := platBal + split.PlatformTotalShare
			_, _ = tx.ExecContext(r.Context(), `UPDATE wallets SET balance = ? WHERE id = ?`, newPlatBal, platWalletID)
			_, _ = tx.ExecContext(r.Context(), `
				INSERT INTO wallet_transactions (id, wallet_id, tx_type, amount, balance_before, balance_after, reference_type, reference_id, description)
				VALUES (?, ?, 'ORDER_EARNING', ?, ?, ?, 'ORDER', ?, ?)
			`, newUUIDv4(), platWalletID, split.PlatformTotalShare, platBal, newPlatBal, orderID, fmt.Sprintf("Pendapatan Komisi Platform (%s)", orderCode))
		}
	}

	if err := tx.Commit(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	resp := map[string]any{
		"id":                         orderID,
		"order_code":                 orderCode,
		"status":                     "COMPLETED",
		"payment_method":             paymentMethod,
		"platform_commission_driver": split.DriverCommission,
		"platform_commission_store":  split.StoreCommission,
		"driver_net_earning":         split.DriverNetEarning,
		"store_net_earning":          split.StoreNetEarning,
	}
	if driverBalanceAfter != nil {
		resp["driver_wallet_balance_after"] = *driverBalanceAfter
	}
	if storeBalanceAfter != nil {
		resp["store_wallet_balance_after"] = *storeBalanceAfter
	}
	s.pingOrderRTDBAsync(orderID, "COMPLETED", driverID.String, "", "", 0, nil)
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) pingOrderRTDBAsync(orderID, status, driverID, pickupAddr, dropoffAddr string, totalPay int64, offerDriverIDs []string) {
	if s.firebase == nil || orderID == "" {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
		defer cancel()
		payload := map[string]any{"status": status}
		if driverID != "" {
			payload["driver_id"] = driverID
		}
		_ = s.firebase.PingLiveOrder(ctx, orderID, payload)

		if status == "SEARCHING_DRIVER" && len(offerDriverIDs) > 0 {
			offerPayload := map[string]any{
				"order_id":           orderID,
				"status":             status,
				"pickup_address":     pickupAddr,
				"dropoff_address":    dropoffAddr,
				"total_customer_pay": totalPay,
			}
			for _, dID := range offerDriverIDs {
				_ = s.firebase.BroadcastOrderOffer(ctx, dID, orderID, offerPayload)
			}
		}
	}()
}

func (s *Server) clearAllDriverOffersAsync(orderID string) {
	if s.firebase == nil || orderID == "" {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
		defer cancel()
		rows, err := s.db.QueryContext(ctx, `SELECT id FROM drivers WHERE is_online = 1`)
		if err != nil {
			return
		}
		defer rows.Close()
		for rows.Next() {
			var dID string
			if rows.Scan(&dID) == nil {
				_ = s.firebase.ClearOrderOffer(ctx, dID, orderID)
			}
		}
	}()
}

func (s *Server) handleInternalQRISPaid(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	secret := strings.TrimSpace(r.Header.Get("X-PayG-Secret"))
	if s.paygWebhookSecret != "" && secret != s.paygWebhookSecret {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"error": "Unauthorized internal webhook"})
		return
	}
	var body struct {
		OrderID     string `json:"order_id"`
		ReferenceID string `json:"reference_id"`
		Purpose     string `json:"purpose"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	if s.firebase != nil && strings.TrimSpace(body.OrderID) != "" {
		go func(oID string) {
			ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
			defer cancel()
			_ = s.firebase.PingLiveOrder(ctx, oID, map[string]any{"payment_status": "PAID"})
		}(strings.TrimSpace(body.OrderID))
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func (s *Server) getOrCreateWalletTx(ctx context.Context, tx *sql.Tx, ownerType, ownerID string) (string, int64, error) {
	var id string
	var bal int64
	err := tx.QueryRowContext(ctx, `
		SELECT id, balance FROM wallets WHERE owner_type = ? AND owner_id = ? FOR UPDATE
	`, ownerType, ownerID).Scan(&id, &bal)
	if err == nil {
		return id, bal, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return "", 0, err
	}
	id = newUUIDv4()
	_, err = tx.ExecContext(ctx, `
		INSERT INTO wallets (id, owner_type, owner_id, balance) VALUES (?, ?, ?, 0)
	`, id, ownerType, ownerID)
	return id, 0, err
}

func (s *Server) handleOrderRating(w http.ResponseWriter, r *http.Request, orderID string) {
	var body struct {
		CustomerID  string `json:"customer_id"`
		DriverScore *int   `json:"driver_score"`
		StoreScore  *int   `json:"store_score"`
		Comment     string `json:"comment"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	var customerID string
	var driverID, storeID sql.NullString
	err := s.db.QueryRowContext(r.Context(), `
		SELECT customer_id, driver_id, store_id FROM orders WHERE id = ?
	`, orderID).Scan(&customerID, &driverID, &storeID)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Order not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	var dScore, sScore any
	if body.DriverScore != nil && *body.DriverScore >= 1 && *body.DriverScore <= 5 {
		dScore = *body.DriverScore
	}
	if body.StoreScore != nil && *body.StoreScore >= 1 && *body.StoreScore <= 5 {
		sScore = *body.StoreScore
	}

	ratingID := newUUIDv4()
	var dVal, stVal any
	if driverID.Valid {
		dVal = driverID.String
	}
	if storeID.Valid {
		stVal = storeID.String
	}

	_, err = s.db.ExecContext(r.Context(), `
		INSERT INTO ratings (id, order_id, customer_id, driver_id, store_id, driver_Score, store_score, comment)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE driver_Score = VALUES(driver_Score), store_score = VALUES(store_score), comment = VALUES(comment)
	`, ratingID, orderID, customerID, dVal, stVal, dScore, sScore, body.Comment)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if driverID.Valid && driverID.String != "" {
		_, _ = s.db.ExecContext(r.Context(), `
			UPDATE drivers SET rating_avg = COALESCE((SELECT ROUND(AVG(driver_Score), 2) FROM ratings WHERE driver_id = ? AND driver_Score IS NOT NULL), 5.00)
			WHERE id = ?
		`, driverID.String, driverID.String)
	}
	if storeID.Valid && storeID.String != "" {
		_, _ = s.db.ExecContext(r.Context(), `
			UPDATE stores SET rating_avg = COALESCE((SELECT ROUND(AVG(store_score), 2) FROM ratings WHERE store_id = ? AND store_score IS NOT NULL), 5.00)
			WHERE id = ?
		`, storeID.String, storeID.String)
	}

	writeJSON(w, http.StatusCreated, map[string]any{"id": ratingID, "order_id": orderID, "saved": true})
}

