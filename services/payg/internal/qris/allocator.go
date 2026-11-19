package qris

import (
	"context"
	"crypto/rand"
	"database/sql"
	"errors"
	"math/big"
)

// AllocateUniqueCode reserves a 3-digit unique nominal suffix (1..999) so that
// payableAmount = baseAmount + uniqueCode does not collide with any active PENDING QRIS row.
func AllocateUniqueCode(ctx context.Context, db *sql.DB, baseAmount int64) (int, int64, error) {
	if baseAmount <= 0 {
		return 0, 0, errors.New("base_amount must be greater than zero")
	}
	used := map[int64]bool{}
	if db != nil {
		rows, err := db.QueryContext(ctx, `
			SELECT amount FROM qris_transactions
			WHERE status = 'PENDING' AND expires_at >= NOW()
		`)
		if err != nil {
			return 0, 0, err
		}
		defer rows.Close()
		for rows.Next() {
			var amt int64
			if rows.Scan(&amt) == nil {
				used[amt] = true
			}
		}
		if err := rows.Err(); err != nil {
			return 0, 0, err
		}
	}

	startOffset := 0
	if n, err := rand.Int(rand.Reader, big.NewInt(999)); err == nil {
		startOffset = int(n.Int64())
	}
	return pickNonCollidingCode(baseAmount, used, startOffset)
}

func pickNonCollidingCode(baseAmount int64, activePending map[int64]bool, startOffset int) (int, int64, error) {
	if baseAmount <= 0 {
		return 0, 0, errors.New("base_amount must be greater than zero")
	}
	for i := 0; i < 999; i++ {
		code := ((startOffset + i) % 999) + 1
		payable := baseAmount + int64(code)
		if !activePending[payable] {
			return code, payable, nil
		}
	}
	return 0, 0, errors.New("all 999 unique QRIS codes are currently busy for this base amount")
}

