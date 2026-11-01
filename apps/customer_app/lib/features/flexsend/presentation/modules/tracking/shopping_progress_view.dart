import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';
import 'driver_card_widget.dart';

class ShoppingProgressView extends StatefulWidget {
  final List<FlexSendLocation> locations;
  final VoidCallback onBack;
  final VoidCallback onAdvanceToDelivering;

  const ShoppingProgressView({
    super.key,
    this.locations = const [],
    required this.onBack,
    required this.onAdvanceToDelivering,
  });

  @override
  State<ShoppingProgressView> createState() => _ShoppingProgressViewState();
}

class _ShoppingProgressViewState extends State<ShoppingProgressView> {
  Timer? _autoTransitionTimer;
  int _purchasedItemsCount = 0;
  Timer? _itemCheckTimer;

  @override
  void initState() {
    super.initState();
    _startShoppingSimulation();
  }

  void _startShoppingSimulation() {
    final totalItems = widget.locations.fold<int>(
      0,
      (sum, loc) => sum + loc.items.length,
    );

    // Simulasi centang barang satu per satu
    _itemCheckTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (mounted) {
        setState(() {
          if (_purchasedItemsCount < totalItems) {
            _purchasedItemsCount++;
          }
        });
      }
    });

    // Otomatis beralih ke 'delivering' setelah simulasi belanja selesai (4 detik)
    _autoTransitionTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        widget.onAdvanceToDelivering();
      }
    });
  }

  @override
  void dispose() {
    _autoTransitionTimer?.cancel();
    _itemCheckTimer?.cancel();
    super.dispose();
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showItemsListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        int itemCounter = 0;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pantau Barang Belanjaan',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          Text(
                            'Live checklist barang yang dibeli driver',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (widget.locations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Tidak ada data barang belanjaan',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: const Color(0xFF8C86A8),
                          ),
                        ),
                      ),
                    )
                  else
                    ...widget.locations.asMap().entries.map((locEntry) {
                      final locIdx = locEntry.key;
                      final loc = locEntry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F8FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9E4FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.storefront_rounded,
                                    size: 16, color: Color(0xFF6B48FC)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Toko ${locIdx + 1}: ${loc.name}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...loc.items.map((item) {
                              itemCounter++;
                              final bool isBought = itemCounter <= _purchasedItemsCount;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isBought
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFE2DCFE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isBought
                                            ? Icons.check_rounded
                                            : Icons.hourglass_empty_rounded,
                                        size: 12,
                                        color: isBought
                                            ? Colors.white
                                            : const Color(0xFF6B48FC),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${item.name} (${item.qty} ${item.unit})',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: isBought
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isBought
                                              ? const Color(0xFF17152B)
                                              : const Color(0xFF8C86A8),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isBought ? 'Sudah Dibeli' : 'Sedang Dicari',
                                          style: GoogleFonts.roboto(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isBought
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFB45309),
                                          ),
                                        ),
                                        Text(
                                          'Rp ${_formatRupiah(item.price * item.qty)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            color: const Color(0xFF8C86A8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.locations.fold<int>(
      0,
      (sum, loc) => sum + loc.items.length,
    );
    final String currentStoreName = widget.locations.isNotEmpty
        ? widget.locations.first.name
        : 'Pasar Pagi Batuphat';
    final int storeCount =
        widget.locations.isNotEmpty ? widget.locations.length : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      body: Stack(
        children: [
          // Background Peta
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Header FlexSend Konsisten di bagian atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FlexSendHeader(
              title: 'FlexSend',
              onBack: widget.onBack,
            ),
          ),

          // Bottom Shopping Card Semi-Transparan Konsisten FlexRide (Color 0xFFC6BCFF 85% opacity)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6BCFF).withValues(alpha: 0.85),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle Bar
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF828282),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Status Banner: Driver Sedang Membelanjakan Barang
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2D1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_rounded,
                                size: 20,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Driver Sedang Belanja',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF17152B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2EFFF),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$_purchasedItemsCount/$totalItems Item',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF6B48FC),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Di $currentStoreName (Toko 1 dari $storeCount)',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF6B6680),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showItemsListSheet(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2EFFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.checklist_rounded,
                                        size: 14, color: Color(0xFF6B48FC)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Item',
                                      style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6B48FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Driver Profile Card
                      const DriverCardWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
