import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flexsend_item_model.dart';

void showAddItemSheet({
  required BuildContext context,
  required int locationIndex,
  required Function(FlexSendItem item) onSaveItem,
}) {
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                      hintText:
                          'Tolong potong ukuran rendang, pilih segar...',
                      filled: true,
                      fillColor: const Color(0xFFF7F5FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFC6BCFF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                        final price =
                            int.tryParse(priceController.text.trim()) ?? 0;
                        if (name.isNotEmpty && price > 0) {
                          final newItem = FlexSendItem(
                            name: name,
                            qty: qty,
                            price: price,
                            notes: notesController.text.isNotEmpty
                                ? notesController.text
                                : null,
                          );
                          onSaveItem(newItem);
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
