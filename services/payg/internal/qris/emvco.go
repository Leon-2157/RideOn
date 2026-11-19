package qris

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

// DefaultDevStaticQRIS is a valid EMVCo static QRIS payload used in development
// when PAYG_STATIC_QRIS is empty in both environment variables and system_settings.
const DefaultDevStaticQRIS = "00020101021126660014ID.CO.QRIS.WWW01189360050300000898760215ID10260000123450303UMI5204581253033605802ID5918RIDEON LHOKSEUMAWE6011LHOKSEUMAWE610524351630464CF"

type TLV struct {
	Tag   string
	Value string
}

// ComputeCRC16 calculates the EMVCo CRC-16/CCITT-FALSE checksum
// (polynomial 0x1021, initial value 0xFFFF, no final XOR) as a 4-char uppercase hex string.
func ComputeCRC16(input string) string {
	crc := uint16(0xFFFF)
	for i := 0; i < len(input); i++ {
		crc ^= uint16(input[i]) << 8
		for j := 0; j < 8; j++ {
			if (crc & 0x8000) != 0 {
				crc = (crc << 1) ^ 0x1021
			} else {
				crc <<= 1
			}
		}
	}
	return fmt.Sprintf("%04X", crc)
}

// ParseEMVCo splits an EMVCo QRIS string into top-level TLV fields.
func ParseEMVCo(payload string) ([]TLV, error) {
	payload = strings.TrimSpace(payload)
	if len(payload) < 12 {
		return nil, errors.New("qris payload too short")
	}

	var fields []TLV
	idx := 0
	for idx < len(payload) {
		if idx+4 > len(payload) {
			return nil, fmt.Errorf("truncated TLV header at offset %d", idx)
		}
		tag := payload[idx : idx+2]
		length, err := strconv.Atoi(payload[idx+2 : idx+4])
		if err != nil || length < 0 {
			return nil, fmt.Errorf("invalid TLV length at offset %d", idx)
		}
		if idx+4+length > len(payload) {
			return nil, fmt.Errorf("TLV tag %s length %d exceeds payload bounds", tag, length)
		}
		val := payload[idx+4 : idx+4+length]
		fields = append(fields, TLV{Tag: tag, Value: val})
		idx += 4 + length
	}
	return fields, nil
}

// ValidateCRC verifies that the payload ends with Tag 63 (length 04) matching ComputeCRC16.
func ValidateCRC(payload string) bool {
	payload = strings.TrimSpace(payload)
	if len(payload) < 8 {
		return false
	}
	tagMarker := payload[len(payload)-8 : len(payload)-4]
	if tagMarker != "6304" {
		return false
	}
	expected := ComputeCRC16(payload[:len(payload)-4])
	actual := strings.ToUpper(payload[len(payload)-4:])
	return expected == actual
}

// GenerateDynamicQRIS converts a static EMVCo QRIS string (or DefaultDevStaticQRIS if empty)
// into a dynamic QRIS string with Tag 01 set to "12", Tag 54 set to the integer amount,
// and Tag 63 recalculated with CRC16-CCITT.
func GenerateDynamicQRIS(staticQRIS string, amount int64) (string, error) {
	if amount <= 0 {
		return "", errors.New("amount must be greater than zero")
	}
	raw := strings.TrimSpace(staticQRIS)
	if raw == "" {
		raw = DefaultDevStaticQRIS
	}

	fields, err := ParseEMVCo(raw)
	if err != nil {
		return "", err
	}

	amountStr := strconv.FormatInt(amount, 10)
	var out []TLV
	hasTag01 := false
	inserted54 := false

	for _, f := range fields {
		if f.Tag == "63" || f.Tag == "54" {
			continue
		}
		if f.Tag == "01" {
			hasTag01 = true
			out = append(out, TLV{Tag: "01", Value: "12"})
			continue
		}
		if !inserted54 && (f.Tag == "55" || f.Tag == "58" || f.Tag == "59" || f.Tag == "60" || f.Tag == "61" || f.Tag == "62") {
			out = append(out, TLV{Tag: "54", Value: amountStr})
			inserted54 = true
		}
		out = append(out, f)
	}

	if !hasTag01 {
		// Insert Tag 01 = "12" right after Tag 00 if present.
		if len(out) > 0 && out[0].Tag == "00" {
			out = append([]TLV{out[0], {Tag: "01", Value: "12"}}, out[1:]...)
		} else {
			out = append([]TLV{{Tag: "01", Value: "12"}}, out...)
		}
	}

	if !inserted54 {
		out = append(out, TLV{Tag: "54", Value: amountStr})
	}

	var sb strings.Builder
	for _, f := range out {
		sb.WriteString(f.Tag)
		sb.WriteString(fmt.Sprintf("%02d", len(f.Value)))
		sb.WriteString(f.Value)
	}
	sb.WriteString("6304")
	crc := ComputeCRC16(sb.String())
	sb.WriteString(crc)
	return sb.String(), nil
}
