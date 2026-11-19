package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

func (s *Server) handleStores(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}

	rows, err := s.db.QueryContext(r.Context(), `
		SELECT st.id, st.user_id, st.store_name, st.category, COALESCE(st.description, ''),
		       st.address, st.lat, st.lng, COALESCE(st.banner_url, ''), COALESCE(st.logo_url, ''),
		       st.is_open, st.open_time, st.close_time, st.rating_avg, u.status
		FROM stores st
		JOIN users u ON u.id = st.user_id
		WHERE u.status = 'ACTIVE'
		ORDER BY st.is_open DESC, st.updated_at DESC
	`)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var stores []map[string]any
	for rows.Next() {
		var (
			id, userID, storeName, cat, desc, addr, banner, logo, openT, closeT, uStatus string
			lat, lng, ratingAvg                                                          float64
			isOpen                                                                       int
		)
		if err := rows.Scan(&id, &userID, &storeName, &cat, &desc, &addr, &lat, &lng, &banner, &logo, &isOpen, &openT, &closeT, &ratingAvg, &uStatus); err != nil {
			continue
		}
		stores = append(stores, map[string]any{
			"id":          id,
			"user_id":     userID,
			"store_name":  storeName,
			"category":    cat,
			"description": desc,
			"address":     addr,
			"lat":         lat,
			"lng":         lng,
			"banner_url":  banner,
			"logo_url":    logo,
			"is_open":     isOpen == 1,
			"open_time":   openT,
			"close_time":  closeT,
			"rating_avg":  ratingAvg,
			"status":      uStatus,
		})
	}
	if stores == nil {
		stores = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"stores": stores})
}

func (s *Server) handleStoreSubtree(w http.ResponseWriter, r *http.Request) {
	trimmed := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/stores/"), "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 || parts[0] == "" {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "store id is required"})
		return
	}
	storeID := parts[0]

	if len(parts) == 1 && r.Method == http.MethodGet {
		s.handleGetStoreDetail(w, r, storeID)
		return
	}
	if len(parts) == 2 && parts[1] == "status" && (r.Method == http.MethodPatch || r.Method == http.MethodPut || r.Method == http.MethodPost) {
		s.handlePatchStoreOpenStatus(w, r, storeID)
		return
	}
	if len(parts) == 2 && parts[1] == "menus" {
		if r.Method == http.MethodGet {
			s.handleGetStoreMenus(w, r, storeID)
			return
		}
		if r.Method == http.MethodPost {
			s.handleCreateStoreMenu(w, r, storeID)
			return
		}
	}
	if len(parts) == 3 && parts[1] == "menus" {
		menuID := parts[2]
		if r.Method == http.MethodPut {
			s.handleUpdateStoreMenu(w, r, storeID, menuID)
			return
		}
		if r.Method == http.MethodDelete {
			s.handleDeleteStoreMenu(w, r, storeID, menuID)
			return
		}
	}
	writeJSON(w, http.StatusNotFound, map[string]any{"error": "Endpoint not found"})
}

