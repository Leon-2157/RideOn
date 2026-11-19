package context

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
)

const safeActionBoundary = `Anda adalah Asisten AI resmi ekosistem RideOn (Lhokseumawe & Aceh Utara).
BATASAN KEAMANAN (SAFE ACTION BOUNDARY):
- Anda hanya berwenang MEMBACA ringkasan data operasional real-time yang diberikan pada bagian KONTEKS DATA AKTUAL di bawah ini.
- Anda DILARANG mengklaim telah mengubah saldo dompet, menyetujui penarikan dana (withdraw), mengubah status order, atau menyetujui dokumen pendaftaran mitra secara sepihak.
- Seluruh mutasi finansial, pembatalan/ubah status pesanan, dan persetujuan admin hanya diproses melalui tombol aksi resmi di aplikasi atau panel Admin.`

// BuildSystemPrompt combines the safe action boundary, live read-only MySQL snapshots
// scoped to the caller role/user, and any per-request prompt instructions.
func BuildSystemPrompt(ctx context.Context, db *sql.DB, appRole, userID, customPrompt string) string {
	var b strings.Builder
	b.WriteString(safeActionBoundary)

	role := strings.ToUpper(strings.TrimSpace(appRole))
	if db != nil {
		var snapshot string
		switch role {
		case "ADMIN":
			snapshot = readAdminSnapshot(ctx, db)
		case "STORE":
			snapshot = readStoreSnapshot(ctx, db, userID)
		case "DRIVER":
			snapshot = readDriverSnapshot(ctx, db, userID)
		default:
			snapshot = readCustomerSnapshot(ctx, db, userID)
		}
		if snapshot != "" {
			b.WriteString("\n\nKONTEKS DATA AKTUAL (MySQL Real-Time):\n")
			b.WriteString(snapshot)
		}
	}

	if extra := strings.TrimSpace(customPrompt); extra != "" {
		b.WriteString("\n\nINSTRUKSI TAMBAHAN:\n")
		b.WriteString(extra)
	}
	return b.String()
}

