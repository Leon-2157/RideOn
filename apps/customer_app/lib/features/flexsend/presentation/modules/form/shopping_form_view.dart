import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';
import 'location_card_widget.dart';

class ShoppingFormView extends StatelessWidget {
  final List<FlexSendItem> location1Items;
  final List<FlexSendItem> location2Items;
  final bool isLocation2Active;
  final VoidCallback onAddLocation;
  final VoidCallback onDeleteLocation2;
  final Function(int locationIndex) onAddItem;
  final VoidCallback onStartSearching;
  final int baseOngkir;
  final int extraStopFee;
  final int itemQuotaFee;
  final int totalOngkir;
  final int totalTalangan;
  final int totalBayar;

  const ShoppingFormView({
    super.key,
    required this.location1Items,
    required this.location2Items,
    required this.isLocation2Active,
    required this.onAddLocation,
    required this.onDeleteLocation2,
    required this.onAddItem,
    required this.onStartSearching,
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
    final totalItems =
        location1Items.length + (isLocation2Active ? location2Items.length : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const FlexSendHeader(title: 'Beranda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Section
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded,
                          size: 18, color: Color(0xFF17152B)),
                      const SizedBox(width: 8),
                      Text(
                        'FlexSend',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                    ],
                  ),
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
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2DCFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_outlined,
                              size: 20, color: Color(0xFF6B48FC)),
                        ),
                        const SizedBox(width: 10),
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

                  // Location 1 Card
                  LocationCardWidget(
                    locationIndex: 1,
                    locationName: 'Pasar Pagi Batuphat',
                    badgeText: 'Lokasi 1 (Pasar Utama)',
                    badgeColor: const Color(0xFFD8E7FE),
                    items: location1Items,
                    onAddItem: () => onAddItem(1),
                  ),
                  const SizedBox(height: 14),

                  // Location 2 Card
                  if (isLocation2Active) ...[
                    LocationCardWidget(
                      locationIndex: 2,
                      locationName: 'Apotek Kimia Farma',
                      badgeText: 'Lokasi 2 (+Rp 2.000 Ongkir)',
                      badgeColor: const Color(0xFFFFECC8),
                      items: location2Items,
                      onAddItem: () => onAddItem(2),
                      onDeleteLocation: onDeleteLocation2,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Add Location Button
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

                  // Rincian Estimasi Biaya Card
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
                          'Rincian Estimasi Biaya',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow('Ongkir Jarak Tempuh (3.5 km)',
                            'Rp ${_formatRupiah(baseOngkir)}'),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                            'Tambahan Toko ke-2',
                            isLocation2Active
                                ? '+Rp ${_formatRupiah(extraStopFee)}'
                                : 'Rp 0'),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                            'Biaya Kuota (Item ke-4 s/d 5)',
                            itemQuotaFee > 0
                                ? '+Rp ${_formatRupiah(itemQuotaFee)}'
                                : 'Rp 0'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Color(0xFFE2DCFE)),
                        ),
                        _buildPriceRow(
                          'Total Ongkos Kirim Driver',
                          'Rp ${_formatRupiah(totalOngkir)}',
                          isBold: true,
                          color: const Color(0xFF6B48FC),
                        ),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                          'Estimasi Talangan Belanja',
                          'Rp ${_formatRupiah(totalTalangan)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Catatan: Karcis parkir riil (maks. Rp 2.000/tempat) akan dimasukkan ke struk.',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Perkiraan Total Bayar',
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          color: const Color(0xFF6B6680),
                        ),
                      ),
                      Text(
                        totalItems > 0
                            ? 'Rp ${_formatRupiah(totalBayar)}'
                            : 'Rp -',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  key: const Key('btn_cari_driver_belanja'),
                  onPressed: totalItems > 0 ? onStartSearching : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1832),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cari Driver Belanja',
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
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
