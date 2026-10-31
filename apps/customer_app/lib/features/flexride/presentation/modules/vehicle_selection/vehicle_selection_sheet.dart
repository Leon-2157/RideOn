import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'vehicle_option_card.dart';

class VehicleSelectionSheet extends StatelessWidget {
  final String destinationText;
  final String selectedVehicle;
  final int selectedVehiclePrice;
  final TextEditingController pickupNoteController;
  final Function(String vehicle, int price) onSelectVehicle;
  final VoidCallback onOrder;

  const VehicleSelectionSheet({
    super.key,
    required this.destinationText,
    required this.selectedVehicle,
    required this.selectedVehiclePrice,
    required this.pickupNoteController,
    required this.onSelectVehicle,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                destinationText,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
            ),

            // Vehicle 1: Flex Motor
            VehicleOptionCard(
              name: 'Flex Motor',
              desc: 'Tercepat (1-2 mnt Penjemputan)',
              price: 'Rp 14.000',
              icon: Icons.two_wheeler_rounded,
              isSelected: selectedVehicle == 'Flex Motor',
              onTap: () => onSelectVehicle('Flex Motor', 14000),
            ),
            const SizedBox(height: 8),

            // Vehicle 2: Flex Mobil
            VehicleOptionCard(
              name: 'Flex Mobil',
              desc: 'Nyaman & ber-AC dingin',
              price: 'Rp 30.000',
              icon: Icons.directions_car_rounded,
              isSelected: selectedVehicle == 'Flex Mobil',
              onTap: () => onSelectVehicle('Flex Mobil', 30000),
            ),
            const SizedBox(height: 4),

            // Pickup Note Card
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
                      controller: pickupNoteController,
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

            // Order Button
            GestureDetector(
              onTap: onOrder,
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
                    'Pesan $selectedVehicle Sekarang Rp ${selectedVehiclePrice == 14000 ? '14.000' : '30.000'}',
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
    );
  }
}