func (s *Server) handleGetStoreDetail(w http.ResponseWriter, r *http.Request, storeID string) {
	var (
		id, userID, storeName, cat, desc, addr, banner, logo, openT, closeT string
		lat, lng, ratingAvg                                                 float64
		isOpen                                                              int
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT id, user_id, store_name, category, COALESCE(description, ''), address, lat, lng,
		       COALESCE(banner_url, ''), COALESCE(logo_url, ''), is_open, open_time, close_time, rating_avg
		FROM stores WHERE id = ?
	`, storeID).Scan(&id, &userID, &storeName, &cat, &desc, &addr, &lat, &lng, &banner, &logo, &isOpen, &openT, &closeT, &ratingAvg)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Store not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	menus := s.fetchMenusForStore(r, storeID)
	writeJSON(w, http.StatusOK, map[string]any{
		"store": map[string]any{
			"id":          id,
			"user_id":     userID,
			"store_name":  storeName,
			"category":    cat,
			"description": desc,
			"address":     addr,
			"lat":         lat,
			"lng":         lng,
			"banner_url":  banner,
			"logo_url":    logo,
			"is_open":     isOpen == 1,
			"open_time":   openT,
			"close_time":  closeT,
			"rating_avg":  ratingAvg,
			"menus":       menus,
		},
	})
}

func (s *Server) fetchMenusForStore(r *http.Request, storeID string) []map[string]any {
	rows, err := s.db.QueryContext(r.Context(), `
		SELECT id, store_id, name, COALESCE(description, ''), category, price, COALESCE(photo_url, ''), is_available, stock
		FROM store_menus
		WHERE store_id = ?
		ORDER BY updated_at DESC, created_at DESC
	`, storeID)
	if err != nil {
		return []map[string]any{}
	}
	defer rows.Close()

	var menus []map[string]any
	for rows.Next() {
		var (
			id, sID, name, desc, cat, photo string
			price                           int64
			isAvail, stock                  int
		)
		if err := rows.Scan(&id, &sID, &name, &desc, &cat, &price, &photo, &isAvail, &stock); err != nil {
			continue
		}
		menus = append(menus, map[string]any{
			"id":           id,
			"store_id":     sID,
			"name":         name,
			"description":  desc,
			"category":     cat,
			"price":        price,
			"photo_url":    photo,
			"is_available": isAvail == 1,
			"stock":        stock,
		})
	}
	if menus == nil {
		menus = []map[string]any{}
	}
	return menus
}

func (s *Server) handleGetStoreMenus(w http.ResponseWriter, r *http.Request, storeID string) {
	writeJSON(w, http.StatusOK, map[string]any{"menus": s.fetchMenusForStore(r, storeID)})
}

func (s *Server) handlePublicMenus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	q := strings.TrimSpace(r.URL.Query().Get("q"))
	cat := strings.TrimSpace(r.URL.Query().Get("category"))
	storeID := strings.TrimSpace(r.URL.Query().Get("store_id"))

	var where []string
	var args []any
	where = append(where, "u.status = 'ACTIVE'", "m.is_available = 1")
	if q != "" {
		like := "%" + q + "%"
		where = append(where, "(m.name LIKE ? OR COALESCE(m.description, '') LIKE ? OR m.category LIKE ? OR st.store_name LIKE ?)")
		args = append(args, like, like, like, like)
	}
	if cat != "" && !strings.EqualFold(cat, "Semua") {
		where = append(where, "m.category = ?")
		args = append(args, cat)
	}
	if storeID != "" {
		where = append(where, "m.store_id = ?")
		args = append(args, storeID)
	}

	query := `
		SELECT m.id, m.store_id, m.name, COALESCE(m.description, ''), m.category, m.price,
		       COALESCE(m.photo_url, ''), m.is_available, m.stock,
		       st.store_name, st.address, st.lat, st.lng, st.is_open, st.rating_avg,
		       COALESCE((SELECT SUM(oi.qty) FROM order_items oi JOIN orders o ON o.id = oi.order_id WHERE oi.menu_id = m.id AND o.status = 'COMPLETED'), 0) AS sold_count
		FROM store_menus m
		JOIN stores st ON st.id = m.store_id
		JOIN users u ON u.id = st.user_id
		WHERE ` + strings.Join(where, " AND ") + `
		ORDER BY st.is_open DESC, sold_count DESC, m.updated_at DESC, m.created_at DESC
		LIMIT 100
	`
	rows, err := s.db.QueryContext(r.Context(), query, args...)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	defer rows.Close()

	var menus []map[string]any
	for rows.Next() {
		var (
			id, sID, name, desc, category, photo, storeName, storeAddr string
			price, soldCount                                           int64
			isAvail, stock, isOpen                                     int
			lat, lng, ratingAvg                                        float64
		)
		if err := rows.Scan(&id, &sID, &name, &desc, &category, &price, &photo, &isAvail, &stock, &storeName, &storeAddr, &lat, &lng, &isOpen, &ratingAvg, &soldCount); err != nil {
			continue
		}
		menus = append(menus, map[string]any{
			"id":            id,
			"store_id":      sID,
			"name":          name,
			"description":   desc,
			"category":      category,
			"price":         price,
			"photo_url":     photo,
			"is_available":  isAvail == 1,
			"stock":         stock,
			"store_name":    storeName,
			"store_address": storeAddr,
			"store_lat":     lat,
			"store_lng":     lng,
			"store_is_open": isOpen == 1,
			"rating_avg":    ratingAvg,
			"sold_count":    soldCount,
		})
	}
	if menus == nil {
		menus = []map[string]any{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"menus": menus})
}

type menuInput struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Category    string  `json:"category"`
	Price       int64   `json:"price"`
	PhotoURL    *string `json:"photo_url"`
	IsAvailable *bool   `json:"is_available"`
	Stock       *int    `json:"stock"`
}

func (s *Server) handleCreateStoreMenu(w http.ResponseWriter, r *http.Request, storeID string) {
	var in menuInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	name := strings.TrimSpace(in.Name)
	if name == "" || in.Price <= 0 {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "name and positive price are required"})
		return
	}
	cat := strings.TrimSpace(in.Category)
	if cat == "" {
		cat = "Makanan Utama"
	}
	isAvail := 1
	if in.IsAvailable != nil && !*in.IsAvailable {
		isAvail = 0
	}
	stock := 100
	if in.Stock != nil && *in.Stock >= 0 {
		stock = *in.Stock
	}
	var photoVal any = nil
	if in.PhotoURL != nil && strings.TrimSpace(*in.PhotoURL) != "" {
		photoVal = strings.TrimSpace(*in.PhotoURL)
	}

	menuID := newUUIDv4()
	_, err := s.db.ExecContext(r.Context(), `
		INSERT INTO store_menus (id, store_id, name, description, category, price, photo_url, is_available, stock)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, menuID, storeID, name, in.Description, cat, in.Price, photoVal, isAvail, stock)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{
		"id":           menuID,
		"store_id":     storeID,
		"name":         name,
		"description":  in.Description,
		"category":     cat,
		"price":        in.Price,
		"photo_url":    photoVal,
		"is_available": isAvail == 1,
		"stock":        stock,
	})
}

