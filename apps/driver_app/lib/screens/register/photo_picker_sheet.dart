import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// [PhotoPickerSheet]
/// Bottom sheet modal untuk memilih sumber foto dokumen pendaftaran mitra driver:
/// - Figma/HalamanLogin/Daftar akun_step 3.png
class PhotoPickerSheet extends StatelessWidget {
  final String documentTitle;
  final ValueChanged<String>? onSourceSelected;

  const PhotoPickerSheet({
    super.key,
    required this.documentTitle,
    this.onSourceSelected,
  });

  static Future<String?> show(BuildContext context, {required String documentTitle}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PhotoPickerSheet(
        documentTitle: documentTitle,
        onSourceSelected: (source) => Navigator.of(context).pop(source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon camera + "Pilih Foto"
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pilih Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8E5F2)),
          const SizedBox(height: 16),

          // Option 1: Ambil Foto
          _buildOptionTile(
            key: const Key('opt_ambil_foto'),
            icon: Icons.camera_alt_rounded,
            title: 'Ambil Foto',
            subtitle: 'Ambil Foto Sekarang',
            onTap: () {
              if (onSourceSelected != null) {
                onSourceSelected!('camera');
              } else {
                Navigator.of(context).pop('camera');
              }
            },
          ),
          const SizedBox(height: 12),

          // Option 2: Pilih Dari Galeri
          _buildOptionTile(
            key: const Key('opt_pilih_galeri'),
            icon: Icons.photo_library_rounded,
            title: 'Pilih Dari Galeri',
            subtitle: 'Pilih Foto Dari Perangkat',
            onTap: () {
              if (onSourceSelected != null) {
                onSourceSelected!('gallery');
              } else {
                Navigator.of(context).pop('gallery');
              }
            },
          ),
          const SizedBox(height: 20),

          // Button Batal
          Center(
            child: SizedBox(
              width: 140,
              height: 40,
              child: ElevatedButton(
                key: const Key('btn_batal_pilih_foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'BATAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

  Widget _buildOptionTile({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FF).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Purple Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.dark.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.dark,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
