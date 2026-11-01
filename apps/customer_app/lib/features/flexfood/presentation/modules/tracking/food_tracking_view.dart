import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/features/chat/presentation/modules/call/voice_call_overlay.dart';
import 'package:rideon/features/chat/presentation/pages/chat_screen.dart';
import '../header/flexfood_header.dart';

class FoodTrackingView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final String restaurantName;
  final String foodTitle;
  final int cartQuantity;
  final int totalPrice;
  final String deliveryLabel;
  final String deliveryAddress;

  const FoodTrackingView({
    super.key,
    required this.onBack,
    required this.onFinish,
    this.restaurantName = 'Banku City Resto & Cafe',
    this.foodTitle = 'Nasi Goreng Spesial',
    this.cartQuantity = 1,
    this.totalPrice = 37000,
    this.deliveryLabel = 'Rumah',
    this.deliveryAddress = 'Jl. Brawl No. 77',
  });

  @override
  State<FoodTrackingView> createState() => _FoodTrackingViewState();
}

class _FoodTrackingViewState extends State<FoodTrackingView> {
  int _trackingStep = 0;
  Timer? _timer;

  static const List<String> statusTitles = [
    'Driver Menuju Restoran...',
    'Driver Menunggu Makanan...',
    'Driver Sedang Mengantar...',
    'Pesanan Telah Sampai!',
  ];

  static const List<double> progressValues = [0.25, 0.50, 0.80, 1.0];

  @override
  void initState() {
    super.initState();
    _startAutoSimulation();
  }

