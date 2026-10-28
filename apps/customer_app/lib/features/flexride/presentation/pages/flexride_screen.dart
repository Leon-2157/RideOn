import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/pages/chat_screen.dart';

/// Halaman FlexRide strictly based on Figma nodes [44:3505], [44:5901], [44:6446], [44:6080], [44:6232]:
/// 1. Masuk Flex Ride: Input pickup & destination with quick saved addresses (Rumah, Kantor, Mall Centre)
/// 2. Flex Motor / Mobil: Vehicle selection with prices (Rp 14.000 vs Rp 30.000)
/// 3. Cari Driver: Searching radar animation
/// 4. Dapat Driver & Driver Sampai: Driver tracking (Pikri Haykal, BG 4563 R) with direct chat & call access
class FlexRideScreen extends StatefulWidget {
  const FlexRideScreen({super.key});

  @override
  State<FlexRideScreen> createState() => _FlexRideScreenState();
}

enum FlexRideState {
  inputLocation,
  vehicleSelect,
  searchingDriver,
  driverFound,
  driverArrived,
}

class _FlexRideScreenState extends State<FlexRideScreen> {
  FlexRideState _currentState = FlexRideState.inputLocation;
  String _selectedVehicle = 'Flex Motor';
  int _selectedVehiclePrice = 14000;

  final TextEditingController _pickupController = TextEditingController(
    text: 'Jl. Brawl No. 77, Land of Dawn II',
  );
  final TextEditingController _destinationController = TextEditingController(
    text: 'Jl. Ranked No. 133, Land of Dawn IV',
  );

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _currentState = FlexRideState.searchingDriver;
    });

    // Auto-advance matching Figma prototype timeout
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentState == FlexRideState.searchingDriver) {
        setState(() {
          _currentState = FlexRideState.driverFound;
        });

        // Simulate driver arrived after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _currentState == FlexRideState.driverFound) {
            setState(() {
              _currentState = FlexRideState.driverArrived;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          _currentState == FlexRideState.inputLocation ? 'Pesan FlexRide' : 'Status Perjalanan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_currentState != FlexRideState.inputLocation) {
              setState(() {
                _currentState = FlexRideState.inputLocation;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentState) {
      case FlexRideState.inputLocation:
        return _buildInputLocationView();
      case FlexRideState.vehicleSelect:
        return _buildVehicleSelectView();
      case FlexRideState.searchingDriver:
        return _buildSearchingView();
      case FlexRideState.driverFound:
      case FlexRideState.driverArrived:
        return _buildDriverTrackingView();
    }
  }

  // View 1: Input Location & Saved Addresses
  Widget _buildInputLocationView() {
    final savedAddresses = [
      {'label': 'Rumah', 'dist': '0 km', 'addr': 'Jl. Brawl No. 77, Land of Dawn II', 'icon': Icons.home_rounded},
      {'label': 'Kantor', 'dist': '8,9 km', 'addr': 'Jl. Central Park No. 12, Kota Krukuh', 'icon': Icons.business_rounded},
      {'label': 'Mall Centre', 'dist': '5,7 km', 'addr': 'Grand City Mall Blok B, Lantai 1', 'icon': Icons.local_mall_rounded},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pickup & Destination Inputs Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOKASI JEMPUT', style: GoogleFonts.roboto(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                          TextField(
                            controller: _pickupController,
                            style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(width: 2, height: 16, color: AppColors.divider),
                ),
                // Destination
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TUJUAN PERJALANAN', style: GoogleFonts.roboto(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                          TextField(
                            controller: _destinationController,
                            style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Alamat Favorit & Riwayat Cepat Header
          Text(
            'Alamat Favorit & Riwayat Cepat',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),

          // Saved Address Chips / List
          ...List.generate(savedAddresses.length, (index) {
            final s = savedAddresses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _destinationController.text = s['addr'] as String;
                    _currentState = FlexRideState.vehicleSelect;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(s['icon'] as IconData, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s['label'] as String, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
                                Text(s['dist'] as String, style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(s['addr'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.roboto(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentState = FlexRideState.vehicleSelect;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Lanjut Pilih Kendaraan'),
          ),
        ],
      ),
    );
  }

  // View 2: Vehicle Selection & Map View
  Widget _buildVehicleSelectView() {
    return Column(
      children: [
        // Map Container
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFE9E8F3),
            child: Stack(
              children: [
                // Stylized map streets
                CustomPaint(
                  size: Size.infinite,
                  painter: _MapGridPainter(),
                ),

                // Pickup location badge
                Positioned(
                  top: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Patokan jemput: “Didepan Mesjid Al-Munawarah”',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Vehicle Selection Bottom Sheet
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flex Motor Option
              _vehicleCard(
                title: 'Flex Motor',
                desc: 'Tercepat (1-2 mnt Penjemputan)',
                price: 'Rp 14.000',
                icon: Icons.two_wheeler_rounded,
                isSelected: _selectedVehicle == 'Flex Motor',
                onTap: () {
                  setState(() {
                    _selectedVehicle = 'Flex Motor';
                    _selectedVehiclePrice = 14000;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Flex Mobil Option
              _vehicleCard(
                title: 'Flex Mobil',
                desc: 'Nyaman & ber-AC dingin',
                price: 'Rp 30.000',
                icon: Icons.directions_car_rounded,
                isSelected: _selectedVehicle == 'Flex Mobil',
                onTap: () {
                  setState(() {
                    _selectedVehicle = 'Flex Mobil';
                    _selectedVehiclePrice = 30000;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Confirm Button
              ElevatedButton(
                onPressed: _startSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Pesan $_selectedVehicle Sekarang Rp ${_selectedVehiclePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vehicleCard({
    required String title,
    required String desc,
    required String price,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                  Text(desc, style: GoogleFonts.roboto(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(price, style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  // View 3: Searching Driver Radar
  Widget _buildSearchingView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Menghubungkan ke Driver...',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(
            'Mencari Driver terdekat di sekitar Jl. Brawl.\nMohon tunggu sebentar...',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _currentState = FlexRideState.vehicleSelect;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(200, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('BATALKAN PEMESANAN'),
          ),
        ],
      ),
    );
  }

  // View 4: Driver Found & Tracking
  Widget _buildDriverTrackingView() {
    final isArrived = _currentState == FlexRideState.driverArrived;

    return Column(
      children: [
        // Map Area
        Expanded(
          child: Container(
            color: const Color(0xFFE9E8F3),
            child: Stack(
              children: [
                CustomPaint(size: Size.infinite, painter: _MapGridPainter()),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isArrived ? AppColors.success : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isArrived ? 'Driver Sudah Tiba di Titik Jemput!' : 'Driver Sedang Menuju Titik Jemput (3 Menit)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Driver Info Sheet
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.person, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Pikri Haykal', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                            Text('4.9', style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dark)),
                          ],
                        ),
                        Text('Honda Vario 160 Hitam • BG 4563 R', style: GoogleFonts.roboto(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  // Chat Button
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ChatScreen(showBackButton: true)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perjalanan dimulai! Hati-hati di jalan.')),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isArrived ? 'Saya sudah Bertemu Driver' : 'Hubungi Driver'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Draw stylized streets
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.45), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.35, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.65, size.height), paint);

    // Route Polyline
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.42)
      ..lineTo(size.width * 0.5, size.height * 0.43)
      ..lineTo(size.width * 0.67, size.height * 0.6);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
