import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimulatedMapView extends StatelessWidget {
  final bool showRoute;
  final bool showDriver;
  final bool isArrived;

  const SimulatedMapView({
    super.key,
    this.showRoute = false,
    this.showDriver = false,
    this.isArrived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5EDEB),
      child: Stack(
        children: [
          // Road Grid
          CustomPaint(
            size: Size.infinite,
            painter: _MapPainter(),
          ),

          // Origin Marker
          const Positioned(
            left: 95,
            top: 200,
            child: Column(
              children: [
                Icon(Icons.location_on_rounded,
                    color: Color(0xFF27AE60), size: 28),
                Text(
                  'Titik Jemput Kamu',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Destination Marker
          const Positioned(
            right: 80,
            top: 80,
            child: Column(
              children: [
                Icon(Icons.location_pin, color: Color(0xFFEB5757), size: 28),
                Text(
                  'Kota Krukuh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Driver Moving Marker
          if (showDriver)
            Positioned(
              left: isArrived ? 100 : 130,
              top: isArrived ? 195 : 140,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF17152B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      isArrived ? 'Driver Sampai' : 'Pikri (3 mnt)',
                      style: GoogleFonts.roboto(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF0F3D39)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final riverPaint = Paint()
      ..color = const Color(0xFFBCE3F7)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    // Draw River
    final riverPath = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.38,
        size.width,
        size.height * 0.36,
      );
    canvas.drawPath(riverPath, riverPaint);

    // Draw Grid Roads
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.2),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );

    // Purple Route Path
    final routePaint = Paint()
      ..color = const Color(0xFF6B48FC)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.75, size.height * 0.2)
      ..lineTo(size.width * 0.75, size.height * 0.12);
    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
