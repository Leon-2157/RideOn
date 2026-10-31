import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../header/flexsend_header.dart';

class ShoppingReceiptView extends StatelessWidget {
  final VoidCallback onFinish;

  const ShoppingReceiptView({
    super.key,
    required this.onFinish,
  });

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: color ?? const Color(0xFF17152B),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const FlexSendHeader(title: 'Beranda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Green Header Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F7DF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF28A745)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 32, color: Color(0xFF28A745)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PEMBAYARAN BERHASIL (LUNAS)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E7E34),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Menyerahkan uang cash ID: #TB-4091',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  color: const Color(0xFF1E7E34),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Komponen A: Talangan Riil Driver
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KOMPONEN A',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Talangan Riil Driver (Wajib Diganti)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                            'Nota Pasar Sukaramai (4 Item)', 'Rp 275.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Retribusi Parkir Pasar (Karcis)', 'Rp 2.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Nota Apotek Kimia Farma (1 Item)', 'Rp 25.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Parkir Apotek Kimia Farma', 'Rp 0 (Gratis)',
                            color: const Color(0xFF28A745)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE2DCFE)),
                        ),
                        _buildPriceRow(
                            'Subtotal Uang Talangan:', 'Rp 302.000',
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Komponen B: Ongkos Kirim Aplikasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KOMPONEN B',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A73E8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ongkos Kirim Aplikasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                            'Ongkir Rute Perjalanan (4.2 km)', 'Rp 12.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Tambahan 1 Toko Singgah', 'Rp 2.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Biaya Kuota (Item ke-4 s/d 5)', 'Rp 1.000'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE2DCFE)),
                        ),
                        _buildPriceRow('Subtotal Ongkir Driver:', 'Rp 15.000',
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total Pelunasan Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL PELUNASAN',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6B48FC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Metode: Cash',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          'Rp 317.000',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELESAI Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      key: const Key('btn_receipt_selesai'),
                      onPressed: onFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
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