func (s *Server) handleUpdateStoreMenu(w http.ResponseWriter, r *http.Request, storeID, menuID string) {
	var in menuInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}

	var (
		name, desc, cat, photo string
		price                  int64
		isAvail, stock         int
	)
	err := s.db.QueryRowContext(r.Context(), `
		SELECT name, COALESCE(description, ''), category, price, COALESCE(photo_url, ''), is_available, stock
		FROM store_menus WHERE id = ? AND store_id = ?
	`, menuID, storeID).Scan(&name, &desc, &cat, &price, &photo, &isAvail, &stock)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Menu not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}

	if strings.TrimSpace(in.Name) != "" {
		name = strings.TrimSpace(in.Name)
	}
	if in.Description != "" {
		desc = in.Description
	}
	if strings.TrimSpace(in.Category) != "" {
		cat = strings.TrimSpace(in.Category)
	}
	if in.Price > 0 {
		price = in.Price
	}
	if in.PhotoURL != nil {
		photo = strings.TrimSpace(*in.PhotoURL)
	}
	if in.IsAvailable != nil {
		if *in.IsAvailable {
			isAvail = 1
		} else {
			isAvail = 0
		}
	}
	if in.Stock != nil && *in.Stock >= 0 {
		stock = *in.Stock
	}

	_, err = s.db.ExecContext(r.Context(), `
		UPDATE store_menus
		SET name = ?, description = ?, category = ?, price = ?, photo_url = ?, is_available = ?, stock = ?
		WHERE id = ? AND store_id = ?
	`, name, desc, cat, price, photo, isAvail, stock, menuID, storeID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"id":           menuID,
		"store_id":     storeID,
		"name":         name,
		"description":  desc,
		"category":     cat,
		"price":        price,
		"photo_url":    photo,
		"is_available": isAvail == 1,
		"stock":        stock,
	})
}

func (s *Server) handleDeleteStoreMenu(w http.ResponseWriter, r *http.Request, storeID, menuID string) {
	_, err := s.db.ExecContext(r.Context(), `DELETE FROM store_menus WHERE id = ? AND store_id = ?`, menuID, storeID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"deleted": true, "id": menuID})
}

