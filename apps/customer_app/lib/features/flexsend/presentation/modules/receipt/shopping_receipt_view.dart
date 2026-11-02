import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';
import '../tracking/driver_card_widget.dart';

class ShoppingReceiptView extends StatefulWidget {
  final List<FlexSendLocation> locations;
  final int baseOngkir;
  final int extraStopFee;
  final int itemQuotaFee;
  final int totalOngkir;
  final int totalTalangan;
  final int totalBayar;
  final VoidCallback onFinish;

  const ShoppingReceiptView({
    super.key,
    this.locations = const [],
    this.baseOngkir = 12000,
    this.extraStopFee = 0,
    this.itemQuotaFee = 0,
    this.totalOngkir = 12000,
    this.totalTalangan = 0,
    this.totalBayar = 12000,
    required this.onFinish,
  });

  @override
  State<ShoppingReceiptView> createState() => _ShoppingReceiptViewState();
}

class _ShoppingReceiptViewState extends State<ShoppingReceiptView> {
  // 'tunai', 'qris', null
  String? _selectedPaymentMethod;
  bool _isQrScannedAndPaid = false;
  Timer? _qrVerificationTimer;

  // Struk riil belanja yang diinput driver (realistis saat barang dibeli)
  late final Map<int, int> _driverActualReceiptPrices;

  @override
  void initState() {
    super.initState();
    _driverActualReceiptPrices = {};
    for (int i = 0; i < widget.locations.length; i++) {
      final loc = widget.locations[i];
      // Jika harga item masih 0, simulasikan harga riil dari nota struk driver
      if (loc.subtotal == 0) {
        // Misal estimasi harga riil belanjaan pasar 35.000 s/d 65.000 per toko
        _driverActualReceiptPrices[i] = 35000 + (loc.items.length * 15000);
      } else {
        _driverActualReceiptPrices[i] = loc.subtotal;
      }
    }
  }

  @override
  void dispose() {
    _qrVerificationTimer?.cancel();
    super.dispose();
  }

  int get _actualTotalTalangan {
    if (widget.locations.isEmpty) return 35000;
    return _driverActualReceiptPrices.values.fold(0, (sum, val) => sum + val);
  }

  int get _actualGrandTotal => _actualTotalTalangan + widget.totalOngkir;

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
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

