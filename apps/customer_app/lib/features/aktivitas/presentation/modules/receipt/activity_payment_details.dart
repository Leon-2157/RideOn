import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

/// Items list, payment breakdown, and action button in Activity Summary
class ActivityPaymentDetails extends StatelessWidget {
  final String paymentMethod;
  final VoidCallback onReorder;

  const ActivityPaymentDetails({
    super.key,
    required this.paymentMethod,
    required this.onReorder,
  });

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF17152B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pembelian',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
        ),
        const SizedBox(height: 10),
        _buildReceiptRow('NASI GORENG + TELUR MATA SAPI', '1'),
        const SizedBox(height: 6),
        _buildReceiptRow('ES TEH HIJAU', '1'),
        const SizedBox(height: 6),
        Text(
          'Tanpa alat makan',
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.textMuted,
          ),
        ),
        const Divider(height: 32, color: Color(0xFFE2E8F0)),

        Text(
          'Detail pembayaran',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
        ),
        const SizedBox(height: 10),
        _buildReceiptRow('Harga', '25.000'),
        const SizedBox(height: 6),
        _buildReceiptRow('Biaya Penanganan & Pengiriman', '3.000'),
        const SizedBox(height: 6),
        _buildReceiptRow('Biaya lainnya', '1.500'),
        const Divider(height: 20, color: Color(0xFFE2E8F0)),
        _buildReceiptRow('Total', '29.500', isBold: true),
        const Divider(height: 20, color: Color(0xFFE2E8F0)),
        _buildReceiptRow(paymentMethod, '29.500'),
        const SizedBox(height: 28),

        GestureDetector(
          onTap: onReorder,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FC),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B48FC).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Mau lagi',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
