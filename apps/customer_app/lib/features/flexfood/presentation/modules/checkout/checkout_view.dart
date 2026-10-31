import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import '../header/flexfood_header.dart';

class CheckoutView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAddMoreItems;
  final VoidCallback onPlaceOrder;
  final int cartQuantity;
  final int subtotalPrice;
  final int spicyLevel;
  final bool extraEgg;
  final String kitchenNotes;
  final int deliveryFee;
  final int serviceFee;
  final int totalPrice;

  const CheckoutView({
    super.key,
    required this.onBack,
    required this.onAddMoreItems,
    required this.onPlaceOrder,
    required this.cartQuantity,
    required this.subtotalPrice,
    required this.spicyLevel,
    required this.extraEgg,
    required this.kitchenNotes,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          FlexFoodHeader(
            title: '',
            onBack: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Diantar ke Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: Color(0xFF6B48FC),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diantar ke: Rumah (Jl. Brawl No. 77)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Catatan: Pagar hitam depan pos satpam',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  color: const Color(0xFF6B6680),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Ubah',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B48FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dapur Banku City',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cartQuantity}x Nasi Goreng Spesial',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Rp $subtotalPrice',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Level $spicyLevel ${extraEgg ? 'Ekstra Telur, ' : ''}Catatan: $kitchenNotes',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: onAddMoreItems,
                          child: Text(
                            '+ Tambah Pesanan Lain',
                            style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B48FC),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metode Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6B48FC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle,
                                  color: Color(0xFF17152B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Saldo E-Wallet (Rp 185.000)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                              ),
                              const Icon(Icons.radio_button_checked,
                                  color: Color(0xFF6B48FC), size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 30),
                              Expanded(
                                child: Text(
                                  'Bayar Tunai ke Driver',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: const Color(0xFF6B6680),
                                  ),
                                ),
                              ),
                              const Icon(Icons.radio_button_unchecked,
                                  color: AppColors.divider, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rincian Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPriceRow(
                            'Subtotal Makanan', 'Rp $subtotalPrice'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Ongkos Kirim Driver (1.2 km)', 'Rp $deliveryFee'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Biaya Layanan Aplikasi', 'Rp $serviceFee'),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2DCFE)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Rp $totalPrice',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sudah termasuk PPN resto & jaminan higienis',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: const Color(0xFF6B6680)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Button: Pesan Makanan Sekarang
                  ElevatedButton(
                    onPressed: onPlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1832),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Pesan Makanan Sekarang Rp $totalPrice',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
                fontSize: 11.5, color: const Color(0xFF17152B)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }
}
