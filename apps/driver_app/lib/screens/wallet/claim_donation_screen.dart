import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/image_picker_service.dart';
import 'widgets/dashed_border_container.dart';
import 'withdraw_screen.dart';

/// [ClaimDonationScreen]
/// Layar Donasi Belanjaan ke Panti Asuhan (Klaim Talangan Step 2)
/// Sesuai spesifikasi desain Figma:
/// - Figma/HalamanDompet/dompet-5.png
/// - Figma/HalamanDompet/dompet-6.png
/// - Figma/HalamanDompet/dompet-19.png s/d dompet-22.png
class ClaimDonationScreen extends StatefulWidget {
  final String orderId;
  final String donationRecipient;
  final String totalAmount;
  final bool initialPhotoUploaded;
  final ImagePickerService? imagePickerService;

  const ClaimDonationScreen({
    super.key,
    this.orderId = 'ID : I2E4S69',
    this.donationRecipient = 'Panti Asuhan Terdekat',
    this.totalAmount = 'Rp 177.000 (Nota+Parkir)',
    this.initialPhotoUploaded = true,
    this.imagePickerService,
  });

  @override
  State<ClaimDonationScreen> createState() => _ClaimDonationScreenState();
}

class _ClaimDonationScreenState extends State<ClaimDonationScreen> {
  late bool _isPhotoUploaded;
  Uint8List? _donationPhotoBytes;
  String? _donationPhotoPath;
  late final TextEditingController _notesController;
  late final ImagePickerService _pickerService;

  @override
  void initState() {
    super.initState();
    _isPhotoUploaded = widget.initialPhotoUploaded;
    _pickerService = widget.imagePickerService ?? ImagePickerService();
    _notesController = TextEditingController(
      text:
          'Penyaluran belanjaan barang dari pesanan yang di batalkan oleh customer kepada panti asuhan setempat yang lebih membutuhkan agar bermanfaat.',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage({required bool fromCamera}) async {
    try {
      final XFile? file = fromCamera
          ? await _pickerService.pickImageFromCamera()
          : await _pickerService.pickImageFromGallery();

      if (file != null) {
        final Uint8List? bytes = await _pickerService.readBytes(file);
        if (mounted) {
          setState(() {
            _donationPhotoBytes = bytes;
            _donationPhotoPath = file.path;
            _isPhotoUploaded = true;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto penyerahan barang berhasil dipilih'),
              backgroundColor: Color(0xFF00796B),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking donation image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.white,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Sheet
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pilih Foto Penyerahan Barang',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Option 1: Ambil Foto
              _buildPickerOption(
                key: const Key('opt_ambil_foto_donation'),
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Foto',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handlePickImage(fromCamera: true);
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Pilih Dari Galeri
              _buildPickerOption(
                key: const Key('opt_pilih_galeri_donation'),
                icon: Icons.image_rounded,
                title: 'Pilih Dari Galeri',
                subtitle: 'Pilih Foto Dari Perangkat',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handlePickImage(fromCamera: false);
                },
              ),
              const SizedBox(height: 20),

              // Tombol Batal
              SizedBox(
                width: 140,
                height: 44,
                child: ElevatedButton(
                  key: const Key('btn_batal_picker_donation'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17152B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BATAL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEBE6FE),
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
            const SizedBox(width: 14),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6E6A8A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6E6A8A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _submitClaim() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EEFE),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC6BCFF), width: 3),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFF6B48FC),
                            size: 34,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00C853),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Klaim talangan anda di setujui',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Uang talangan kas sebesar Rp 177.000 akan otomatis masuk ke saldo dompet anda dalam 1×24jam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6E6A8A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Detail Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEBE6FE),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Total', 'Rp 177.000', isBold: true),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Metode Pelunasan',
                          'Saldo Dompet Anda',
                          valueColor: const Color(0xFF00C853),
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'ID orderan',
                          widget.orderId,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button 1: Tarik Saldo
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup dialog
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const WithdrawScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tarik Saldo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button 2: Kembali ke radar kerja
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup dialog
                        // Kembali ke halaman dompet
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Kembali ke radar kerja',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6A8A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.dark,
            ),
          ),
        ),
      ],
    );
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
                        'Donasi belanjaan ke panti asuhan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
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

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Proteksi / Informasi Donasi
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F8FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC6BCFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pemberian  kepanti asuhan yang membutuhkan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B48FC),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Terimakasih Driver atas kerja sama nya untuk menyalurkan bantuan ke tempat yang membutuhkan. uang modal anda tetap di ganti oleh sistem dalam 1×24 jam.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6E6A8A),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Card Ringkasan Donasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ID Pesanan',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E6A8A),
                              ),
                            ),
                            Text(
                              widget.orderId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Penerima Donasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6E6A8A),
                                ),
                              ),
                            ),
                            Text(
                              widget.donationRecipient,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E6A8A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.totalAmount,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Upload Box: Foto Penyerahan Barang
                  InkWell(
                    key: const Key('btn_upload_donation_photo'),
                    onTap: _showImagePickerSheet,
                    borderRadius: BorderRadius.circular(16),
                    child: DashedBorderContainer(
                      strokeColor: const Color(0xFFC6BCFF),
                      backgroundColor: const Color(0xFFFCFBFF),
                      child: Row(
                        children: [
                          if (_donationPhotoBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _donationPhotoBytes!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Icon(
                              Icons.camera_alt_outlined,
                              color: Color(0xFF6B48FC),
                              size: 28,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Foto Penyerahan Barang',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                                if (_donationPhotoBytes != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _donationPhotoPath != null
                                        ? 'Foto: ${_donationPhotoPath!.split(RegExp(r"[/\\]")).last}'
                                        : 'Foto terpilih (ketuk untuk ganti)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6E6A8A),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isPhotoUploaded
                                    ? const Color(0xFFC5EFE8)
                                    : const Color(0xFFEAE6FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isPhotoUploaded ? 'Terupload' : 'JPG/PNG',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isPhotoUploaded
                                      ? const Color(0xFF00796B)
                                      : const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keterangan Pemberian Donasi (Label sesuai Figma)
                  const Text(
                    'Keteranagn pemberian donasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input Box Keterangan
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFBFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: TextField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 5,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.dark,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'isi keterengan...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9DB2),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Kirim Klaim Anti Rugi Sekarang
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Kirim klaim anti rugi sekarang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
