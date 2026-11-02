import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'vehicle_option_card.dart';

class VehicleSelectionSheet extends StatefulWidget {
  final String pickupText;
  final String destinationText;
  final String selectedVehicle;
  final int selectedVehiclePrice;
  final TextEditingController pickupNoteController;
  final Function(String vehicle, int price) onSelectVehicle;
  final VoidCallback onOrder;

  const VehicleSelectionSheet({
    super.key,
    required this.pickupText,
    required this.destinationText,
    required this.selectedVehicle,
    required this.selectedVehiclePrice,
    required this.pickupNoteController,
    required this.onSelectVehicle,
    required this.onOrder,
  });

  @override
  State<VehicleSelectionSheet> createState() => _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends State<VehicleSelectionSheet> {
  // 'tunai' atau 'qris'
  String _selectedPaymentMethod = 'tunai';
  bool _isQrScannedAndPaid = false;
  Timer? _qrTimer;

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  void _onSelectMethod(String method) {
    if (method == 'tunai') {
      if (_isQrScannedAndPaid) return; // Terkunci jika QR sudah lunas
      _qrTimer?.cancel();
      setState(() {
        _selectedPaymentMethod = 'tunai';
      });
    } else if (method == 'qris') {
      _qrTimer?.cancel();
      setState(() {
        _selectedPaymentMethod = 'qris';
        _isQrScannedAndPaid = false;
      });

      // Simulasi otomatis: sistem mengecek saldo masuk setelah 5 detik
      _qrTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _selectedPaymentMethod == 'qris') {
          setState(() {
            _isQrScannedAndPaid = true;
          });
        }
      });
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final bool canOrder = _selectedPaymentMethod == 'tunai' ||
        (_selectedPaymentMethod == 'qris' && _isQrScannedAndPaid);

    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFC6BCFF).withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
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

                // SECTION 1: LOKASI JEMPUT - LOKASI TUJUAN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Titik Jemput
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.pickupText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Divider(height: 1, color: Color(0xFFEFEAFF)),
                      ),
                      // Titik Tujuan
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE83535),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.destinationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SECTION 2: PILIHAN KENDARAAN
                VehicleOptionCard(
                  name: 'Flex Motor',
                  desc: 'Tercepat (1-2 mnt Penjemputan)',
                  price: 'Rp 14.000',
                  icon: Icons.two_wheeler_rounded,
                  isSelected: widget.selectedVehicle == 'Flex Motor',
                  onTap: () => widget.onSelectVehicle('Flex Motor', 14000),
                ),
                const SizedBox(height: 8),

                VehicleOptionCard(
                  name: 'Flex Mobil',
                  desc: 'Nyaman & ber-AC dingin',
                  price: 'Rp 30.000',
                  icon: Icons.directions_car_rounded,
                  isSelected: widget.selectedVehicle == 'Flex Mobil',
                  onTap: () => widget.onSelectVehicle('Flex Mobil', 30000),
                ),
                const SizedBox(height: 8),

                // Patokan Penjemputan (Optional Note)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 10),
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
                          controller: widget.pickupNoteController,
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: const Color(0xFF17152B),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'patokan penjemputan',
                            hintStyle: GoogleFonts.roboto(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // SECTION 3: METODE PEMBAYARAN (Tunai & QRIS)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode Pembayaran',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Opsi Tunai / Cash
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onSelectMethod('tunai'),
                        child: Opacity(
                          opacity: _isQrScannedAndPaid ? 0.45 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'tunai'
                                  ? const Color(0xFFF2EFFF)
                                  : const Color(0xFFF9F8FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'tunai'
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFE9E4FF),
                                width: _selectedPaymentMethod == 'tunai' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.money_rounded,
                                    size: 18, color: Color(0xFF22C55E)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tunai / Cash Langsung',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                ),
                                Icon(
                                  _selectedPaymentMethod == 'tunai'
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  size: 18,
                                  color: _selectedPaymentMethod == 'tunai'
                                      ? const Color(0xFF6B48FC)
                                      : const Color(0xFFC6BCFF),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Opsi QRIS
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onSelectMethod('qris'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod == 'qris'
                                ? const Color(0xFFF2EFFF)
                                : const Color(0xFFF9F8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPaymentMethod == 'qris'
                                  ? const Color(0xFF6B48FC)
                                  : const Color(0xFFE9E4FF),
                              width: _selectedPaymentMethod == 'qris' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code_2_rounded,
                                  size: 18, color: Color(0xFF6B48FC)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'QRIS (Non-Tunai)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                              ),
                              Icon(
                                _selectedPaymentMethod == 'qris'
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 18,
                                color: _selectedPaymentMethod == 'qris'
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFC6BCFF),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Barcode QRIS & Verifikasi Masuk Saldo
                      if (_selectedPaymentMethod == 'qris') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F8FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2DCFE)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Scan Barcode QRIS RideOn',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tarif: Rp ${_formatPrice(widget.selectedVehiclePrice)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Kotak QR Code
                              Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isQrScannedAndPaid
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF6B48FC),
                                    width: 1.5,
                                  ),
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
                                              size: 38,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Saldo Lunas',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF22C55E),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          size: 72,
                                          color: Color(0xFF17152B),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Status Verifikasi Sistem
                              if (!_isQrScannedAndPaid)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF6B48FC)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Menunggu sistem mendeteksi pembayaran...',
                                      style: GoogleFonts.roboto(
                                        fontSize: 10.5,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4F7DF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 14, color: Color(0xFF1E7E34)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Saldo Berhasil Masuk ke Sistem',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E7E34),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!_isQrScannedAndPaid) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _onSelectMethod('tunai'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
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
                                            fontSize: 10,
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
                const SizedBox(height: 12),

                // SECTION 4: TOMBOL ORDER (Aktif jika Tunai atau QRIS Lunas)
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 260,
                    height: 44,
                    child: ElevatedButton(
                      key: const Key('btn_pesan_flexride_order'),
                      onPressed: canOrder ? widget.onOrder : null,
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
                            canOrder
                                ? Icons.check_circle_rounded
                                : Icons.lock_outline_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pesan ${widget.selectedVehicle} Sekarang',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
    );
  }
}
