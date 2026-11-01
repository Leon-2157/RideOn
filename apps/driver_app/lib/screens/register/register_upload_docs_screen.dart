import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'photo_picker_sheet.dart';
import 'terms_and_conditions_sheet.dart';
import 'register_success_screen.dart';

/// Model dokumen yang wajib diunggah driver
class RequiredDocument {
  final String id;
  final String title;
  final IconData icon;
  bool isUploaded;
  String? uploadedFilePath;

  RequiredDocument({
    required this.id,
    required this.title,
    required this.icon,
    this.isUploaded = false,
    this.uploadedFilePath,
  });
}

/// [RegisterUploadDocsScreen]
/// Layar Unggah Berkas Pendaftaran Mitra Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/Daftar akun_step 2.png
/// - Figma/HalamanLogin/Daftar akun_step 4.png
/// - Figma/HalamanLogin/Daftar akun_step 5.png
/// - Figma/HalamanLogin/Daftar akun_step 9.png
class RegisterUploadDocsScreen extends StatefulWidget {
  final String? fullName;
  final String? phone;
  final String? email;
  final String? password;

  const RegisterUploadDocsScreen({
    super.key,
    this.fullName,
    this.phone,
    this.email,
    this.password,
  });

  @override
  State<RegisterUploadDocsScreen> createState() =>
      _RegisterUploadDocsScreenState();
}

class _RegisterUploadDocsScreenState extends State<RegisterUploadDocsScreen> {
  final List<RequiredDocument> _documents = [
    RequiredDocument(
      id: 'ktp',
      title: 'Identitas Pribadi (KTP)',
      icon: Icons.badge_outlined,
    ),
    RequiredDocument(
      id: 'sim',
      title: 'Surat Izin Mengemudi (SIM)',
      icon: Icons.assignment_ind_outlined,
    ),
    RequiredDocument(
      id: 'stnk',
      title: 'Surat Tanda Nomor Kendaraan (STNK)',
      icon: Icons.two_wheeler_outlined,
    ),
    RequiredDocument(
      id: 'bank',
      title: 'Informasi Rekening Bank',
      icon: Icons.account_balance_wallet_outlined,
    ),
    RequiredDocument(
      id: 'skck',
      title: 'Surat Keterangan Catatan Kepolisian (SKCK)',
      icon: Icons.shield_outlined,
    ),
  ];

  bool _agreeToTerms = false;
  String? _errorMessage;

  Future<void> _handleUploadDocument(RequiredDocument doc) async {
    final result = await PhotoPickerSheet.show(
      context,
      documentTitle: doc.title,
    );

    if (result != null) {
      setState(() {
        doc.isUploaded = true;
        doc.uploadedFilePath = '$result/${doc.id}.jpg';
        _errorMessage = null;
      });
    }
  }

  Future<void> _openTerms() async {
    final agreed = await TermsAndConditionsSheet.show(context);
    if (agreed == true) {
      setState(() {
        _agreeToTerms = true;
        _errorMessage = null;
      });
    }
  }

  void _submitDocuments() {
    final allUploaded = _documents.every((d) => d.isUploaded);

    if (!allUploaded) {
      setState(() {
        _errorMessage = 'Harap lengkapi semua dokumen yang diperlukan.';
      });
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage =
            'Anda harus menyetujui Syarat & Ketentuan RideOn untuk melanjutkan.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterSuccessScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 20,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 24.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color:
                              const Color(0xFFF1F1FD).withValues(alpha: 0.60),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            offset: const Offset(0, 4),
                            blurRadius: 20.0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header: Lengkapi Berkas
                          const Text(
                            'Lengkapi Berkas',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lengkapi data diri Anda untuk memulai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.dark.withValues(alpha: 0.70),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Daftar 5 Dokumen
                          ..._documents.map(
                            (doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildDocumentTile(doc),
                            ),
                          ),

                          // Checkbox Syarat & Ketentuan
                          _buildTermsCheckbox(),
                          const SizedBox(height: 12),

                          // Pesan Error jika berkas / persetujuan belum lengkap
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE83535),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFE83535),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE83535),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Tombol UPLOAD
                          SizedBox(
                            height: 42,
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('btn_upload_berkas'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13.0),
                                ),
                              ),
                              onPressed: _submitDocuments,
                              child: const Text(
                                'UPLOAD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footer: Sudah punya akun? Masuk di sini
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(RequiredDocument doc) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.0),
            gradient: LinearGradient(
              begin: const Alignment(-0.94, -0.69),
              end: const Alignment(0.94, 0.78),
              stops: const [0.45, 1.0],
              colors: [
                AppColors.primary.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.20),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(2, 2),
                blurRadius: 8.0,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('tile_doc_${doc.id}'),
              borderRadius: BorderRadius.circular(13.0),
              onTap: () => _handleUploadDocument(doc),
              child: Row(
                children: [
                  Icon(
                    doc.icon,
                    size: 19,
                    color: AppColors.dark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 19,
                    color: AppColors.dark,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Badge "Terupload" jika dokumen telah diunggah
        if (doc.isUploaded)
          Positioned(
            top: -7,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7CE2D5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Terupload',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F5A51),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13.0),
        gradient: LinearGradient(
          begin: const Alignment(-0.94, -0.69),
          end: const Alignment(0.94, 0.78),
          stops: const [0.45, 1.0],
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(2, 2),
            blurRadius: 8.0,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Theme(
            data: ThemeData(
              unselectedWidgetColor: AppColors.dark.withValues(alpha: 0.60),
            ),
            child: Checkbox(
              key: const Key('checkbox_terms'),
              value: _agreeToTerms,
              activeColor: AppColors.dark,
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                setState(() {
                  _agreeToTerms = val ?? false;
                  if (_agreeToTerms) {
                    _errorMessage = null;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              key: const Key('link_terms_bottomsheet'),
              onTap: _openTerms,
              child: RichText(
                text: const TextSpan(
                  text: 'Saya menyetujui ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.dark,
                  ),
                  children: [
                    TextSpan(
                      text: 'Syarat & Ketentuan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: ' RideOn.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.dark,
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

  Widget _buildFooter() {
    return GestureDetector(
      key: const Key('link_masuk_dari_upload'),
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: RichText(
        text: const TextSpan(
          text: 'Sudah punya akun? ',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
          children: [
            TextSpan(
              text: 'Masuk di sini',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
