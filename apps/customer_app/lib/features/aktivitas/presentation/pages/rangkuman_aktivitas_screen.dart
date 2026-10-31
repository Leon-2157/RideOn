import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../modules/receipt/activity_delivery_details.dart';
import '../modules/receipt/activity_loyalty_card.dart';
import '../modules/receipt/activity_payment_details.dart';
import '../modules/receipt/activity_rating_card.dart';

export '../modules/receipt/activity_delivery_details.dart';
export '../modules/receipt/activity_loyalty_card.dart';
export '../modules/receipt/activity_payment_details.dart';
export '../modules/receipt/activity_rating_card.dart';

class RangkumanAktivitasScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const RangkumanAktivitasScreen({
    super.key,
    required this.activity,
  });

  @override
  State<RangkumanAktivitasScreen> createState() =>
      _RangkumanAktivitasScreenState();
}

class _RangkumanAktivitasScreenState extends State<RangkumanAktivitasScreen> {
  int _foodRating = 0;
  int _driverRating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Pastel lavender gradient header with back button and high-contrast dark title
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB4A5FE),
                  Color(0xFFE2DCFE),
                  Color(0xFFF7F5FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E0FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF17152B),
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
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Receipt Content
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                                  Clipboard.setData(
                                      const ClipboardData(text: 'F-120707'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('ID Transaksi berhasil disalin!'),
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

                  // Rating Card
                  ActivityRatingCard(
                    foodRating: _foodRating,
                    driverRating: _driverRating,
                    onFoodRatingChanged: (val) =>
                        setState(() => _foodRating = val),
                    onDriverRatingChanged: (val) =>
                        setState(() => _driverRating = val),
                    driverName: widget.activity['driver'] as String,
                    vehicleInfo: widget.activity['vehicle'] as String,
                  ),
                  const SizedBox(height: 18),

                  // Loyalty Card
                  const ActivityLoyaltyCard(),
                  const SizedBox(height: 20),

                  // Detail Pengantaran
                  const ActivityDeliveryDetails(),
                  const Divider(height: 32, color: Color(0xFFE2E8F0)),

                  // Pembelian & Pembayaran
                  ActivityPaymentDetails(
                    paymentMethod: widget.activity['metode'] as String,
                    onReorder: () => Navigator.of(context).pop(),
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
