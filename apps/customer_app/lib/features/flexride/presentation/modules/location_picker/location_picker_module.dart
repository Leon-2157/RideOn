import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';

class LocationPickerModule extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final Function(String address) onSelectSavedAddress;
  final VoidCallback onPickViaMap;
  final VoidCallback onProceedToVehicles;

  const LocationPickerModule({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.onSelectSavedAddress,
    required this.onPickViaMap,
    required this.onProceedToVehicles,
  });

  static const List<Map<String, dynamic>> savedAddresses = [
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Character Illustration Header matching Figma node [1:2948]
          Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.flexrideManHeader,
                  height: 56,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Image.asset(
                  AppAssets.flexrideSpeechBubble,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // Pickup & Destination Inputs Box
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                              controller: pickupController,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                              controller: destinationController,
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

          // Saved Addresses List
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
                  onTap: () => onSelectSavedAddress(addr['addr'] as String),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
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

          // Button Outline: + Pilih Lewat Peta Langsung
          GestureDetector(
            onTap: onPickViaMap,
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
            onTap: onProceedToVehicles,
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
}
