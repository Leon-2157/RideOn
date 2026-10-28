import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/pages/chat_screen.dart';

/// Halaman FlexRide strictly based on Figma nodes [44:3505], [44:5901], [44:6446], [44:6080], [44:6232]:
/// 1. Masuk Flex Ride: Character illustration, Pickup & Destination input, Quick addresses, '+ Pilih Lewat Peta Langsung'
/// 2. Flex Motor / Mobil: Real-time map backdrop with bottom sheet vehicle selection & pickup note
/// 3. Cari Driver: Radar pulse searching state
/// 4. Dapat Driver & Driver Sampai: Driver tracking (Pikri Haykal, BG 4563 R) with direct chat & call access
class FlexRideScreen extends StatefulWidget {
  const FlexRideScreen({super.key});

  @override
  State<FlexRideScreen> createState() => _FlexRideScreenState();
}

enum FlexRideState {
  inputLocation, // masuk flex ride.png
  vehicleSelect, // flex motor.png / flex mOBIL.png
  searchingDriver, // cari driver.png
  driverFound, // dapat driver.png
  driverArrived, // driver sampai.png
}

class _FlexRideScreenState extends State<FlexRideScreen> {
  FlexRideState _currentState = FlexRideState.inputLocation;
  String _selectedVehicle = 'Flex Motor';
  int _selectedVehiclePrice = 14000;

