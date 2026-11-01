import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/image_picker_service.dart';

/// [EditProfileScreen]
/// Implementasi Layar Ubah Profil sesuai spesifikasi Figma:
/// - Figma/PengaturanAkun/ubah profil.png
/// - Figma/PengaturanAkun/ubah profil 2.png
/// - Figma/PengaturanAkun/pilih foto profil.png
/// - Figma/PengaturanAkun/edit pp.png
class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String? initialPhotoAsset;
  final ValueChanged<String>? onNameSaved;
  final ImagePickerService? imagePickerService;

  const EditProfileScreen({
    super.key,
    this.initialName = 'Joni Utama',
    this.initialPhotoAsset = 'assets/images/driver_avatar.png',
    this.onNameSaved,
    this.imagePickerService,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late String _photoAsset;
  Uint8List? _photoBytes;
  late final ImagePickerService _pickerService;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _photoAsset = widget.initialPhotoAsset ?? 'assets/images/driver_avatar.png';
    _pickerService = widget.imagePickerService ?? ImagePickerService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final file = fromCamera
        ? await _pickerService.pickImageFromCamera()
        : await _pickerService.pickImageFromGallery();
    if (file != null) {
      final bytes = await _pickerService.readBytes(file);
      if (mounted && bytes != null) {
        setState(() {
          _photoBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dipilih!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Camera Icon + Title
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Foto Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEEEEEE), height: 28),

              // Option 1: Buka Kamera
              _buildPhotoActionTile(
                icon: Icons.camera_alt,
                title: 'Pilih Foto Profil',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(true);
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Galeri
              _buildPhotoActionTile(
                icon: Icons.image_rounded,
                title: 'Pilih Dari Galeri',
                subtitle: 'Pilih Foto Dari Perangkat',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(false);
                },
              ),
              const SizedBox(height: 24),

              // Tombol Batal
              Center(
                child: SizedBox(
                  width: 130,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BATAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B48FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 16),
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
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    widget.onNameSaved?.call(newName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil diperbarui!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop(newName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Header Bar
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
                        'Ubah Profil',
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6BCFF).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Centered with Camera Overlay Badge
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _photoBytes != null
                                  ? Image.memory(
                                      _photoBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      _photoAsset,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showPhotoOptions,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.dark,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Label Nama Lengkap
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // TextField Nama Lengkap
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintText: 'Masukkan nama lengkap',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol SIMPAN PERUBAHAN
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'SIMPAN PERUBAHAN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
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
}
