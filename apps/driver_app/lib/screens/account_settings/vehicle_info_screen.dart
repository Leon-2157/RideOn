import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/image_picker_service.dart';

/// [VehicleInfoScreen]
/// Implementasi Layar Informasi Kendaraan sesuai spesifikasi Figma:
/// - Figma/PengaturanAkun/informasi.png
/// - Figma/PengaturanAkun/informasi kendaraan.png
/// - Figma/PengaturanAkun/perbarui.png
/// - Figma/PengaturanAkun/ubah-1.png .. ubah-6.png
/// - Figma/PengaturanAkun/berhasil.png
class VehicleInfoScreen extends StatefulWidget {
  final String brand;
  final String model;
  final String plateNumber;
  final String color;
  final String year;
  final String imageAsset;
  final ImagePickerService? imagePickerService;

  const VehicleInfoScreen({
    super.key,
    this.brand = 'Honda',
    this.model = 'Vario 160',
    this.plateNumber = 'BL 1234 XX',
    this.color = 'Merah',
    this.year = '2024',
    this.imageAsset = 'assets/images/motor_vario.png',
    this.imagePickerService,
  });

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  late String _brand;
  late String _model;
  late String _plateNumber;
  late String _color;
  late String _year;
  late String _imageAsset;
  Uint8List? _imageBytes;
  bool _isEditing = false;
  late final ImagePickerService _pickerService;

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _plateController;
  late TextEditingController _colorController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _pickerService = widget.imagePickerService ?? ImagePickerService();
    _brand = widget.brand;
    _model = widget.model;
    _plateNumber = widget.plateNumber;
    _color = widget.color;
    _year = widget.year;
    _imageAsset = widget.imageAsset;

    _brandController = TextEditingController(text: _brand);
    _modelController = TextEditingController(text: _model);
    _plateController = TextEditingController(text: _plateNumber);
    _colorController = TextEditingController(text: _color);
    _yearController = TextEditingController(text: _year);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickVehicleImage(bool fromCamera) async {
    final file = fromCamera
        ? await _pickerService.pickImageFromCamera()
        : await _pickerService.pickImageFromGallery();
    if (file != null) {
      final bytes = await _pickerService.readBytes(file);
      if (mounted && bytes != null) {
        setState(() {
          _imageBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto kendaraan diperbarui!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showVehiclePhotoOptions() {
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
                    'Pilih Foto Kendaraan',
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
                title: 'Ambil Foto',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickVehicleImage(true);
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
                  _pickVehicleImage(false);
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kendaraan Berhasil Diubah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kendaraan Anda Berhasil diperbarui',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SIMPAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveVehicleInfo() {
    setState(() {
      _brand = _brandController.text.trim();
      _model = _modelController.text.trim();
      _plateNumber = _plateController.text.trim();
      _color = _colorController.text.trim();
      _year = _yearController.text.trim();
    });
    _showSuccessDialog();
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
                        'Pengaturan Akun',
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF8B68FC),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Vehicle Banner Container (Lavender)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC6BCFF).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                // Motorcycle Image
                                GestureDetector(
                                  onTap: _isEditing ? _showVehiclePhotoOptions : null,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 86,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: _imageBytes != null
                                              ? Image.memory(
                                                  _imageBytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.asset(
                                                  _imageAsset,
                                                  fit: BoxFit.contain,
                                                ),
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.dark,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              size: 14,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Model Title & Type
                                Text(
                                  '$_brand $_model',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Sepeda Motor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Verified Pill Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB2DFDB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00796B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section Title
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Detail Kendaraan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Vehicle Specs Table
                          _buildSpecRow('Merek Kendaraan', _brand, _brandController),
                          const Divider(color: Color(0xFFE5E7EB), height: 1),
                          _buildSpecRow('Model Kendaraan', _model, _modelController),
                          const Divider(color: Color(0xFFE5E7EB), height: 1),
                          _buildSpecRow('Nomor Polisi', _plateNumber, _plateController),
                          const Divider(color: Color(0xFFE5E7EB), height: 1),
                          _buildSpecRow('Warna', _color, _colorController),
                          const Divider(color: Color(0xFFE5E7EB), height: 1),
                          _buildSpecRow('Tahun Kendaraan', _year, _yearController),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button Ubah / Perbarui
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isEditing) {
                            _saveVehicleInfo();
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          elevation: 0,
                        ),
                        child: Text(
                          _isEditing ? 'Perbarui' : 'Ubah Informasi Kendaraan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
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

  Widget _buildSpecRow(
    String label,
    String value,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_isEditing)
            SizedBox(
              width: 130,
              height: 36,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFC6BCFF)),
                  ),
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
        ],
      ),
    );
  }
}