  final TextEditingController _pickupController = TextEditingController(
    text: 'Jl. Brawl No. 77, Lnad of down II',
  );
  final TextEditingController _destinationController = TextEditingController(
    text: 'Jl. Ranked No. 133, Land of down IV',
  );
  final TextEditingController _pickupNoteController = TextEditingController(
    text: 'Didepan Mesjid Al-Munawarah',
  );

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupNoteController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _currentState = FlexRideState.searchingDriver;
    });

    // Auto-advance matching Figma prototype
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

  void _openChatWithDriver() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          showBackButton: true,
          initialShowDetail: true,
        ),
      ),
    );
  }

  void _openCallWithDriver() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          showBackButton: true,
          initialShowDetail: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFigmaHeader(),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, bottom: 10, left: 14, right: 14),
      decoration: const BoxDecoration(
        gradient: AppColors.splashGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (_currentState != FlexRideState.inputLocation) {
                setState(() {
                  _currentState = FlexRideState.inputLocation;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Beranda',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Text(
            'Pesan FlexRide',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
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

  // ---------------------------------------------------------------------------
  // 1. Masuk Flex Ride (figma/HalamanFlexRide/masuk flex ride.png)
  // ---------------------------------------------------------------------------
  Widget _buildInputLocationView() {
    final savedAddresses = [
      {
        'label': 'Rumah',
        'dist': '0 km',
        'addr': 'Jl. Brawl No. 77, Lnad of down II',
        'icon': Icons.home_rounded,
      },
      {
        'label': 'Kantor',
        'dist': '8,9 km',
        'addr': 'Jl. Brawl No. 77, Lnad of down II',
        'icon': Icons.business_center_rounded,
      },
      {
        'label': 'Mall Centre',
        'dist': '5,7 km',
        'addr': 'Jl. Brawl No. 77, Lnad of down II',
        'icon': Icons.shopping_bag_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Character Illustration Header (Man scratching head + 'Mau Pergi Ke mana ?')
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Image.asset(
                AppAssets.flexrideManHeader,
                height: 48,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),

        // Pickup & Destination Inputs Box with Soft Lavender Background
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFC7BCFE).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6B48FC).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Pickup Input
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOKASI JEMPUT',
                            style: GoogleFonts.roboto(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextField(
                            controller: _pickupController,
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17152B),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Dotted Connector
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 2,
                    height: 16,
                    color: const Color(0xFF6B48FC).withValues(alpha: 0.4),
                  ),
                ),
              ),
              // Destination Input
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B48FC),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TUJUAN PERJALANAN',
                            style: GoogleFonts.roboto(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextField(
                            controller: _destinationController,
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17152B),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: 'Ketik tujuan perjalananmu...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Section Title
        Text(
          'Alamat Favorit & Riwayat Cepat',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
        ),
        const SizedBox(height: 4),

        // Saved Addresses List (Cards with soft purple border)
        ...savedAddresses.map((addr) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC7BCFE),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _destinationController.text = addr['addr'] as String;
                    _currentState = FlexRideState.vehicleSelect;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          addr['icon'] as IconData,
                          size: 20,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['label'] as String,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              addr['addr'] as String,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        addr['dist'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),

        // Button Outline: + Pilih Lewat Peta Langsung (figma/HalamanFlexRide/masuk flex ride.png)
        GestureDetector(
          onTap: () {
            setState(() {
              _currentState = FlexRideState.vehicleSelect;
            });
          },
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF6B48FC),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '+ Pilih Lewat Peta Langsung',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B48FC),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentState = FlexRideState.vehicleSelect;
            });
          },
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF17152B),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Lanjut Pilih Kendaraan',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Vehicle Selection View (figma/HalamanFlexRide/flex motor.png)
  // ---------------------------------------------------------------------------
  Widget _buildVehicleSelectView() {
    return Stack(
      children: [
        // Map backdrop
        _buildSimulatedMap(showRoute: true),

        // Bottom Sheet: Address, Vehicles, Note, Order Button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFD6CEFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle bar
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF828282),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Selected Destination Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Jl.Ranked No. 133, Land of down IV (2.9 Km 12mnt)',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                ),

                // Vehicle 1: Flex Motor (Selected by default)
                _buildVehicleOptionCard(
                  name: 'Flex Motor',
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
                const SizedBox(height: 8),

                // Vehicle 2: Flex Mobil
                _buildVehicleOptionCard(
                  name: 'Flex Mobil',
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
                const SizedBox(height: 4),

                // Pickup Note Card (Patokan jemput)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _pickupNoteController,
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: const Color(0xFF17152B),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'Patokan jemput...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Order Button: 'Pesan Flex Motor Sekarang Rp 14.000'
                GestureDetector(
                  onTap: _startSearch,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Pesan $_selectedVehicle Sekarang Rp ${_selectedVehiclePrice == 14000 ? '14.000' : '30.000'}',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleOptionCard({
    required String name,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B48FC) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6B48FC) : const Color(0xFF17152B),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.roboto(
                      fontSize: 10.5,
                      color: isSelected ? const Color(0xFF6B48FC) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B48FC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Searching View (figma/HalamanFlexRide/cari driver.png)
  // ---------------------------------------------------------------------------
  Widget _buildSearchingView() {
    return Stack(
      children: [
        _buildSimulatedMap(showRoute: true),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: Color(0xFF6B48FC),
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mencari Driver Terdekat...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menghubungkan ke armada terdekat di sekitar Land of Dawn',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Driver Found & Arrived Views (dapat driver.png & driver sampai.png)
  // ---------------------------------------------------------------------------
  Widget _buildDriverTrackingView() {
    final isArrived = _currentState == FlexRideState.driverArrived;

    return Stack(
      children: [
        _buildSimulatedMap(showRoute: true, showDriver: true, isArrived: isArrived),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFD6CEFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF828282),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Status Pill: 'Driver Menuju Lokasimu' or 'Driver Sudah Tiba di Titik Jemput!'
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isArrived ? const Color(0xFFD4EDDA) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isArrived ? const Color(0xFF27AE60) : const Color(0xFF6B48FC),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isArrived) ...[
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Sudah Tiba di Titik Jemput!',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF27AE60),
                                ),
                              ),
                              Text(
                                'Temui Bapak Pikri di depan Mr.DIY',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  color: const Color(0xFF27AE60),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            'Driver Menuju Lokasimu',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B48FC),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17152B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tiba Dalam 3 Menit',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Driver Card: Pikri Haykal, 4.9, BG 4563 R, Chat & Call action buttons
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          image: const DecorationImage(
                            image: AssetImage(AppAssets.driverPikri),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pikri Haykal',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF17152B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BG 4563 R',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF1C40F)),
                                Text(
                                  '4.9',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Honda Vario 160 Hitam',
                              style: GoogleFonts.roboto(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chat Icon Button
                      GestureDetector(
                        onTap: _openChatWithDriver,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF6B48FC),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Call Icon Button
                      GestureDetector(
                        onTap: _openCallWithDriver,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF27AE60),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pickup location description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27AE60),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jemput: Jl. Brawl No. 77 (Patokan: Depan Mr.DIY)',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Action Button: 'Saya sudah Bertemu Driver'
                if (isArrived)
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selamat menikmati perjalanan bersama RideOn!'),
                          backgroundColor: Color(0xFF27AE60),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF17152B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Saya sudah Bertemu Driver',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Simulated Map Canvas (Visual Road Grid matching Figma flex motor.png)
  Widget _buildSimulatedMap({
    bool showRoute = false,
    bool showDriver = false,
    bool isArrived = false,
  }) {
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
                Icon(Icons.location_on_rounded, color: Color(0xFF27AE60), size: 28),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF17152B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white, size: 12),
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
