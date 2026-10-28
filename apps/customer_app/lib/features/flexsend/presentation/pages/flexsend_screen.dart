import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';

/// Halaman FlexSend strictly matching Figma designs in figma/HalamanFlexSend:
/// - flrxsend.png / flrxsend-4.png / flrxsend-5.png / flrxsend-6.png / flrxsend-7.png
/// - cari driver.png (radar pulse searching)
/// - dapat driver.png (driver found + "Lanjut dengan driver ini?")
/// - beli brng.png (driver shopping in store)
/// - driver sampai.png (driver on route to delivery)
/// - driver sampai-1.png (driver arrived + "Selesai dan Lihat Rincian Belanja")
/// - flrxsend-2.png (receipt / pelunasan tunai breakdown + "SELESAI")
class FlexSendScreen extends StatefulWidget {
  const FlexSendScreen({super.key});

  @override
  State<FlexSendScreen> createState() => _FlexSendScreenState();
}

enum FlexSendState {
  form,        // Form input belanjaan & lokasi
  searching,   // Radar mencari driver (cari driver.png)
  driverFound, // Driver ditemukan (dapat driver.png)
  shopping,    // Driver belanja di pasar/toko (beli brng.png)
  delivering,  // Driver dalam perjalanan mengantar (driver sampai.png)
  arrived,     // Driver telah sampai di lokasi (driver sampai-1.png)
  receipt,     // Rincian pelunasan belanja (flrxsend-2.png)
}

class FlexSendItem {
  final String name;
  final int qty;
  final int price;
  final String? notes;

  FlexSendItem({
    required this.name,
    required this.qty,
    required this.price,
    this.notes,
  });
}

