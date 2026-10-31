import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flexsend_item_model.dart';

class LocationCardWidget extends StatelessWidget {
  final int locationIndex;
  final String locationName;
  final String badgeText;
  final Color badgeColor;
  final List<FlexSendItem> items;
  final VoidCallback onAddItem;
  final VoidCallback? onDeleteLocation;

  const LocationCardWidget({
    super.key,
    required this.locationIndex,
    required this.locationName,
    required this.badgeText,
    required this.badgeColor,
    required this.items,
    required this.onAddItem,
    this.onDeleteLocation,
  });

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Icon(Icons.location_on,
                  size: 16, color: Color(0xFF6B48FC)),
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
              onTap: onAddItem,
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
                onPressed: onAddItem,
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
}
