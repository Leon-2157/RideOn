import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// [ActivityShoppingDetailScreen]
/// Implementasi Layar Detail Aktivitas Titip Belanja (FlexSend Manual)
/// Sesuai spesifikasi Figma:
/// - Figma/HalamanAktivitas/aktivitas driver list.png
class ActivityShoppingDetailScreen extends StatefulWidget {
  final String customerName;
  final String location1Name;
  final String location2Name;
  final String parkingFee1;
  final String parkingFee2;
  final String destinationAddress;
  final String distanceTimeEstimate;

  const ActivityShoppingDetailScreen({
    super.key,
    this.customerName = 'Gufran',
    this.location1Name = 'Pasar Pagi Batuphat',
    this.location2Name = 'Apotik Dien Farma',
    this.parkingFee1 = 'Rp 2.000',
    this.parkingFee2 = 'Rp 2.000',
    this.destinationAddress = 'Jl. Lauser, PIM No. 88 (Gufran)',
    this.distanceTimeEstimate =
        'Total Jarak Tempuh: 4.2 km Estimasi: 10 menit',
  });

  @override
  State<ActivityShoppingDetailScreen> createState() =>
      _ActivityShoppingDetailScreenState();
}

class _ActivityShoppingDetailScreenState
    extends State<ActivityShoppingDetailScreen> {
  late TextEditingController _parking1Controller;
  late TextEditingController _parking2Controller;

  @override
  void initState() {
    super.initState();
    _parking1Controller = TextEditingController(text: widget.parkingFee1);
    _parking2Controller = TextEditingController(text: widget.parkingFee2);
  }

  @override
  void dispose() {
    _parking1Controller.dispose();
    _parking2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Header Bar dengan Curved Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B68FC),
                  Color(0xFFB4A1FF),
                  Color(0xFFEBE6FE),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.dark,
                          size: 22,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Titip Belanja',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // Konten Utama Scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Banner: Selesai
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Belanja & Pengantaran Selesai',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Hari ini, 09:15 WIB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF558B2F),
                        ),
                      ),
                    ],
                  ),
                ),

                // 1. Header Banner FlexSend & Pemesan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC6BCFF),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.all_inbox_rounded,
                            color: AppColors.dark,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'FlexSend',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                              Text(
                                'Titip Belanja Manual',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF555268),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Pemesanan: ${widget.customerName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Lokasi 1: Pasar Pagi Batuphat (4 Barang)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8E4F8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Lokasi & Jumlah Barang
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC6BCFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Lokasi 1: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Color(0xFF6B48FC),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.location1Name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '4 Barang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF525068),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Daftar Barang Belanja Lokasi 1
                      _buildShoppingItem(
                        number: '1.',
                        title: 'Daging Sapi (1 kg)',
                        price: 'Rp 120.000',
                        note: 'Catatan: Potong dadu rendang',
                      ),
                      _buildShoppingItem(
                        number: '2.',
                        title: 'Cabai Merah (1/2 kg)',
                        price: 'Rp 20.000',
                      ),
                      _buildShoppingItem(
                        number: '3.',
                        title: 'Bawang Merah (1/4 kg)',
                        price: 'Rp 10.000',
                      ),
                      _buildShoppingItem(
                        number: '4.',
                        title: 'Santan Instan (2 bks)',
                        price: 'Rp 6.000',
                      ),

                      const SizedBox(height: 8),

                      // Input Biaya Retribusi Parkir Pasar
                      const Text(
                        'Biaya Retribusi Parkir Pasar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _parking1Controller.text,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFC6BCFF),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Color(0xFF6B48FC),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD8D2FF),
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+ png1234567899',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7B7890),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '#Kosong kan saja jika tidak ada parkir',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7B7890),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Lokasi 2: Apotik Dien Farma (1 Barang)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8E4F8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Lokasi & Jumlah Barang
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC6BCFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Lokasi 1: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Color(0xFF6B48FC),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.location2Name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '1 Barang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF525068),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Item Apotik
                      _buildShoppingItem(
                        number: '1.',
                        title: 'Paracetamol (1 Papan)',
                        price: 'Rp 10.000',
                      ),

                      const SizedBox(height: 8),

                      // Input Biaya Retribusi Parkir Pasar
                      const Text(
                        'Biaya Retribusi Parkir Pasar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _parking2Controller.text,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFC6BCFF),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Color(0xFF6B48FC),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD8D2FF),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '+ png1234567899',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7B7890),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '#Kosong kan saja jika tidak ada parkir',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7B7890),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Ringkasan Biaya
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFC6BCFF),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow('Total', 'Rp 166.000'),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        'Total Retribusi Parkir',
                        'Rp 2.000',
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        'Ongkir Driver',
                        '+ Rp 15.000',
                        valueColor: const Color(0xFF00A838),
                        isBold: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: Color(0xFF4A4760),
                          thickness: 1,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB4A1FF),
                            ),
                          ),
                          Text(
                            'Rp 183.000',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB4A1FF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Pajak Batuphat & Info Pengantaran
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFC6BCFF),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pajak batuphat (4 Item)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Apotek Kimia Farma (1 Item)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.destinationAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555268),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.distanceTimeEstimate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7B7890),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Kartu Bantuan Pesanan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E5F2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF6B48FC),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ada kendala belanja atau retribusi nota?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A4660),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF86829D),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItem({
    required String number,
    required String title,
    required String price,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$number $title',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7B7890),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.dark,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.dark,
          ),
        ),
      ],
    );
  }
}
