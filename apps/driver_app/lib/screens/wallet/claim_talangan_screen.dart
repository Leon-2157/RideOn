import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/image_picker_service.dart';
import 'widgets/dashed_border_container.dart';
import 'claim_donation_screen.dart';

/// [ClaimTalanganScreen]
/// Layar Klaim Uang Talangan Belanja (Step 1)
/// Sesuai spesifikasi desain Figma:
/// - Figma/HalamanDompet/dompet-1.png
/// - Figma/HalamanDompet/dompet-2.png
/// - Figma/HalamanDompet/dompet-3.png
/// - Figma/HalamanDompet/dompet-4.png
/// - Figma/HalamanDompet/dompet-23.png
/// - Figma/HalamanDompet/dompet-24.png
class ClaimTalanganScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String totalAmount;
  final bool initialItemPhotoUploaded;
  final bool initialReceiptPhotoUploaded;
  final ImagePickerService? imagePickerService;

  const ClaimTalanganScreen({
    super.key,
    this.orderId = 'ID : I2E4S69',
    this.customerName = 'Pikri (Batal Sepihak)',
    this.totalAmount = 'Rp 177.000 (Nota+Parkir)',
    this.initialItemPhotoUploaded = true,
    this.initialReceiptPhotoUploaded = true,
    this.imagePickerService,
  });

  @override
  State<ClaimTalanganScreen> createState() => _ClaimTalanganScreenState();
}

class _ClaimTalanganScreenState extends State<ClaimTalanganScreen> {
  late bool _isItemPhotoUploaded;
  late bool _isReceiptPhotoUploaded;
  Uint8List? _itemPhotoBytes;
  String? _itemPhotoPath;
  Uint8List? _receiptPhotoBytes;
  String? _receiptPhotoPath;
  late final TextEditingController _reasonController;
  late final ImagePickerService _pickerService;

  @override
  void initState() {
    super.initState();
    _isItemPhotoUploaded = widget.initialItemPhotoUploaded;
    _isReceiptPhotoUploaded = widget.initialReceiptPhotoUploaded;
    _pickerService = widget.imagePickerService ?? ImagePickerService();
    _reasonController = TextEditingController(
      text:
          'Customer batalkan sepihak saat saya sudah selesai bayar di Pasar BatuPhat dan sedang menuju lokasi rumah pengantaran.',
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage({
    required bool isItemPhoto,
    required bool fromCamera,
  }) async {
    try {
      final XFile? file = fromCamera
          ? await _pickerService.pickImageFromCamera()
          : await _pickerService.pickImageFromGallery();

      if (file != null) {
        final Uint8List? bytes = await _pickerService.readBytes(file);
        if (mounted) {
          setState(() {
            if (isItemPhoto) {
              _itemPhotoBytes = bytes;
              _itemPhotoPath = file.path;
              _isItemPhotoUploaded = true;
            } else {
              _receiptPhotoBytes = bytes;
              _receiptPhotoPath = file.path;
              _isReceiptPhotoUploaded = true;
            }
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isItemPhoto
                    ? 'Foto barang belanjaan berhasil dipilih'
                    : 'Foto nota belanja berhasil dipilih',
              ),
              backgroundColor: const Color(0xFF00796B),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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

  void _showImagePickerSheet(bool isItemPhoto) {
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
                      'Pilih Foto Belanjaan & Nota',
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
                key: const Key('opt_ambil_foto'),
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Foto',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handlePickImage(isItemPhoto: isItemPhoto, fromCamera: true);
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Pilih Dari Galeri
              _buildPickerOption(
                key: const Key('opt_pilih_galeri'),
                icon: Icons.image_rounded,
                title: 'Pilih Dari Galeri',
                subtitle: 'Pilih Foto Dari Perangkat',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _handlePickImage(isItemPhoto: isItemPhoto, fromCamera: false);
                },
              ),
              const SizedBox(height: 20),

              // Tombol Batal
              SizedBox(
                width: 140,
                height: 44,
                child: ElevatedButton(
                  key: const Key('btn_batal_picker'),
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
                        'Klaim Uang Talangan Belanja',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
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
                  // Banner Proteksi Talangan 100%
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
                          'Jaminan Proteksi Talangan 100%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B48FC),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jika pelanggan membatalkan pesanan setelah Anda belanja di pasar, uang modal Anda akan diganti utuh oleh sistem.',
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

                  // Card Info Pesanan
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
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E6A8A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.customerName,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE53935), // Merah untuk batal sepihak
                                ),
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

                  // Upload Box 1: Foto Barang Belanjaan Fisik
                  InkWell(
                    key: const Key('btn_upload_item_photo'),
                    onTap: () => _showImagePickerSheet(true),
                    borderRadius: BorderRadius.circular(16),
                    child: DashedBorderContainer(
                      strokeColor: const Color(0xFFC6BCFF),
                      backgroundColor: const Color(0xFFFCFBFF),
                      child: Row(
                        children: [
                          if (_itemPhotoBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _itemPhotoBytes!,
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
                                  'Foto Barang Belanjaan Fisik',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _itemPhotoBytes != null
                                      ? (_itemPhotoPath != null
                                          ? 'Foto: ${_itemPhotoPath!.split(RegExp(r"[/\\]")).last}'
                                          : 'Foto terpilih (ketuk untuk ganti)')
                                      : 'Kantong kresek & isi barang pasar',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6E6A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isItemPhotoUploaded
                                  ? const Color(0xFFC5EFE8)
                                  : const Color(0xFFEAE6FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isItemPhotoUploaded ? 'Terupload' : 'JPG/PNG',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isItemPhotoUploaded
                                    ? const Color(0xFF00796B)
                                    : const Color(0xFF6B48FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Upload Box 2: Foto Nota Asli Lapak & Karcis
                  InkWell(
                    key: const Key('btn_upload_receipt_photo'),
                    onTap: () => _showImagePickerSheet(false),
                    borderRadius: BorderRadius.circular(16),
                    child: DashedBorderContainer(
                      strokeColor: const Color(0xFFC6BCFF),
                      backgroundColor: const Color(0xFFFCFBFF),
                      child: Row(
                        children: [
                          if (_receiptPhotoBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _receiptPhotoBytes!,
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
                                  'Foto Nota Asli Lapak & Karcis',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _receiptPhotoBytes != null
                                      ? (_receiptPhotoPath != null
                                          ? 'Foto: ${_receiptPhotoPath!.split(RegExp(r"[/\\]")).last}'
                                          : 'Foto nota terpilih (ketuk untuk ganti)')
                                      : 'Bukti transaksi fisik',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6E6A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isReceiptPhotoUploaded
                                  ? const Color(0xFFC5EFE8)
                                  : const Color(0xFFEAE6FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isReceiptPhotoUploaded ? 'Terupload' : 'PNG/JPG',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isReceiptPhotoUploaded
                                    ? const Color(0xFF00796B)
                                    : const Color(0xFF6B48FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alasan Pembatalan di Lapangan
                  const Text(
                    'Alasan Pembatalan di Lapangan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input Box Alasan
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFBFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: TextField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 5,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.dark,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'isi alasan pembatalan...',
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

                  // Tombol Selanjutnya
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClaimDonationScreen(
                              orderId: widget.orderId,
                              totalAmount: widget.totalAmount,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'SELANJUTNYA',
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
