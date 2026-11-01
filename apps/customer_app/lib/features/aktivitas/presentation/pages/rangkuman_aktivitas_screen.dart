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
  late int _foodRating;
  late int _driverRating;

  @override
  void initState() {
    super.initState();
    _foodRating = widget.activity['foodRating'] as int? ?? 5;
    _driverRating = widget.activity['driverRating'] as int? ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradient horizontal lavender (#9F88FD) ke putih (#FFFFFF) presisi Figma node [44:9005]
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9F88FD),
                  Color(0xFFBAA7FD),
                  Color(0xFFEFEAFF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.45, 0.85, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 63,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF1E143E),
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
                          color: const Color(0xFF1E143E),
                        ),
                      ),
                      const Spacer(),
                      StatefulBuilder(
                        builder: (context, setFavState) {
                          final bool isFav =
                              widget.activity['isFav'] == true;
                          return IconButton(
                            icon: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav
                                  ? const Color(0xFF6B48FC)
                                  : const Color(0xFF1E143E),
                              size: 24,
                            ),
                            onPressed: () {
                              setFavState(() {
                                widget.activity['isFav'] = !isFav;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
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

                  // Rating Card (Fixed / Read-Only yang sudah dinilai sebelumnya)
                  ActivityRatingCard(
                    foodRating: _foodRating,
                    driverRating: _driverRating,
                    driverName: widget.activity['driver'] as String,
                    vehicleInfo: widget.activity['vehicle'] as String,
                    serviceType: widget.activity['service'] as String,
                    isReadOnly: true,
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
