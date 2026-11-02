import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';
import 'location_card_widget.dart';

class ShoppingFormView extends StatelessWidget {
  final List<FlexSendLocation> locations;
  final VoidCallback onAddLocation;
  final Function(int locationIndex) onDeleteLocation;
  final Function(int locationIndex) onAddItem;
  final VoidCallback onStartSearching;
  final VoidCallback? onBack;
  final int baseOngkir;
  final int extraStopFee;
  final int itemQuotaFee;
  final int totalOngkir;
  final int totalTalangan;
  final int totalBayar;

  const ShoppingFormView({
    super.key,
    required this.locations,
    required this.onAddLocation,
    required this.onDeleteLocation,
    required this.onAddItem,
    required this.onStartSearching,
    this.onBack,
    required this.baseOngkir,
    required this.extraStopFee,
    required this.itemQuotaFee,
    required this.totalOngkir,
    required this.totalTalangan,
    required this.totalBayar,
  });

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

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
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: color ?? const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Syarat tombol aktif: minimal ada 1 lokasi, dan SEMUA lokasi yang ditambahkan wajib memiliki minimal 1 barang
    final bool hasEmptyLocation = locations.any((loc) => loc.items.isEmpty);
    final bool isReadyToSearch = locations.isNotEmpty && !hasEmptyLocation;

    final int totalItemCount = locations.fold(0, (sum, loc) => sum + loc.items.length);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Gradasi Lavender ke Putih Presisi Figma
          FlexSendHeader(title: 'FlexSend', onBack: onBack),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: FlexSend Titip Belanja Manual
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.inventory_2_rounded,
                            size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FlexSend',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Titip Belanja Manual',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: const Color(0xFF6B6680)),
                  ),
                  const SizedBox(height: 12),

                  // Shield Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC6BCFF)),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/illustrations/il_driver_talangi.png',
                          width: 24,
                          height: 29,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2DCFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF6B48FC),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Talangi Dulu di Tempat',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Batas talangan tunai belanja driver maks. Rp 300.000',
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
                  const SizedBox(height: 14),

                  // Empty State: Jika belum ada lokasi toko/pasar yang ditambahkan
                  if (locations.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2DCFE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EFFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 34,
                              color: Color(0xFF6B48FC),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Belum Ada Toko Belanja',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tambahkan pasar atau toko tempat driver akan membelikan barang pesananmu.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              color: const Color(0xFF6B6680),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: onAddLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B48FC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_location_alt_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+ Masukkan Toko / Pasar Pertama',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
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
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Tampilkan List Lokasi yang telah ditambahkan
                    ...List.generate(locations.length, (index) {
                      final loc = locations[index];
                      final locNumber = index + 1;
                      final isFirst = index == 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: LocationCardWidget(
                          locationIndex: locNumber,
                          locationName: loc.name,
                          badgeText: isFirst
                              ? 'Lokasi 1 (Pasar Utama)'
                              : 'Lokasi $locNumber (+Rp 2.000 Ongkir)',
                          badgeColor: isFirst
                              ? const Color(0xFFD8E7FE)
                              : const Color(0xFFFFECC8),
                          items: loc.items,
                          onAddItem: () => onAddItem(index),
                          onDeleteLocation: isFirst ? null : () => onDeleteLocation(index),
                        ),
                      );
                    }),

                    // Add Location Button (Hanya jika belum mencapai 3 lokasi)
                    if (locations.length < 3) ...[
                      GestureDetector(
                        key: const Key('btn_add_location'),
                        onTap: onAddLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF6B48FC)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 16, color: Color(0xFF6B48FC)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '+ Tambah Lokasi Singgah Lain (Maks. 3 Tempat)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Rincian Ongkos Kirim Aplikasi Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2DCFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ongkos Kirim Aplikasi',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildPriceRow(
                              'Ongkos Kirim Dasar', 'Rp ${_formatRupiah(baseOngkir)}'),
                          if (extraStopFee > 0) ...[
                            const SizedBox(height: 6),
                            _buildPriceRow(
                                'Biaya Singgah Tambahan',
                                '+Rp ${_formatRupiah(extraStopFee)}',
                                color: const Color(0xFF6B48FC)),
                          ],
                          if (itemQuotaFee > 0) ...[
                            const SizedBox(height: 6),
                            _buildPriceRow(
                                'Biaya Kuota Barang (>3 item)',
                                '+Rp ${_formatRupiah(itemQuotaFee)}',
                                color: const Color(0xFF6B48FC)),
                          ],
                          const Divider(height: 20, color: Color(0xFFE2DCFE)),
                          _buildPriceRow(
                            'Total Ongkir Aplikasi',
                            'Rp ${_formatRupiah(totalOngkir)}',
                            isBold: true,
                            color: const Color(0xFF6B48FC),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Catatan Driver info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F8FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF6B48FC)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFF6B48FC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Harga belanja akan disesuaikan dengan struk asli pembelian oleh driver.',
                              style: GoogleFonts.roboto(
                                fontSize: 10.5,
                                color: const Color(0xFF6B6680),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Titip Belanja',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalItemCount Barang (${locations.length} Toko)',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: !isReadyToSearch
                        ? () {
                            String message = 'Silakan masukkan toko dan barang belanjaan terlebih dahulu';
                            if (locations.isEmpty) {
                              message = 'Silakan masukkan minimal 1 toko belanja';
                            } else if (hasEmptyLocation) {
                              message = 'Setiap tempat belanja wajib memiliki minimal 1 barang';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: const Color(0xFF6B48FC),
                              ),
                            );
                          }
                        : onStartSearching,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: !isReadyToSearch
                            ? const Color(0xFFB0B0C0)
                            : const Color(0xFF17152B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Cari Driver Belanja',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
