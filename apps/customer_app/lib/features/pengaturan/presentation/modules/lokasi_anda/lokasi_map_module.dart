import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

/// Container Peta Interaktif OpenStreetMap (Free, Zero Cost, High Res)
class LokasiMapModule extends StatelessWidget {
  final MapController mapController;
  final LatLng currentPosition;
  final double currentZoom;
  final void Function(MapCamera pos, bool hasGesture)? onPositionChanged;
  final VoidCallback? onMoveEnd;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenterGps;

  const LokasiMapModule({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.currentZoom,
    this.onPositionChanged,
    this.onMoveEnd,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenterGps,
  });

  Widget _buildMapCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = const Color(0xFF17152B),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6B48FC).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Peta FlutterMap OpenStreetMap
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentPosition,
                initialZoom: currentZoom,
                onPositionChanged: onPositionChanged,
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    onMoveEnd?.call();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rideon.customer',
                ),
              ],
            ),

            // Center Pin Marker (Tepat di tengah peta)
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      'Geser peta untuk atur titik',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 38,
                    color: Color(0xFF6B48FC),
                  ),
                  const SizedBox(height: 18), // Kompensasi anchor ujung jarum pin
                ],
              ),
            ),

            // Tombol Zoom In & Zoom Out di pojok kanan atas
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  _buildMapCircleButton(
                    icon: Icons.add,
                    onTap: onZoomIn,
                  ),
                  const SizedBox(height: 6),
                  _buildMapCircleButton(
                    icon: Icons.remove,
                    onTap: onZoomOut,
                  ),
                ],
              ),
            ),

            // Tombol Recenter GPS Cepat di pojok kanan bawah peta
            Positioned(
              bottom: 10,
              right: 10,
              child: _buildMapCircleButton(
                icon: Icons.my_location_rounded,
                color: const Color(0xFF6B48FC),
                iconColor: Colors.white,
                onTap: onRecenterGps,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
