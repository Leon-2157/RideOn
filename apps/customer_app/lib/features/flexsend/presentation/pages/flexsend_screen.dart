import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/pages/chat_screen.dart';

/// Halaman FlexSend strictly matching Figma designs in figma/HalamanFlexSend:
/// - flrxsend.png / flrxsend-6.png: Titip Belanja Manual, locations, items, price estimation
/// - flrxsend-7.png: Tambah Barang Belanjaan modal sheet
/// - cari driver.png: Radar search simulation
/// - beli brng.png: Driver shopping in progress
/// - driver sampai.png: Driver delivering to home & completed order
class FlexSendScreen extends StatefulWidget {
  const FlexSendScreen({super.key});

  @override
  State<FlexSendScreen> createState() => _FlexSendScreenState();
}

enum FlexSendState {
  form, // flrxsend.png / flrxsend-6.png
  searching, // cari driver.png
  shopping, // beli brng.png
  delivering, // driver sampai.png
}

class FlexSendItem {
  final String name;
  final int qty;
  final int price;
  final String notes;

  FlexSendItem({
    required this.name,
    required this.qty,
    required this.price,
    this.notes = '',
  });
}

class _FlexSendScreenState extends State<FlexSendScreen>
    with SingleTickerProviderStateMixin {
  FlexSendState _currentState = FlexSendState.form;

  // Shopping items in Location 1
  final List<FlexSendItem> _location1Items = [
    FlexSendItem(
      name: 'Daging Sapi (1 kg)',
      qty: 1,
      price: 120000,
      notes: 'Potong rendang',
    ),
    FlexSendItem(
      name: 'Cabai Merah (1/2 kg)',
      qty: 1,
      price: 20000,
      notes: 'Pilih yang segar',
    ),
    FlexSendItem(
      name: 'Bawang Merah (1/4 kg)',
      qty: 1,
      price: 10000,
    ),
    FlexSendItem(
      name: 'Santan Instan (2 bks)',
      qty: 2,
      price: 6000,
    ),
  ];

  // Shopping items in Location 2
  final List<FlexSendItem> _location2Items = [
    FlexSendItem(
      name: 'Minyak Kayu Putih 120ml (1 btl)',
      qty: 1,
      price: 25000,
    ),
  ];

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  int get _location1Subtotal =>
      _location1Items.fold(0, (sum, item) => sum + (item.price * item.qty));

  int get _location2Subtotal =>
      _location2Items.fold(0, (sum, item) => sum + (item.price * item.qty));

  int get _totalTalangan => _location1Subtotal + _location2Subtotal;
  int get _baseOngkir => 12000;
  int get _extraStopFee => _location2Items.isNotEmpty ? 2000 : 0;
  int get _totalOngkir => _baseOngkir + _extraStopFee;
  int get _totalBayar => _totalTalangan + _totalOngkir;

  void _showAddItemSheet(int locationIndex) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Tambah Barang Belanjaan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('close_add_item'),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Nama Barang
                    Text(
                      'Nama Barang',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6B48FC)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Daging Sapi Segar',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => nameController.clear(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Jumlah
                    Text(
                      'Jumlah',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EEFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2DCFE)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () {
                                  if (qty > 1) {
                                    setSheetState(() => qty--);
                                  }
                                },
                              ),
                              Text(
                                '$qty',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                                onPressed: () {
                                  setSheetState(() => qty++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Perkiraan Harga Satuan
                    Text(
                      'Perkiraan Harga Satuan',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DCFE)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Rp ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B48FC),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: const InputDecoration(
                                hintText: '120.000',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Catatan untuk Driver (Opsional)
                    Text(
                      'Catatan untuk Driver (Opsional)',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DCFE)),
                      ),
                      child: TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: GoogleFonts.roboto(fontSize: 12, color: const Color(0xFF17152B)),
                        decoration: const InputDecoration(
                          hintText: 'Tolong minta dipotong ukuran rendang ya mas...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Simpan Button
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final priceStr = priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                        final price = int.tryParse(priceStr) ?? 15000;
                        if (name.isNotEmpty) {
                          setState(() {
                            final newItem = FlexSendItem(
                              name: name,
                              qty: qty,
                              price: price,
                              notes: notesController.text.trim(),
                            );
                            if (locationIndex == 1) {
                              _location1Items.add(newItem);
                            } else {
                              _location2Items.add(newItem);
                            }
                          });
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1832),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Simpan ke Daftar Belanja',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case FlexSendState.form:
        return _buildFormScreen();
      case FlexSendState.searching:
        return _buildSearchingScreen();
      case FlexSendState.shopping:
        return _buildShoppingScreen();
      case FlexSendState.delivering:
        return _buildDeliveringScreen();
    }
  }

  // -------------------------------------------------------------------------
  // 1. Form Screen (flrxsend.png / flrxsend-6.png)
  // -------------------------------------------------------------------------
  Widget _buildFormScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFlexSendHeader('Beranda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Section
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF17152B)),
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
                    style: GoogleFonts.roboto(fontSize: 11, color: const Color(0xFF6B6680)),
                  ),
                  const SizedBox(height: 12),

                  // Shield Info Card (Driver Talangi Dulu di Tempat)
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
                            color: const Color(0xFFE6E0FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: Color(0xFF6B48FC),
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
                                  fontSize: 10,
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
                  _buildLocationCard(
                    locationIndex: 1,
                    locationName: 'Pasar Pagi Batuphat',
                    badgeText: 'Lokasi 1 (Pasar Utama)',
                    badgeColor: const Color(0xFFD6E4FF),
                    items: _location1Items,
                  ),
                  const SizedBox(height: 14),

                  // Location 2 Card (if exists)
                  _buildLocationCard(
                    locationIndex: 2,
                    locationName: 'Pasar Pagi Batuphat',
                    badgeText: 'Lokasi 2 (+Rp 2.000 Ongkir)',
                    badgeColor: const Color(0xFFFFECC8),
                    items: _location2Items,
                  ),
                  const SizedBox(height: 14),

                  // Add Location Button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lokasi singgah maksimal 3 tempat')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6B48FC)),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPriceRow('Ongkir Jarak Tempuh (3.5 km)', 'Rp $_baseOngkir'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Tambahan Toko ke-2', '+Rp $_extraStopFee'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Biaya Kuota (Item ke-4 s/d 5)', 'Rp 0'),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2DCFE)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Total Ongkos Kirim Driver',
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rp $_totalOngkir',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Estimasi Talangan Belanja',
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rp $_totalTalangan',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Catatan: Karcis parkir riil (maks. Rp 2.000/tempat) akan dimasukkan ke struk.',
                          style: GoogleFonts.roboto(fontSize: 9.5, color: const Color(0xFF6B6680)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
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
                        'Rp $_totalBayar',
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
                  onPressed: () {
                    setState(() {
                      _currentState = FlexSendState.searching;
                      _radarController.repeat();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1832),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildLocationCard({
    required int locationIndex,
    required String locationName,
    required String badgeText,
    required Color badgeColor,
    required List<FlexSendItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.roboto(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
              ),
              Text(
                '${items.length} Barang',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6680),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location Pin + Name
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF6B48FC), size: 18),
              const SizedBox(width: 8),
              Text(
                locationName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          ...items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$idx. ',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        if (item.notes.isNotEmpty)
                          Text(
                            'Catatan: ${item.notes}',
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${item.price * item.qty}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Add Item Button inside card
          GestureDetector(
            onTap: () => _showAddItemSheet(locationIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2DCFE)),
              ),
              child: Center(
                child: Text(
                  locationIndex == 1
                      ? '+ Tambah Barang di Pasar Ini'
                      : '+ Tambah Barang di Toko Ini',
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B48FC),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(fontSize: 11.5, color: const Color(0xFF17152B)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 2. Searching Screen (cari driver.png)
  // -------------------------------------------------------------------------
  Widget _buildSearchingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Concentric Radar Waves
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 + (_radarController.value * 80),
                        height: 140 + (_radarController.value * 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6B48FC)
                                .withValues(alpha: 1.0 - _radarController.value),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 90 + (_radarController.value * 50),
                        height: 90 + (_radarController.value * 50),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6B48FC)
                                .withValues(alpha: 0.8 - (_radarController.value * 0.5)),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B48FC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () {
                _radarController.stop();
                setState(() => _currentState = FlexSendState.form);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF17152B)),
              ),
            ),
          ),

          // Bottom Search Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: Color(0xFFC7BCFE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B48FC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mencari Driver...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mencari Driver yang aktif dan bersedia!',
                    style: GoogleFonts.roboto(
                      fontSize: 11.5,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Titip Belanja Pasar Pagi Batuphat Rp $_totalBayar',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Button to simulate driver found
                  GestureDetector(
                    onTap: () {
                      _radarController.stop();
                      setState(() {
                        _currentState = FlexSendState.shopping;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Simulasi: Driver Ditemukan (Lanjut Belanja) ➔',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B48FC),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  OutlinedButton(
                    onPressed: () {
                      _radarController.stop();
                      setState(() => _currentState = FlexSendState.form);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE83535)),
                      foregroundColor: const Color(0xFFE83535),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'BATALKAN PEMESANAN',
                      style: GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700),
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

  // -------------------------------------------------------------------------
  // 3. Shopping Screen (beli brng.png)
  // -------------------------------------------------------------------------
  Widget _buildShoppingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => setState(() => _currentState = FlexSendState.form),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF17152B)),
              ),
            ),
          ),

          // Bottom Shopping Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFC7BCFE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Banner (Yellow: Sedang Membelanjakan Barang)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2D1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE082),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_cart_rounded, size: 18, color: Color(0xFF8D6E00)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Sedang Membelanjakan Barang',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8D6E00),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Di Pasar Pagi Batuphat (Lokasi 1 dari 2)',
                                style: GoogleFonts.roboto(fontSize: 10.5, color: const Color(0xFF8D6E00)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Profile Card
                  _buildDriverCard(),
                  const SizedBox(height: 14),

                  // Next Step button (to Delivering)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentState = FlexSendState.delivering;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1832),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Simulasi: Belanja Selesai ➔ Antar ke Rumah',
                      style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700),
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

  // -------------------------------------------------------------------------
  // 4. Delivering Screen (driver sampai.png)
  // -------------------------------------------------------------------------
  Widget _buildDeliveringScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => setState(() => _currentState = FlexSendState.form),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF17152B)),
              ),
            ),
          ),

          // Bottom Delivering Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFC7BCFE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Banner (Green: Belanja Selesai)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F7DF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF28A745)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 28, color: Color(0xFF28A745)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Belanja selesai, menuju rumah anda!',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E7E34),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estimasi tiba: 8-12 menit (Jarak 2.1 km)',
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
                  const SizedBox(height: 10),

                  // Info Box: Belanjaan lengkap
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Belanjaan lengkap (5 item) Siapkan uang tunai / E-Wallet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Card
                  _buildDriverCard(),
                  const SizedBox(height: 16),

                  // Selesai Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentState = FlexSendState.form;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SELESAI',
                      style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Driver Photo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6B48FC), width: 2),
              image: const DecorationImage(
                image: AssetImage(AppAssets.driverLuthfi),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and vehicle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pikri Haykal',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1832),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BG 4563 R',
                        style: GoogleFonts.roboto(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Honda Vario 160 Hitam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: const Color(0xFF6B6680),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6B48FC)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),

          // Call button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4F7DF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_rounded, color: Color(0xFF28A745), size: 16),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menghubungi Pikri Haykal...')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Shared Header for FlexSend
  Widget _buildFlexSendHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB4A5FE),
            Color(0xFFE2DCFE),
            Color(0xFFF7F5FF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF17152B),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
        ),
      ),
    );
  }
}
