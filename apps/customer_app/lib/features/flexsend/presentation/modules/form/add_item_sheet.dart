import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flexsend_item_model.dart';

void showAddItemSheet({
  required BuildContext context,
  required int locationIndex,
  required Function(FlexSendItem item) onSaveItem,
}) {
  final nameController = TextEditingController();
  final notesController = TextEditingController();
  int qty = 1;
  String selectedUnit = 'kg';

  final List<String> availableUnits = [
    'kg',
    'gram',
    'bks',
    'ikat',
    'botol',
    'buah',
    'butir',
    'pcs',
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final isNameFilled = nameController.text.trim().isNotEmpty;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 12,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2DCFE),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFF6B48FC),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Barang Belanjaan',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Lokasi $locationIndex • Titip belanja ke driver',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: const Color(0xFF6B6680),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('close_add_item'),
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF8C86A8)),
                        splashRadius: 20,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row: [ Nama Barang (flex 6) ] | [ Jumlah & Satuan (flex 4) ]
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolom Nama Barang
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Barang',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 48,
                              child: TextField(
                                key: const Key('input_item_name'),
                                controller: nameController,
                                onChanged: (_) => setSheetState(() {}),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF17152B),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Misal: Daging Sapi, Telur',
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: const Color(0xFFA5A0BF),
                                  ),
                                  prefixIcon: const Icon(Icons.edit_note_rounded,
                                      color: Color(0xFF6B48FC), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF9F8FF),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE9E4FF), width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF6B48FC), width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Kolom Jumlah & Satuan
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F8FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE9E4FF), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  // Tombol Minus
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      if (qty > 1) {
                                        setSheetState(() => qty--);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 16,
                                        color: qty > 1
                                            ? const Color(0xFF17152B)
                                            : const Color(0xFFB0B0C0),
                                      ),
                                    ),
                                  ),
                                  // Teks Angka
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 2),
                                    child: Text(
                                      '$qty',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: const Color(0xFF17152B),
                                      ),
                                    ),
                                  ),
                                  // Tombol Plus
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => setSheetState(() => qty++),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: Color(0xFF6B48FC),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: const Color(0xFFE2DCFE),
                                  ),
                                  const SizedBox(width: 2),
                                  // Dropdown Satuan
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedUnit,
                                        isDense: true,
                                        isExpanded: true,
                                        icon: const Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 18,
                                            color: Color(0xFF6B48FC)),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6B48FC),
                                        ),
                                        items: availableUnits.map((u) {
                                          return DropdownMenuItem<String>(
                                            value: u,
                                            child: Text(u),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setSheetState(
                                                () => selectedUnit = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Catatan untuk Driver (Opsional)
                  Text(
                    'Catatan untuk Driver (Opsional)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      color: const Color(0xFF17152B),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Misal: Pilih yang masih segar, ukuran sedang...',
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFFA5A0BF),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Icon(Icons.speaker_notes_outlined,
                            color: Color(0xFF8C86A8), size: 18),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9F8FF),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFE9E4FF), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF6B48FC), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('btn_save_item'),
                      onPressed: isNameFilled
                          ? () {
                              final name = nameController.text.trim();
                              final newItem = FlexSendItem(
                                name: name,
                                qty: qty,
                                unit: selectedUnit,
                                price: 0,
                                notes: notesController.text.isNotEmpty
                                    ? notesController.text
                                    : null,
                              );
                              onSaveItem(newItem);
                              Navigator.of(context).pop();
                            }
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
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Simpan ke Daftar Belanja',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
          );
        },
      );
    },
  );
}