func (s *Server) handlePatchStoreOpenStatus(w http.ResponseWriter, r *http.Request, storeID string) {
	var userStatus string
	err := s.db.QueryRowContext(r.Context(), `
		SELECT u.status
		FROM stores st
		JOIN users u ON u.id = st.user_id
		WHERE st.id = ?
		LIMIT 1
	`, storeID).Scan(&userStatus)
	if errors.Is(err, sql.ErrNoRows) {
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "Store not found"})
		return
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	if userStatus != "ACTIVE" {
		writeJSON(w, http.StatusForbidden, map[string]any{
			"error":  "Akun toko masih dalam proses verifikasi Admin",
			"status": userStatus,
		})
		return
	}

	var body struct {
		IsOpen bool `json:"is_open"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	val := 0
	if body.IsOpen {
		val = 1
	}
	_, err = s.db.ExecContext(r.Context(), `UPDATE stores SET is_open = ? WHERE id = ?`, val, storeID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"id": storeID, "is_open": body.IsOpen})
}

func (s *Server) handlePromotions(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		rows, err := s.db.QueryContext(r.Context(), `
			SELECT id, code, title, COALESCE(description, ''), discount_type, discount_value,
			       min_order_amount, COALESCE(max_discount_amount, 0), quota, used_count, is_active
			FROM promotions
			ORDER BY is_active DESC, created_at DESC
		`)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()
		var list []map[string]any
		for rows.Next() {
			var (
				id, code, title, desc, dType          string
				dVal, minOrd, maxDisc                 int64
				quota, usedCount, isActive            int
			)
			if err := rows.Scan(&id, &code, &title, &desc, &dType, &dVal, &minOrd, &maxDisc, &quota, &usedCount, &isActive); err != nil {
				continue
			}
			list = append(list, map[string]any{
				"id":                  id,
				"code":                code,
				"title":               title,
				"description":         desc,
				"discount_type":       dType,
				"discount_value":      dVal,
				"min_order_amount":    minOrd,
				"max_discount_amount": maxDisc,
				"quota":               quota,
				"used_count":          usedCount,
				"is_active":           isActive == 1,
			})
		}
		writeJSON(w, http.StatusOK, map[string]any{"promotions": list})

	case http.MethodPost:
		var in struct {
			Code              string `json:"code"`
			Title             string `json:"title"`
			Description       string `json:"description"`
			DiscountType      string `json:"discount_type"`
			DiscountValue     int64  `json:"discount_value"`
			MinOrderAmount    int64  `json:"min_order_amount"`
			MaxDiscountAmount int64  `json:"max_discount_amount"`
			Quota             int    `json:"quota"`
		}
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		code := strings.ToUpper(strings.TrimSpace(in.Code))
		title := strings.TrimSpace(in.Title)
		if code == "" || title == "" || in.DiscountValue <= 0 {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "code, title, and positive discount_value are required"})
			return
		}
		dType := strings.ToUpper(strings.TrimSpace(in.DiscountType))
		if dType != "PERCENTAGE" {
			dType = "FIXED"
		}
		if in.Quota <= 0 {
			in.Quota = 100
		}
		id := newUUIDv4()
		_, err := s.db.ExecContext(r.Context(), `
			INSERT INTO promotions (id, code, title, description, discount_type, discount_value, min_order_amount, max_discount_amount, quota, used_count, start_at, end_at, is_active)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW(), DATE_ADD(NOW(), INTERVAL 90 DAY), 1)
		`, id, code, title, in.Description, dType, in.DiscountValue, in.MinOrderAmount, in.MaxDiscountAmount, in.Quota)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, map[string]any{"id": id, "code": code, "title": title})

	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
	}
}

func (s *Server) handlePromotionByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	id := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/promotions/"), "/")
	var in struct {
		Title         *string `json:"title"`
		DiscountValue *int64  `json:"discount_value"`
		IsActive      *bool   `json:"is_active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
		return
	}
	if in.Title != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE promotions SET title = ? WHERE id = ?`, *in.Title, id)
	}
	if in.DiscountValue != nil {
		_, _ = s.db.ExecContext(r.Context(), `UPDATE promotions SET discount_value = ? WHERE id = ?`, *in.DiscountValue, id)
	}
	if in.IsActive != nil {
		val := 0
		if *in.IsActive {
			val = 1
		}
		_, _ = s.db.ExecContext(r.Context(), `UPDATE promotions SET is_active = ? WHERE id = ?`, val, id)
	}
	writeJSON(w, http.StatusOK, map[string]any{"id": id, "updated": true})
}

func (s *Server) handleFavorites(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	if claims, err := s.extractClaims(r); err == nil && userID == "" {
		userID = claims.UserID
	}

	switch r.Method {
	case http.MethodGet:
		if userID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "user_id or Bearer token is required"})
			return
		}
		rows, err := s.db.QueryContext(r.Context(), `
			SELECT id, user_id, target_type, COALESCE(store_id, ''), COALESCE(menu_id, ''), created_at
			FROM user_favorites WHERE user_id = ? ORDER BY created_at DESC
		`, userID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		defer rows.Close()
		var favs []map[string]any
		for rows.Next() {
			var (
				id, uID, tType, sID, mID string
				createdAt                time.Time
			)
			if err := rows.Scan(&id, &uID, &tType, &sID, &mID, &createdAt); err != nil {
				continue
			}
			favs = append(favs, map[string]any{
				"id":          id,
				"user_id":     uID,
				"target_type": tType,
				"store_id":    sID,
				"menu_id":     mID,
				"created_at":  createdAt.Format(time.RFC3339),
			})
		}
		if favs == nil {
			favs = []map[string]any{}
		}
		writeJSON(w, http.StatusOK, map[string]any{"favorites": favs})

	case http.MethodPost:
		var in struct {
			UserID     string  `json:"user_id"`
			TargetType string  `json:"target_type"`
			StoreID    *string `json:"store_id"`
			MenuID     *string `json:"menu_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "Invalid JSON body"})
			return
		}
		if in.UserID != "" {
			userID = strings.TrimSpace(in.UserID)
		}
		tType := strings.ToUpper(strings.TrimSpace(in.TargetType))
		if userID == "" || (tType != "STORE" && tType != "MENU") {
			writeJSON(w, http.StatusBadRequest, map[string]any{"error": "user_id and target_type (STORE or MENU) are required"})
			return
		}
		sID := ""
		if in.StoreID != nil {
			sID = strings.TrimSpace(*in.StoreID)
		}
		mID := ""
		if in.MenuID != nil {
			mID = strings.TrimSpace(*in.MenuID)
		}

		// Handler-level deduplication because MySQL unique index does not deduplicate NULL columns.
		var existingID string
		err := s.db.QueryRowContext(r.Context(), `
			SELECT id FROM user_favorites
			WHERE user_id = ? AND target_type = ? AND COALESCE(store_id, '') = ? AND COALESCE(menu_id, '') = ?
			LIMIT 1
		`, userID, tType, sID, mID).Scan(&existingID)
		if err == nil && existingID != "" {
			writeJSON(w, http.StatusOK, map[string]any{"id": existingID, "duplicate": true})
			return
		}

		var sVal, mVal any
		if sID != "" {
			sVal = sID
		}
		if mID != "" {
			mVal = mID
		}
		id := newUUIDv4()
		_, err = s.db.ExecContext(r.Context(), `
			INSERT INTO user_favorites (id, user_id, target_type, store_id, menu_id)
			VALUES (?, ?, ?, ?, ?)
		`, id, userID, tType, sVal, mVal)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, map[string]any{"id": id, "user_id": userID, "target_type": tType})

	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
	}
}

func (s *Server) handleFavoriteByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "Method not allowed"})
		return
	}
	id := strings.Trim(strings.TrimPrefix(r.URL.Path, "/v1/favorites/"), "/")
	_, err := s.db.ExecContext(r.Context(), `DELETE FROM user_favorites WHERE id = ?`, id)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"deleted": true, "id": id})
}

