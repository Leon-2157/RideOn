import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Halaman Aktivitas strictly based on Figma node [44:9005]:
/// - Aktivitas.png: List of transaction cards (FlexFood, FlexRide) with dates and prices
/// - Rangkuman Aktivitas.png & rate makanan driver.png: Dedicated full screen receipt & rating
class AktivitasScreen extends StatelessWidget {
  const AktivitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'service': 'FlexFood',
        'title': 'Nasi Goreng Mas Fuad',
        'items': 'Nasi Goreng Mas Fuad (1x Nasi goreng + telur mata sapi, 1x Es teh hijau)',
        'price': 'Rp 29.500',
        'date': '28, Sep 2026, 07:21',
        'icon': Icons.lunch_dining_rounded,
        'driver': 'Gufran Fadlurrahman',
        'vehicle': 'Honda supra | BL67SI',
        'metode': 'Bayar Pakai Cash',
      },
      {
        'service': 'FlexRide',
        'title': 'Perjalanan Ojek Motor',
        'items': 'Perjalanan Dari Kreung Geukueh ke Kampus Unimal Reulet',
        'price': 'Rp 19.500',
        'date': '15, Jan 2026, 20:21',
        'icon': Icons.two_wheeler_rounded,
        'driver': 'Pikri Haykal',
        'vehicle': 'Honda Vario 160 | BG 4563 R',
        'metode': 'Bayar Pakai Cash',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple gradient header with RideOn logo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Image.asset(
                    AppAssets.logoWhite,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Riwayat Aktivitas',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Activities List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final act = activities[index];
                return _buildActivityCard(context, act);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> act) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC7BCFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RangkumanAktivitasScreen(activity: act),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Circle Icon (matching Figma Aktivitas.png)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7BCFE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF17152B),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    act['icon'] as IconData,
                    color: const Color(0xFF17152B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Date, Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act['title'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        act['items'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            act['date'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          Text(
                            act['price'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Halaman Rangkuman Aktivitas strictly based on Figma [Rangkuman Aktivitas.png] & [rate makanan driver.png]:
/// - Header gradient purple with back arrow and title 'Rangkuman Aktivitas'
/// - Order status header with transaction ID & copy action
/// - Interactive Star Rating for Food and Driver
/// - Driver information card (Gufran Fadlurrahman, Honda supra BL67SI)
/// - Loyalty benefit card ('Keuntungan buat kamu')
/// - Delivery details with connected route markers
/// - Purchase breakdown and payment summary
/// - 'Mau lagi' primary re-order button
class RangkumanAktivitasScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const RangkumanAktivitasScreen({
    super.key,
    required this.activity,
  });

  @override
  State<RangkumanAktivitasScreen> createState() => _RangkumanAktivitasScreenState();
}

class _RangkumanAktivitasScreenState extends State<RangkumanAktivitasScreen> {
  int _foodRating = 5; // Default 5 matching rate makanan driver.png
  int _driverRating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple Gradient Header with Back Arrow and Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 16, left: 16, right: 16),
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Rangkuman Aktivitas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Receipt Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transaction Meta Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.activity['service'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          Text(
                            'Makanan sudah diantar',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '28 Sep, 08.13',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Transaksi F-120707',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(const ClipboardData(text: 'F-120707'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID Transaksi berhasil disalin!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: Color(0xFF17152B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Rating Card (figma/HalamanAktivitas/rate makanan driver.png)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Nilai makanannya, yuk!',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final filled = index < _foodRating;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _foodRating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 28,
                                  color: filled ? const Color(0xFFFFCC00) : const Color(0xFF17152B),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),
                        Text(
                          'Jangan lupa rating driver, ya',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final filled = index < _driverRating;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _driverRating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 28,
                                  color: filled ? const Color(0xFFFFCC00) : const Color(0xFF17152B),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Driver Profile Info
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 1.5),
                                image: const DecorationImage(
                                  image: AssetImage(AppAssets.driverGufran),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.activity['driver'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                                Text(
                                  widget.activity['vehicle'] as String,
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Loyalty Card ('Keuntungan buat kamu')
                  Text(
                    'Keuntungan buat kamu',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6B48FC),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plus',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        Text(
                          'Pasti diskon s.d. 15rb buat FlexFood dan layanan lainnya!',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Divider(height: 20, color: Color(0xFFE2E8F0)),
                        Text(
                          'FlexStar',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        Text(
                          'Dapatin benefit premium gratis!',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detail Pengantaran
                  Text(
                    'Detail pengantaran',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.restaurant_rounded,
                            size: 18,
                            color: Color(0xFFEB5757),
                          ),
                          Container(
                            width: 1.5,
                            height: 28,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: const Color(0xFFCBD5E1),
                          ),
                          const Icon(
                            Icons.radio_button_checked_rounded,
                            size: 18,
                            color: Color(0xFFEB5757),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat restoran',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              'Nasi Goreng Mas Fuad, Kreung Geukueh',
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Alamat pengiriman • 1 km',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              'Kos Dokter Gufran, Kreung Geukueh',
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFE2E8F0)),

                  // Pembelian
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

                  // Detail Pembayaran
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
                  _buildReceiptRow(widget.activity['metode'] as String, '29.500'),
                  const SizedBox(height: 28),

                  // Bottom Button: 'Mau lagi' (figma/HalamanAktivitas/Rangkuman Aktivitas.png)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
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
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