class _FlexSendScreenState extends State<FlexSendScreen>
    with SingleTickerProviderStateMixin {
  FlexSendState _currentState = FlexSendState.form;

  // Shopping items in Location 1 (Pasar Pagi Batuphat)
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

  // Shopping items in Location 2 (Apotek Kimia Farma / Lokasi Tambahan)
  bool _isLocation2Active = true;
  final List<FlexSendItem> _location2Items = [
    FlexSendItem(
      name: 'Minyak Kayu Putih 120ml (1 btl)',
      qty: 1,
      price: 25000,
    ),
  ];

  late AnimationController _radarController;
  Timer? _searchTimer;

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
    _searchTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  int get _location1Subtotal =>
      _location1Items.fold(0, (sum, item) => sum + (item.price * item.qty));

  int get _location2Subtotal => _isLocation2Active
      ? _location2Items.fold(0, (sum, item) => sum + (item.price * item.qty))
      : 0;

  int get _totalTalangan => _location1Subtotal + _location2Subtotal;
  int get _baseOngkir => 12000;
  int get _extraStopFee => _isLocation2Active ? 2000 : 0;
  int get _itemQuotaFee =>
      ((_location1Items.length + (_isLocation2Active ? _location2Items.length : 0)) >= 4)
          ? 1000
          : 0;
  int get _totalOngkir => _baseOngkir + _extraStopFee + _itemQuotaFee;
  int get _totalBayar => _totalTalangan + _totalOngkir;

  void _startSearching() {
    setState(() {
      _currentState = FlexSendState.searching;
      _radarController.repeat();
    });

    // Automatically transition to driver found after 2.5s for seamless prototype flow
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _currentState == FlexSendState.searching) {
        _radarController.stop();
        setState(() {
          _currentState = FlexSendState.driverFound;
        });
      }
    });
  }

  void _cancelSearching() {
    _searchTimer?.cancel();
    _radarController.stop();
    setState(() {
      _currentState = FlexSendState.form;
    });
  }

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
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6D6D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Tambah Barang Belanjaan',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('close_add_item'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Nama Barang',
                        style: GoogleFonts.roboto(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('input_item_name'),
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Daging Sapi Segar',
                        filled: true,
                        fillColor: const Color(0xFFF7F5FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFC6BCFF)),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Jumlah',
                        style: GoogleFonts.roboto(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC6BCFF)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () {
                                  if (qty > 1) {
                                    setSheetState(() => qty--);
                                  }
                                },
                              ),
                              Text('$qty',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  setSheetState(() => qty++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Perkiraan Harga Satuan (Rp)',
                        style: GoogleFonts.roboto(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('input_item_price'),
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 120000',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: const Color(0xFFF7F5FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFC6BCFF)),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Catatan untuk Driver (Opsional)',
                        style: GoogleFonts.roboto(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Tolong potong ukuran rendang, pilih segar...',
                        filled: true,
                        fillColor: const Color(0xFFF7F5FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFC6BCFF)),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        key: const Key('btn_save_item'),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final price = int.tryParse(priceController.text.trim()) ?? 0;
                          if (name.isNotEmpty && price > 0) {
                            final newItem = FlexSendItem(
                              name: name,
                              qty: qty,
                              price: price,
                              notes: notesController.text.isNotEmpty
                                  ? notesController.text
                                  : null,
                            );
                            setState(() {
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
                          backgroundColor: const Color(0xFF17152B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Simpan ke Daftar Belanja',
                          style: GoogleFonts.roboto(
                              fontSize: 13, fontWeight: FontWeight.w700),
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
      case FlexSendState.driverFound:
        return _buildDriverFoundScreen();
      case FlexSendState.shopping:
        return _buildShoppingScreen();
      case FlexSendState.delivering:
        return _buildDeliveringScreen();
      case FlexSendState.arrived:
        return _buildArrivedScreen();
      case FlexSendState.receipt:
        return _buildReceiptScreen();
    }
  }

  // -------------------------------------------------------------------------
  // 1. Form Screen (flrxsend.png / flrxsend-4.png / flrxsend-5.png)
  // -------------------------------------------------------------------------
  Widget _buildFormScreen() {
    final totalItems =
        _location1Items.length + (_isLocation2Active ? _location2Items.length : 0);

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

                  // Location 1 Card (Pasar Utama)
                  _buildLocationCard(
                    locationIndex: 1,
                    locationName: 'Pasar Pagi Batuphat',
                    badgeText: 'Lokasi 1 (Pasar Utama)',
                    badgeColor: const Color(0xFFD8E7FE),
                    items: _location1Items,
                  ),
                  const SizedBox(height: 14),

                  // Location 2 Card (if active)
                  if (_isLocation2Active) ...[
                    _buildLocationCard(
                      locationIndex: 2,
                      locationName: 'Apotek Kimia Farma',
                      badgeText: 'Lokasi 2 (+Rp 2.000 Ongkir)',
                      badgeColor: const Color(0xFFFFECC8),
                      items: _location2Items,
                      onDeleteLocation: () {
                        setState(() {
                          _isLocation2Active = false;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Add Location Button
                  GestureDetector(
                    key: const Key('btn_add_location'),
                    onTap: () {
                      if (!_isLocation2Active) {
                        setState(() {
                          _isLocation2Active = true;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Lokasi singgah maksimal 2 tempat')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
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
                            'Rp ${_formatRupiah(_baseOngkir)}'),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                            'Tambahan Toko ke-2',
                            _isLocation2Active
                                ? '+Rp ${_formatRupiah(_extraStopFee)}'
                                : 'Rp 0'),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                            'Biaya Kuota (Item ke-4 s/d 5)',
                            _itemQuotaFee > 0
                                ? '+Rp ${_formatRupiah(_itemQuotaFee)}'
                                : 'Rp 0'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Color(0xFFE2DCFE)),
                        ),
                        _buildPriceRow(
                          'Total Ongkos Kirim Driver',
                          'Rp ${_formatRupiah(_totalOngkir)}',
                          isBold: true,
                          color: const Color(0xFF6B48FC),
                        ),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                          'Estimasi Talangan Belanja',
                          'Rp ${_formatRupiah(_totalTalangan)}',
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

          // Bottom Bar (Total Bayar & Button Cari Driver Belanja)
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
                        totalItems > 0 ? 'Rp ${_formatRupiah(_totalBayar)}' : 'Rp -',
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
                  onPressed: totalItems > 0 ? _startSearching : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1832),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    VoidCallback? onDeleteLocation,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2DCFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length} Barang',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6680),
                ),
              ),
              if (onDeleteLocation != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFE83535)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDeleteLocation,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF6B48FC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List or Empty State
          if (items.isEmpty) ...[
            GestureDetector(
              onTap: () => _showAddItemSheet(locationIndex),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFC6BCFF).withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF6B48FC), size: 28),
                    const SizedBox(height: 6),
                    Text(
                      '+ Tambah Barang Belanjaan Pertama Anda',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B48FC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${idx + 1}. ',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF17152B))),
                          if (item.notes != null)
                            Text('Catatan: ${item.notes}',
                                style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    color: const Color(0xFF6B6680))),
                        ],
                      ),
                    ),
                    Text('Rp ${_formatRupiah(item.price * item.qty)}',
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                key: Key('btn_add_item_loc_$locationIndex'),
                onPressed: () => _showAddItemSheet(locationIndex),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC6BCFF)),
                  backgroundColor: const Color(0xFFF7F5FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. Searching Screen (cari driver.png)
  // -------------------------------------------------------------------------
  Widget _buildSearchingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Radar circle overlay
          Center(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220 * _radarController.value + 40,
                      height: 220 * _radarController.value + 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B48FC)
                            .withValues(alpha: (1.0 - _radarController.value) * 0.35),
                        border: Border.all(
                          color: const Color(0xFF6B48FC)
                              .withValues(alpha: (1.0 - _radarController.value) * 0.8),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 130 * _radarController.value + 30,
                      height: 130 * _radarController.value + 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B48FC)
                            .withValues(alpha: (1.0 - _radarController.value) * 0.45),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _searchTimer?.cancel();
                _radarController.stop();
                setState(() => _currentState = FlexSendState.driverFound);
              },
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.radar_rounded,
                            size: 26, color: Color(0xFF6B48FC)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mencari Driver...',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
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
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Titip Belanja Pasar Pagi Batuphat Rp ${_formatRupiah(_totalBayar)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      key: const Key('btn_batal_cari_driver'),
                      onPressed: _cancelSearching,
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
                        style: GoogleFonts.roboto(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 3. Driver Found Screen (dapat driver.png)
  // -------------------------------------------------------------------------
  Widget _buildDriverFoundScreen() {
    return Scaffold(
      body: Stack(
        children: [
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
            child: _buildCircularBackButton(),
          ),

          // Bottom Sheet
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
                  // Status Banner: Driver ditemukan!
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC), width: 1.2),
                    ),
                    child: Text(
                      'Driver ditemukan!',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B48FC),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Profile Card
                  _buildDriverCard(),
                  const SizedBox(height: 14),

                  // Button: Lanjut dengan driver ini?
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      key: const Key('btn_lanjut_driver_ini'),
                      onPressed: () {
                        setState(() {
                          _currentState = FlexSendState.shopping;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Lanjut dengan driver ini?',
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
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 4. Shopping Screen (beli brng.png)
  // -------------------------------------------------------------------------
  Widget _buildShoppingScreen() {
    return Scaffold(
      body: Stack(
        children: [
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
            child: _buildCircularBackButton(),
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
                  GestureDetector(
                    key: const Key('banner_sedang_belanja'),
                    onTap: () {
                      setState(() => _currentState = FlexSendState.delivering);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                            child: const Icon(Icons.shopping_cart_rounded,
                                size: 18, color: Color(0xFF8D6E00)),
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
                                  style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    color: const Color(0xFF8D6E00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF8D6E00)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Card
                  _buildDriverCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 5. Delivering Screen (driver sampai.png)
  // -------------------------------------------------------------------------
  Widget _buildDeliveringScreen() {
    return Scaffold(
      body: Stack(
        children: [
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
            child: _buildCircularBackButton(),
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
                  // Status Banner (Green: Menuju rumah anda)
                  GestureDetector(
                    key: const Key('banner_menuju_rumah'),
                    onTap: () {
                      setState(() => _currentState = FlexSendState.arrived);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4F7DF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF28A745)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 28, color: Color(0xFF28A745)),
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
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF1E7E34)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 6. Arrived Screen (driver sampai-1.png)
  // -------------------------------------------------------------------------
  Widget _buildArrivedScreen() {
    return Scaffold(
      body: Stack(
        children: [
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
            child: _buildCircularBackButton(),
          ),

          // Bottom Arrived Card
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
                  // Status Banner (Green: Driver telah sampai)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F7DF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF28A745)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 28, color: Color(0xFF28A745)),
                        const SizedBox(width: 12),
                        Text(
                          'Driver telah sampai',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E7E34),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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

                  _buildDriverCard(),
                  const SizedBox(height: 14),

                  // Button: Selesai dan Lihat Rincian Belanja
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      key: const Key('btn_selesai_lihat_rincian'),
                      onPressed: () {
                        setState(() {
                          _currentState = FlexSendState.receipt;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Selesai dan Lihat Rincian Belanja',
                        style: GoogleFonts.roboto(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
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

  // -------------------------------------------------------------------------
  // 7. Receipt Screen (flrxsend-2.png)
  // -------------------------------------------------------------------------
  Widget _buildReceiptScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFlexSendHeader('Beranda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Green Header Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F7DF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF28A745)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 32, color: Color(0xFF28A745)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PEMBAYARAN BERHASIL (LUNAS)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E7E34),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Menyerahkan uang cash ID: #TB-4091',
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
                  const SizedBox(height: 14),

                  // Komponen A: Talangan Riil Driver
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KOMPONEN A',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Talangan Riil Driver (Wajib Diganti)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow('Nota Pasar Sukaramai (4 Item)', 'Rp 275.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Retribusi Parkir Pasar (Karcis)', 'Rp 2.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Nota Apotek Kimia Farma (1 Item)', 'Rp 25.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Parkir Apotek Kimia Farma', 'Rp 0 (Gratis)',
                            color: const Color(0xFF28A745)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE2DCFE)),
                        ),
                        _buildPriceRow('Subtotal Uang Talangan:', 'Rp 302.000',
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Komponen B: Ongkos Kirim Aplikasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KOMPONEN B',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A73E8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ongkos Kirim Aplikasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow('Ongkir Rute Perjalanan (4.2 km)', 'Rp 12.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Tambahan 1 Toko Singgah', 'Rp 2.000'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Biaya Kuota (Item ke-4 s/d 5)', 'Rp 1.000'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE2DCFE)),
                        ),
                        _buildPriceRow('Subtotal Ongkir Driver:', 'Rp 15.000',
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total Pelunasan Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(18),
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
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6B48FC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Metode: Cash',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          'Rp 317.000',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELESAI Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      key: const Key('btn_receipt_selesai'),
                      onPressed: () {
                        setState(() {
                          _currentState = FlexSendState.form;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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

  // -------------------------------------------------------------------------
  // Reusable Widgets
  // -------------------------------------------------------------------------
  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(AppAssets.driverLuthfi),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Pikri Haykal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                    const SizedBox(width: 2),
                    Text(
                      '4.9',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17152B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BG 4563 R',
                        style: GoogleFonts.roboto(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Honda Vario 160 Hitam',
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          color: const Color(0xFF6B6680),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat & Call Actions
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF6B48FC)),
            onPressed: () {},
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.call_rounded,
                size: 18, color: Color(0xFF28A745)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularBackButton() {
    return GestureDetector(
      key: const Key('btn_flexsend_back_circle'),
      onTap: () {
        _searchTimer?.cancel();
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
        child: const Icon(Icons.arrow_back_rounded,
            size: 20, color: Color(0xFF17152B)),
      ),
    );
  }

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
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                key: const Key('btn_flexsend_header_back'),
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

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