  // Notifikasi pop-up pembayaran selesai dengan detail FlexSend & tombol selesai
  void _showCompletionDialog(BuildContext context) {
    int givenRating = 5;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Completed Dialog',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final orderNumber = 'ORD-FS-${Random().nextInt(899999) + 100000}';
            final methodLabel = _selectedPaymentMethod == 'qris'
                ? 'QRIS / Non-Tunai (Lunas)'
                : 'Tunai / Cash Langsung';

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                          width: 58,
                          height: 58,
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
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          'Pembayaran Selesai!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Belanjaan titipan Anda telah diterima dengan baik.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Order Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
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
                              _buildDialogRow(
                                'Layanan',
                                'FlexSend (Titip Belanja)',
                              ),
                              const SizedBox(height: 6),
                              _buildDialogRow(
                                'Mitra Driver',
                                'Pikri Haykal (BG 4563 R)',
                              ),
                              const SizedBox(height: 6),
                              _buildDialogRow(
                                'Toko Belanja',
                                widget.locations.isNotEmpty
                                    ? widget.locations
                                          .map((e) => e.name)
                                          .join(', ')
                                    : 'Pasar Pagi Batuphat',
                              ),
                              const SizedBox(height: 6),
                              _buildDialogRow('Metode Pembayaran', methodLabel),
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
                                      'Nomor Pesanan',
                                      style: GoogleFonts.roboto(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      orderNumber,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: const Color(0xFF17152B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Total Pelunasan',
                                      style: GoogleFonts.roboto(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                    Text(
                                      'Rp ${_formatRupiah(_actualGrandTotal)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
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

                        // Rating Driver Section (Bintang 5)
                        Text(
                          'Beri Nilai Driver',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (starIdx) {
                            final star = starIdx + 1;
                            return IconButton(
                              iconSize: 26,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              icon: Icon(
                                star <= givenRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFB300),
                              ),
                              onPressed: () {
                                setDialogState(() => givenRating = star);
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Tombol Selesai
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            key: const Key('btn_dialog_selesai_flexsend'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              widget.onFinish();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17152B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Selesai',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: const Color(0xFF6B6680),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.roboto(
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
    // Tombol aktif jika:
    // 1. Pilih tunai, ATAU
    // 2. Pilih QRIS dan QR sudah di-scan & saldo terverifikasi
    final bool canCompletePayment =
        _selectedPaymentMethod == 'tunai' ||
        (_selectedPaymentMethod == 'qris' && _isQrScannedAndPaid);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      body: Column(
        children: [
          // Header Gradien
          FlexSendHeader(title: 'Rincian Belanja', onBack: widget.onFinish),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner: Menunggu Pembayaran
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEAFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC6BCFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B48FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL RINCIAN BELANJA ASLI',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Driver telah melampirkan nota struk fisik pembelian',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  color: const Color(0xFF6B6680),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kartu Profil Driver
                  const DriverCardWidget(),
                  const SizedBox(height: 12),

                  // Kartu 1: Talangan Riil Driver (Struk Asli dari Driver)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BIAYA BELANJAAN',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Talangan Riil Driver',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (widget.locations.isEmpty)
                          _buildPriceRow(
                            'Nota Pasar Pagi Batuphat',
                            'Rp ${_formatRupiah(_actualTotalTalangan)}',
                          )
                        else
                          ...widget.locations.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final loc = entry.value;
                            final price =
                                _driverActualReceiptPrices[idx] ?? 35000;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildPriceRow(
                                'Nota Toko ${idx + 1}: ${loc.name} (${loc.items.length} item)',
                                'Rp ${_formatRupiah(price)}',
                              ),
                            );
                          }),

                        _buildPriceRow(
                          'Retribusi Parkir Belanja',
                          'Rp 0 (Gratis)',
                          color: const Color(0xFF28A745),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE2DCFE), height: 1),
                        ),
                        _buildPriceRow(
                          'Subtotal Uang Talangan:',
                          'Rp ${_formatRupiah(_actualTotalTalangan)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kartu 2: Ongkos Kirim Aplikasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ONGKOS KIRIM',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ongkos Kirim Aplikasi',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                          'Ongkir Rute Perjalanan',
                          'Rp ${_formatRupiah(widget.baseOngkir)}',
                        ),
                        if (widget.extraStopFee > 0) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow(
                            'Biaya Lokasi Singgah Tambahan',
                            'Rp ${_formatRupiah(widget.extraStopFee)}',
                          ),
                        ],
                        if (widget.itemQuotaFee > 0) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow(
                            'Biaya Kuota Item Tambahan',
                            'Rp ${_formatRupiah(widget.itemQuotaFee)}',
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE2DCFE), height: 1),
                        ),
                        _buildPriceRow(
                          'Subtotal Ongkir Driver:',
                          'Rp ${_formatRupiah(widget.totalOngkir)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total Pelunasan Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(16),
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
                            Text(
                              'Talangan Riil + Ongkir',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${_formatRupiah(_actualGrandTotal)}',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bagian Pilih Metode Pembayaran (Tunai & QRIS)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Metode Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Opsi 1: Tunai / Cash (Terkunci jika QRIS sudah terbayar/lunas)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isQrScannedAndPaid
                              ? null
                              : () {
                                  _qrVerificationTimer?.cancel();
                                  setState(() {
                                    _selectedPaymentMethod = 'tunai';
                                  });
                                },
                          child: Opacity(
                            opacity: _isQrScannedAndPaid ? 0.45 : 1.0,
                            child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'tunai'
                                  ? const Color(0xFFF2EFFF)
                                  : const Color(0xFFF9F8FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'tunai'
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFE9E4FF),
                                width: _selectedPaymentMethod == 'tunai'
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.money_rounded,
                                    size: 20,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tunai / Cash Langsung',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF17152B),
                                        ),
                                      ),
                                      Text(
                                        'Bayar langsung ke tangan driver di tempat',
                                        style: GoogleFonts.roboto(
                                          fontSize: 11,
                                          color: const Color(0xFF6B6680),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                  Icon(
                                    _selectedPaymentMethod == 'tunai'
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: _selectedPaymentMethod == 'tunai'
                                        ? const Color(0xFF6B48FC)
                                        : const Color(0xFFC6BCFF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Opsi 2: QRIS / Non-Tunai
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'qris';
                              _isQrScannedAndPaid = false;
                            });

                            // Sistem otomatis mengecek saldo masuk secara background (jeda 5 detik untuk testing)
                            _qrVerificationTimer?.cancel();
                            _qrVerificationTimer = Timer(
                              const Duration(seconds: 5),
                              () {
                                if (mounted &&
                                    _selectedPaymentMethod == 'qris') {
                                  setState(() {
                                    _isQrScannedAndPaid = true;
                                  });
                                }
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'qris'
                                  ? const Color(0xFFF2EFFF)
                                  : const Color(0xFFF9F8FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'qris'
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFE9E4FF),
                                width: _selectedPaymentMethod == 'qris'
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 20,
                                    color: Color(0xFF6B48FC),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QRIS (Non-Tunai)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF17152B),
                                        ),
                                      ),
                                      Text(
                                        'Scan barcode pembayaran ke driver',
                                        style: GoogleFonts.roboto(
                                          fontSize: 11,
                                          color: const Color(0xFF6B6680),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _selectedPaymentMethod == 'qris'
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: _selectedPaymentMethod == 'qris'
                                      ? const Color(0xFF6B48FC)
                                      : const Color(0xFFC6BCFF),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Area Barcode QRIS & Verifikasi Masuk Saldo
                        if (_selectedPaymentMethod == 'qris') ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F8FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2DCFE),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Scan QRIS Driver Pikri Haykal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nominal: Rp ${_formatRupiah(_actualGrandTotal)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B48FC),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Kotak QR Code Mockup
                                Container(
                                  width: 160,
                                  height: 160,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isQrScannedAndPaid
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF6B48FC),
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isQrScannedAndPaid
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF22C55E),
                                                size: 48,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Saldo Masuk & Lunas',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF22C55E,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Icon(
                                            Icons.qr_code_scanner_rounded,
                                            size: 96,
                                            color: Color(0xFF17152B),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Keterangan Verifikasi Otomatis Sistem
                                if (!_isQrScannedAndPaid)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF6B48FC),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Menunggu sistem mendeteksi pembayaran...',
                                        style: GoogleFonts.roboto(
                                          fontSize: 11,
                                          color: const Color(0xFF6B6680),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4F7DF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Color(0xFF1E7E34),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Saldo Berhasil Masuk ke Sistem',
                                          style: GoogleFonts.roboto(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E7E34),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!_isQrScannedAndPaid) ...[
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      _qrVerificationTimer?.cancel();
                                      setState(() {
                                        _selectedPaymentMethod = 'tunai';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2DCFE),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Color(0xFF6B6680),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Batal / Ganti ke Tunai',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF6B6680),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Pembayaran Selesai (Aktif jika syarat terpenuhi)
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 46,
                      child: ElevatedButton(
                        key: const Key('btn_pembayaran_selesai'),
                        onPressed: canCompletePayment
                            ? () => _showCompletionDialog(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17152B),
                          disabledBackgroundColor: const Color(0xFFCCC8E0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canCompletePayment
                                  ? Icons.check_circle_rounded
                                  : Icons.lock_outline_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pembayaran Selesai',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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
}
