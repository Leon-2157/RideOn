import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card Pengaturan Lokasi Sesuai Desain Figma (atur lokadi.png & lokasi berhasil.png)
class LokasiControlCard extends StatelessWidget {
  final bool isLoadingGps;
  final bool isLocationLocked;
  final String selectedLabel;
  final List<Map<String, dynamic>> labelOptions;
  final String currentAddress;
  final TextEditingController noteController;
  final bool isSaving;
  final VoidCallback onGetGps;
  final ValueChanged<String> onSelectLabel;
  final VoidCallback onSaveLocation;

  const LokasiControlCard({
    super.key,
    required this.isLoadingGps,
    required this.isLocationLocked,
    required this.selectedLabel,
    required this.labelOptions,
    required this.currentAddress,
    required this.noteController,
    required this.isSaving,
    required this.onGetGps,
    required this.onSelectLabel,
    required this.onSaveLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon Peta Kotak Ungu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD6CEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map_rounded,
              size: 26,
              color: Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Atur Lokasi Anda',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 18),

          // Tombol: Gunakan Titik GPS Saat Ini
          GestureDetector(
            key: const Key('btn_gunakan_titik_gps'),
            onTap: isLoadingGps ? null : onGetGps,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFDCD7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoadingGps) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF17152B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mencari Sinyal GPS...',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.navigation_rounded,
                      size: 16,
                      color: Color(0xFF17152B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gunakan Titik GPS Saat Ini',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Teks Status Lokasi Berhasil Dikunci (Figma: lokasi berhasil.png)
          if (isLocationLocked) ...[
            Text(
              'Lokasi berhasil dikunci!',
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4338CA),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Label Kategori Alamat (Multi-Label: Rumah, Kantor, Kost, Lainnya)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Simpan Sebagai',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF17152B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: labelOptions.map((opt) {
                final isSelected = selectedLabel == opt['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF17152B),
                        ),
                        const SizedBox(width: 5),
                        Text(opt['label'] as String),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF17152B),
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    labelStyle: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF17152B),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    onSelected: (val) {
                      if (val) {
                        onSelectLabel(opt['label'] as String);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Detail Alamat Lengkap
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Detail Alamat Lengkap',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF17152B),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              currentAddress,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xFF4C4566),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Catatan Patokan Alamat (Opsional)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1,
              ),
            ),
            child: TextField(
              controller: noteController,
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0xFF17152B),
              ),
              decoration: InputDecoration(
                hintText: 'Catatan patokan (contoh: Pagar hitam No. 12)',
                hintStyle: GoogleFonts.roboto(
                  fontSize: 11,
                  color: const Color(0xFF7C7596),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Tombol SIMPAN TITIK LOKASI
          GestureDetector(
            key: const Key('btn_simpan_titik_lokasi'),
            onTap: isSaving ? null : onSaveLocation,
            child: Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1832),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'SIMPAN TITIK LOKASI',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
