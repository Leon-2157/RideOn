package qris

import (
	"fmt"
	"strings"

	qrcode "github.com/skip2/go-qrcode"
)

// RenderSVG encodes a QRIS EMVCo payload into a compact, crisp-edge SVG document.
func RenderSVG(payload string) (string, error) {
	qr, err := qrcode.New(payload, qrcode.Medium)
	if err != nil {
		return "", err
	}
	bitmap := qr.Bitmap()
	size := len(bitmap)
	if size == 0 {
		return "", fmt.Errorf("empty qr bitmap")
	}

	var path strings.Builder
	for y, row := range bitmap {
		for x, dark := range row {
			if dark {
				fmt.Fprintf(&path, "M%d %dh1v1h-1z", x, y)
			}
		}
	}
	return fmt.Sprintf(
		`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" shape-rendering="crispEdges"><rect width="100%%" height="100%%" fill="#ffffff"/><path fill="#111111" d="%s"/></svg>`,
		size, size, path.String(),
	), nil
}