func readAdminSnapshot(ctx context.Context, db *sql.DB) string {
	var totalOrders, activeOrders, pendingRegs, pendingWithdrawals, pendingTalangan, onlineDrivers, openStores int
	var todayGMV int64
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM orders`).Scan(&totalOrders)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM orders WHERE status NOT IN ('COMPLETED', 'CANCELLED')`).Scan(&activeOrders)
	_ = db.QueryRowContext(ctx, `SELECT COALESCE(SUM(total_customer_pay), 0) FROM orders WHERE DATE(created_at) = CURDATE() AND status = 'COMPLETED'`).Scan(&todayGMV)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM registrations WHERE status = 'PENDING'`).Scan(&pendingRegs)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM withdrawals WHERE status = 'PENDING'`).Scan(&pendingWithdrawals)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM talangan_claims WHERE status IN ('SUBMITTED_STEP1', 'APPROVED_FOR_DONATION')`).Scan(&pendingTalangan)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM drivers WHERE is_online = 1`).Scan(&onlineDrivers)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM stores WHERE is_open = 1`).Scan(&openStores)

	return fmt.Sprintf(
		"- Ringkasan Admin: total order=%d, order aktif=%d, GMV selesai hari ini=Rp %d\n- Driver online=%d, Toko buka=%d\n- Antrean Admin: pendaftaran pending=%d, penarikan saldo pending=%d, klaim talangan pending=%d",
		totalOrders, activeOrders, todayGMV, onlineDrivers, openStores, pendingRegs, pendingWithdrawals, pendingTalangan,
	)
}

func readStoreSnapshot(ctx context.Context, db *sql.DB, userID string) string {
	if strings.TrimSpace(userID) == "" {
		return "- Peran: Mitra Toko RideOn."
	}
	var storeID, storeName, userStatus string
	var isOpen, menuCount int
	var balance int64
	err := db.QueryRowContext(ctx, `
		SELECT st.id, st.store_name, st.is_open, u.status, COALESCE(w.balance, 0),
		       (SELECT COUNT(*) FROM store_menus m WHERE m.store_id = st.id)
		FROM stores st
		JOIN users u ON u.id = st.user_id
		LEFT JOIN wallets w ON w.owner_type = 'STORE' AND w.owner_id = st.id
		WHERE st.user_id = ? OR st.id = ?
		LIMIT 1
	`, userID, userID).Scan(&storeID, &storeName, &isOpen, &userStatus, &balance, &menuCount)
	if err != nil {
		return "- Peran: Mitra Toko RideOn."
	}

	var b strings.Builder
	fmt.Fprintf(&b, "- Toko: %s (status akun=%s, toko buka=%v, jumlah menu=%d, saldo dompet=Rp %d)\n",
		storeName, userStatus, isOpen == 1, menuCount, balance)

	rows, rErr := db.QueryContext(ctx, `
		SELECT order_code, status, total_customer_pay
		FROM orders WHERE store_id = ?
		ORDER BY created_at DESC LIMIT 5
	`, storeID)
	if rErr == nil {
		defer rows.Close()
		var orders []string
		for rows.Next() {
			var code, st string
			var pay int64
			if rows.Scan(&code, &st, &pay) == nil {
				orders = append(orders, fmt.Sprintf("%s [%s, Rp %d]", code, st, pay))
			}
		}
		if len(orders) > 0 {
			fmt.Fprintf(&b, "- 5 pesanan terakhir toko: %s", strings.Join(orders, "; "))
		}
	}
	return strings.TrimSpace(b.String())
}

func readDriverSnapshot(ctx context.Context, db *sql.DB, userID string) string {
	if strings.TrimSpace(userID) == "" {
		return "- Peran: Mitra Driver RideOn."
	}
	var driverID, drvName, userStatus, vType, vPlate string
	var isOnline, totalTrips int
	var cashFloat, balance int64
	err := db.QueryRowContext(ctx, `
		SELECT d.id, u.name, u.status, d.vehicle_type, d.vehicle_plate, d.is_online,
		       d.cash_float_amount, d.total_trips, COALESCE(w.balance, 0)
		FROM drivers d
		JOIN users u ON u.id = d.user_id
		LEFT JOIN wallets w ON w.owner_type = 'DRIVER' AND w.owner_id = d.id
		WHERE d.user_id = ? OR d.id = ?
		LIMIT 1
	`, userID, userID).Scan(&driverID, &drvName, &userStatus, &vType, &vPlate, &isOnline, &cashFloat, &totalTrips, &balance)
	if err != nil {
		return "- Peran: Mitra Driver RideOn."
	}

	var b strings.Builder
	fmt.Fprintf(&b, "- Driver: %s (%s %s, status=%s, online=%v, total trip=%d, modal kas=Rp %d, saldo dompet=Rp %d)\n",
		drvName, vType, vPlate, userStatus, isOnline == 1, totalTrips, cashFloat, balance)

	rows, rErr := db.QueryContext(ctx, `
		SELECT order_code, service_type, status, delivery_fee
		FROM orders WHERE driver_id = ?
		ORDER BY created_at DESC LIMIT 5
	`, driverID)
	if rErr == nil {
		defer rows.Close()
		var trips []string
		for rows.Next() {
			var code, sType, st string
			var fee int64
			if rows.Scan(&code, &sType, &st, &fee) == nil {
				trips = append(trips, fmt.Sprintf("%s (%s, %s, ongkir Rp %d)", code, sType, st, fee))
			}
		}
		if len(trips) > 0 {
			fmt.Fprintf(&b, "- 5 trip terakhir: %s", strings.Join(trips, "; "))
		}
	}
	return strings.TrimSpace(b.String())
}

func readCustomerSnapshot(ctx context.Context, db *sql.DB, userID string) string {
	var b strings.Builder
	rows, err := db.QueryContext(ctx, `
		SELECT st.store_name, st.category, st.address
		FROM stores st
		JOIN users u ON u.id = st.user_id
		WHERE u.status = 'ACTIVE' AND st.is_open = 1
		ORDER BY st.rating_avg DESC LIMIT 5
	`)
	if err == nil {
		defer rows.Close()
		var stores []string
		for rows.Next() {
			var name, cat, addr string
			if rows.Scan(&name, &cat, &addr) == nil {
				stores = append(stores, fmt.Sprintf("%s (%s - %s)", name, cat, addr))
			}
		}
		if len(stores) > 0 {
			fmt.Fprintf(&b, "- Warung/Toko aktif buka: %s\n", strings.Join(stores, "; "))
		}
	}

	if strings.TrimSpace(userID) != "" {
		oRows, oErr := db.QueryContext(ctx, `
			SELECT order_code, service_type, status, total_customer_pay
			FROM orders WHERE customer_id = ?
			ORDER BY created_at DESC LIMIT 3
		`, userID)
		if oErr == nil {
			defer oRows.Close()
			var recent []string
			for oRows.Next() {
				var code, sType, st string
				var pay int64
				if oRows.Scan(&code, &sType, &st, &pay) == nil {
					recent = append(recent, fmt.Sprintf("%s [%s, %s, Rp %d]", code, sType, st, pay))
				}
			}
			if len(recent) > 0 {
				fmt.Fprintf(&b, "- Pesanan terbaru pelanggan: %s", strings.Join(recent, "; "))
			}
		}
	}
	return strings.TrimSpace(b.String())
}

