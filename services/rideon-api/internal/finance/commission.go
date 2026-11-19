package finance

import (
	"errors"
	"math"
)

type CommissionSplit struct {
	DriverCommission   int64
	DriverNetEarning   int64
	StoreCommission    int64
	StoreNetEarning    int64
	PlatformTotalShare int64
}

// CalculateCommission5Pct5Pct computes the platform commission from delivery_fee
// (default 5%) and items_subtotal (default 5% for FLEX_FOOD, 0% otherwise).
func CalculateCommission5Pct5Pct(deliveryFee, itemsSubtotal int64, driverPct, storePct float64) CommissionSplit {
	if deliveryFee < 0 {
		deliveryFee = 0
	}
	if itemsSubtotal < 0 {
		itemsSubtotal = 0
	}
	if driverPct < 0 {
		driverPct = 0
	}
	if storePct < 0 {
		storePct = 0
	}

	driverComm := int64(math.Round(float64(deliveryFee) * (driverPct / 100.0)))
	storeComm := int64(math.Round(float64(itemsSubtotal) * (storePct / 100.0)))

	return CommissionSplit{
		DriverCommission:   driverComm,
		DriverNetEarning:   deliveryFee - driverComm,
		StoreCommission:    storeComm,
		StoreNetEarning:    itemsSubtotal - storeComm,
		PlatformTotalShare: driverComm + storeComm,
	}
}

// CheckDriverCashEligibility verifies whether a driver's wallet balance can accept
// a CASH order given the negative balance tolerance (e.g. limit = 20000 means balance >= -20000).
// Once balance reaches <= -20000, the driver must top up via QRIS or take a QRIS order.
func CheckDriverCashEligibility(currentBalance int64, negativeLimitPositive int64) error {
	if negativeLimitPositive < 0 {
		negativeLimitPositive = -negativeLimitPositive
	}
	minAllowed := -negativeLimitPositive
	if currentBalance <= minAllowed {
		return errors.New("saldo deposit driver telah menyentuh batas minus maksimum (-Rp 20.000), silakan Top-Up via QRIS terlebih dahulu")
	}
	return nil
}

// ComputeFare calculates delivery_fee from distanceKm and pricing_rules.
// BaseFare applies for the first 2 km; distance above 2 km adds PerKmFare per km.
func ComputeFare(distanceKm float64, baseFare, perKmFare, minFare, platformFeeFixed int64) int64 {
	if distanceKm < 0 {
		distanceKm = 0
	}
	extraKm := distanceKm - 2.0
	if extraKm < 0 {
		extraKm = 0
	}
	fare := baseFare + int64(math.Ceil(extraKm)*float64(perKmFare)) + platformFeeFixed
	if fare < minFare {
		fare = minFare
	}
	return fare
}

// HaversineRoadKm estimates road distance in km between two GPS points
// (straight-line Haversine distance multiplied by 1.32 road factor).
func HaversineRoadKm(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusKm = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLng := (lng2 - lng1) * math.Pi / 180.0
	rLat1 := lat1 * math.Pi / 180.0
	rLat2 := lat2 * math.Pi / 180.0

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(rLat1)*math.Cos(rLat2)*math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	roadKm := earthRadiusKm * c * 1.32
	if roadKm < 0.5 {
		roadKm = 1.0
	}
	return math.Round(roadKm*100) / 100
}