  void _startAutoSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_trackingStep < 3) {
        setState(() {
          _trackingStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _currentDescription {
    switch (_trackingStep) {
      case 0:
        return 'Driver Muhammad Luthfi sedang menuju ${widget.restaurantName}. Estimasi tiba 4 mnt.';
      case 1:
        return 'Driver sudah di restoran. Makanan sedang disiapkan oleh ${widget.restaurantName}.';
      case 2:
        return 'Makanan siap! Driver sedang dalam perjalanan ke ${widget.deliveryLabel} (${widget.deliveryAddress}).';
      case 3:
      default:
        return 'Driver telah sampai di ${widget.deliveryLabel}! Silakan ambil pesanan Anda.';
    }
  }

  void _openContactDriverSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2DCFE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hubungi Muhammad Luthfi Fadil',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded,
                      color: Color(0xFF6B48FC), size: 22),
                ),
                title: Text(
                  'Kirim Pesan Chat',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF17152B),
                  ),
                ),
                subtitle: Text(
                  'Gratis via koneksi internet aplikasi',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: const Color(0xFF6B6680)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF6B6680)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const ChatScreen()),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1EEFF)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4F7DF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_rounded,
                      color: Color(0xFF28A745), size: 22),
                ),
                title: Text(
                  'Panggilan Suara Driver',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF17152B),
                  ),
                ),
                subtitle: Text(
                  'Panggilan langsung ke driver pengantar',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: const Color(0xFF6B6680)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF6B6680)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'VoiceCall',
                    barrierColor: Colors.black.withValues(alpha: 0.35),
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (dialogContext, anim1, anim2) {
                      return const VoiceCallOverlay();
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderCompletedDialog(BuildContext context) {
    int givenDriverRating = 0;
    int givenRestoRating = 0;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'OrderCompletedDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final hasRatedBoth = givenDriverRating > 0 && givenRestoRating > 0;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lingkaran centang hijau
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F9EE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6CE19B),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Color(0xFF27AE60),
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Pesanan Selesai!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Makanan telah sampai dan diterima dengan baik.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Rincian Order Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F8FD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE8E5F5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDetailRow('Restoran', widget.restaurantName),
                              const SizedBox(height: 6),
                              _buildDetailRow(
                                  'Menu', '${widget.cartQuantity}x ${widget.foodTitle}'),
                              const SizedBox(height: 6),
                              _buildDetailRow('Driver',
                                  'Muhammad Luthfi Fadil (BK 789 M)'),
                              const SizedBox(height: 6),
                              _buildDetailRow('Alamat',
                                  '${widget.deliveryLabel} (${widget.deliveryAddress})'),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFFECEAF5),
                                ),
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Nomor Orderan',
                                      style: GoogleFonts.roboto(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'ORD-FD-882194',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: const Color(0xFF17152B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Total Pembayaran',
                                      style: GoogleFonts.roboto(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Rp ${widget.totalPrice}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF6B48FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 1. Bintang Penilaian Toko / Restoran
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beri Nilai Restoran',
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            if (givenRestoRating > 0)
                              Text(
                                '$givenRestoRating / 5',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = starIndex <= givenRestoRating;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  givenRestoRating = starIndex;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  isFilled
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 28,
                                  color: isFilled
                                      ? const Color(0xFFF1C40F)
                                      : const Color(0xFFC7BCFE),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),

                        // 2. Bintang Penilaian Driver
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beri Nilai Driver',
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            if (givenDriverRating > 0)
                              Text(
                                '$givenDriverRating / 5',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = starIndex <= givenDriverRating;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  givenDriverRating = starIndex;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  isFilled
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 28,
                                  color: isFilled
                                      ? const Color(0xFFF1C40F)
                                      : const Color(0xFFC7BCFE),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Button Selesai (Aktif jika kedua bintang toko & driver sudah dinilai)
                        GestureDetector(
                          onTap: hasRatedBoth
                              ? () {
                                  Navigator.of(dialogContext).pop();
                                  widget.onFinish();
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: hasRatedBoth
                                  ? const Color(0xFF17152B)
                                  : const Color(0xFFC4C2CF),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: hasRatedBoth
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                hasRatedBoth
                                    ? 'Selesai'
                                    : 'Beri Rating Restoran & Driver',
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: const Color(0xFF6B6680),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = _trackingStep == 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          FlexFoodHeader(
            title: 'Status Pesanan',
            onBack: widget.onBack,
          ),
          Expanded(
            child: Stack(
              children: [
                // 1. Live Interactive Simulated Map (Separuh Layar Atas)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: _FoodTrackingMap(
                    trackingStep: _trackingStep,
                    restaurantName: widget.restaurantName,
                    deliveryAddress: widget.deliveryAddress,
                  ),
                ),

                // 2. Floating Bottom Sheet Tracking (Separuh Layar Bawah)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: MediaQuery.of(context).size.height * 0.38,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Handle Bar
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2DCFE),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Status Header & Live Progress
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE2DCFE), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isFinished
                                            ? const Color(0xFFD4F7DF)
                                            : const Color(0xFFEDE8FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isFinished
                                            ? Icons.check_circle_rounded
                                            : Icons.delivery_dining_rounded,
                                        size: 22,
                                        color: isFinished
                                            ? const Color(0xFF28A745)
                                            : const Color(0xFF6B48FC),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            statusTitles[_trackingStep],
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF17152B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _currentDescription,
                                            style: GoogleFonts.roboto(
                                              fontSize: 11,
                                              color: const Color(0xFF6B6680),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progressValues[_trackingStep],
                                    backgroundColor: const Color(0xFFE2DCFE),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isFinished
                                          ? const Color(0xFF28A745)
                                          : const Color(0xFF6B48FC),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Driver Card (Luthfi Fadil + BK 789 M - Tanpa tombol ganda)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE2DCFE), width: 1),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF6B48FC),
                                            width: 1.5),
                                        image: const DecorationImage(
                                          image: AssetImage(
                                              AppAssets.driverLuthfi),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.star_rounded,
                                                size: 11,
                                                color: Color(0xFFFFB300)),
                                            Text(
                                              '4.9',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF17152B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Muhammad Luthfi Fadil',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF17152B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B1832),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'BK 789 M',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Honda Vario 160 Hitam',
                                            style: GoogleFonts.roboto(
                                              fontSize: 11,
                                              color: const Color(0xFF6B6680),
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
                          const SizedBox(height: 12),

                          // Rincian Pesanan Singkat Nyata
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE2DCFE), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    size: 18, color: Color(0xFF6B48FC)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${widget.cartQuantity}x ${widget.foodTitle}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rp ${widget.totalPrice}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B48FC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Tombol Utama Profesional (Panjang lebih ringkas & proporsional)
                          Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.78,
                              child: ElevatedButton(
                                onPressed: isFinished
                                    ? () => _showOrderCompletedDialog(context)
                                    : () => _openContactDriverSheet(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFinished
                                      ? const Color(0xFF28A745)
                                      : const Color(0xFF6B48FC),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isFinished
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.headset_mic_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFinished
                                          ? 'Pesanan Diterima (Selesai)'
                                          : 'Hubungi Driver',
                                      style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Peta Interaktif Simulasi Live Route FlexFood
class _FoodTrackingMap extends StatelessWidget {
  final int trackingStep;
  final String restaurantName;
  final String deliveryAddress;

  const _FoodTrackingMap({
    required this.trackingStep,
    required this.restaurantName,
    required this.deliveryAddress,
  });

  @override
  Widget build(BuildContext context) {
    // Posisi motor driver bergerak sesuai step (0: di jalan dekat resto, 1: di resto, 2: di tengah jalan, 3: sampai rumah)
    double driverLeftRatio = 0.32;
    double driverTopRatio = 0.50;

    if (trackingStep == 1) {
      driverLeftRatio = 0.22;
      driverTopRatio = 0.62;
    } else if (trackingStep == 2) {
      driverLeftRatio = 0.52;
      driverTopRatio = 0.38;
    } else if (trackingStep == 3) {
      driverLeftRatio = 0.76;
      driverTopRatio = 0.24;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Container(
          color: const Color(0xFFE5EDEB),
          child: Stack(
            children: [
              // Custom Road Network Painter
              CustomPaint(
                size: Size(w, h),
                painter: _FoodMapPainter(),
              ),

              // Pin Restoran Asal (Pojok Kiri Bawah)
              Positioned(
                left: w * 0.14,
                top: h * 0.60,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B48FC),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Text(
                        restaurantName.length > 15
                            ? '${restaurantName.substring(0, 14)}...'
                            : restaurantName,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17152B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pin Rumah Pelanggan (Pojok Kanan Atas)
              Positioned(
                left: w * 0.72,
                top: h * 0.16,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE83535),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Text(
                        deliveryAddress.length > 16
                            ? '${deliveryAddress.substring(0, 15)}...'
                            : deliveryAddress,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17152B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Marker Driver Bergerak Live
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOutCubic,
                left: w * driverLeftRatio,
                top: h * driverTopRatio,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17152B),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delivery_dining_rounded,
                          color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(
                        trackingStep == 3
                            ? 'Driver Sampai'
                            : 'Luthfi (${4 - trackingStep} mnt)',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
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
      },
    );
  }
}

class _FoodMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF0F3D39).withValues(alpha: 0.85)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final riverPaint = Paint()
      ..color = const Color(0xFFBCE3F7)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    // Sungai Latar
    final riverPath = Path()
      ..moveTo(0, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        size.width,
        size.height * 0.38,
      );
    canvas.drawPath(riverPath, riverPaint);

    // Jaringan Jalan Kota
    canvas.drawLine(
      Offset(size.width * 0.22, 0),
      Offset(size.width * 0.22, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, 0),
      Offset(size.width * 0.55, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, 0),
      Offset(size.width * 0.78, size.height),
      roadPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      roadPaint,
    );

    // Jalur Rute Ungu Terang dari Resto ke Rumah Pemesan
    final routePaint = Paint()
      ..color = const Color(0xFF6B48FC)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.65)
      ..lineTo(size.width * 0.55, size.height * 0.65)
      ..lineTo(size.width * 0.55, size.height * 0.25)
      ..lineTo(size.width * 0.78, size.height * 0.25);

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
