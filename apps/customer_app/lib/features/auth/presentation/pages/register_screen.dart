import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Screen Pendaftaran Akun RideOn
/// Strictly implements Figma designs:
/// - figma/HalamanLogin/daftar akun.png
/// - figma/HalamanLogin/ceklis.png
/// - figma/HalamanLogin/error.png
/// - figma/HalamanLogin/syarat dan ketentuan.png
/// - figma/HalamanLogin/berhasil daftar.png
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTermsAgreed = false;
  bool _hasError = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation matching Figma requirements
    if (name.isEmpty ||
        phone.isEmpty ||
        password.length < 8 ||
        password != confirmPassword ||
        !_isTermsAgreed) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    // Show Berhasil Daftar Dialog
    _showSuccessDialog();
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTermsSheet(),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF1F1FD).withValues(alpha: 0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Akun berhasil dibuat!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Akun Anda telah berhasil dibuat.\nSilakan masuk dan bereksplorasi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        key: const Key('btn_masuk_sekarang_success'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Return to LoginScreen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: Text(
                          'MASUK SEKARANG',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE2DCFE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syarat & Ketentuan RideOn',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketentuan umum penggunaan layanan transportasi',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('close_terms_sheet'),
                      icon: const Icon(Icons.close_rounded, color: AppColors.dark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFC6BCFF)),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    Text(
                      'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                      style: GoogleFonts.roboto(fontSize: 12, height: 1.5, color: AppColors.dark),
                    ),
                    _buildTermsSection(
                      '1. Ketentuan Umum & Definisi',
                      [
                        'RideOn adalah platform perantara yang mempertemukan pihak yang menyediakan layanan transportasi (Mitra Pengemudi) dengan pihak yang membutuhkan layanan perjalanan (Penumpang/Customer).',
                        'RideOn tidak memiliki, menguasai, atau mengelola armada kendaraan yang digunakan oleh Mitra Pengemudi di dalam platform ini.',
                        'Pengguna wajib berusia minimal 17 tahun dan/atau memiliki identitas resmi (KTP/SIM/Paspor) yang sah menurut hukum Republik Indonesia. Pengguna di bawah umur wajib didampingi oleh orang dewasa saat menggunakan layanan.',
                      ],
                    ),
                    _buildTermsSection(
                      '2. Tanggung Jawab & Kewajiban Customer',
                      [
                        'Customer wajib memberikan informasi titik penjemputan dan titik tujuan yang asli dan valid saat melakukan transaksi pemesanan perjalanan.',
                        'Customer dilarang keras membawa barang terlarang, ilegal, berbahaya, atau hewan yang tidak sesuai dengan kebijakan keselamatan selama perjalanan berlangsung.',
                        'Customer wajib mematuhi peraturan lalu lintas, termasuk menggunakan helm pelindung (untuk layanan ojek motor) yang disediakan oleh Mitra Pengemudi.',
                        'Kerusakan pada kendaraan Mitra Pengemudi di luar batas wajar pemakaian yang diakibatkan oleh kelalaian atau kesengajaan Customer akan menjadi tanggung jawab Customer sesuai nilai kerugian atau kesepakatan dengan Mitra Pengemudi.',
                      ],
                    ),
                    _buildTermsSection(
                      '3. Tanggung Jawab & Hak Mitra Pengemudi (Driver)',
                      [
                        'Mitra Pengemudi bertanggung jawab penuh atas keselamatan penumpang, kelayakan jalan kendaraan, serta kesesuaian identitas dan plat nomor kendaraan dengan yang tertera di aplikasi.',
                        'Mitra Pengemudi berhak menolak pesanan jika Customer dinilai mencurigakan, membawa muatan berlebih/berbahaya, atau tidak memenuhi standar keselamatan berkendara.',
                      ],
                    ),
                    _buildTermsSection(
                      '4. Batasan Tanggung Jawab',
                      [
                        'RideOn terlepas dari segala tuntutan hukum atas kecelakaan, kehilangan barang bawaan, cedera, atau tindakan kriminal yang dilakukan oleh pengguna atau pengemudi di luar prosedur standar operasi aplikasi.',
                        'Segala sengketa atau wanprestasi adalah tanggung jawab penuh antara Mitra Pengemudi dan Customer. RideOn hanya akan bertindak sebagai mediator untuk membantu menyelesaikan perselisihan jika diperlukan.',
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Button: SAYA MENGERTI & SETUJU
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('btn_agree_terms'),
                    onPressed: () {
                      setState(() {
                        _isTermsAgreed = true;
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SAYA MENGERTI & SETUJU',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
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
      },
    );
  }

  Widget _buildTermsSection(String heading, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.dark.withValues(alpha: 0.85),
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
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 20,
                ),
                child: _buildGlassCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 22.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: const Color(0xFFF1F1FD).withValues(alpha: 0.60),
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
              // Header Title
              Text(
                'Daftar Akun',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi data diri Anda untuk memulai',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 14),

              // Error alert banner (Figma error.png)
              if (_hasError) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE83535), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE83535), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pendaftaran gagal. Mohon lengkapi dan periksa kembali data Anda.',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE83535),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Google Button
              _buildGoogleButton(),
              const SizedBox(height: 10),

              // Divider ATAU
              _buildOrDivider(),
              const SizedBox(height: 10),

              // Input: Nama Lengkap
              _buildInputField(
                controller: _fullNameController,
                hintText: 'Nama Lengkap',
                prefixIcon: Icons.person_rounded,
                keyName: 'input_register_name',
              ),
              const SizedBox(height: 12),

              // Input: No. WhatsApp Aktif
              _buildInputField(
                controller: _phoneController,
                hintText: 'No. WhatsApp Aktif',
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                keyName: 'input_register_phone',
              ),
              const SizedBox(height: 12),

              // Input: Kata sandi (Min. 8 karakter)
              _buildInputField(
                controller: _passwordController,
                hintText: 'Kata sandi (Min. 8 karakter)',
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                keyName: 'input_register_password',
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 17,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Input: Ulangi Kata Sandi
              _buildInputField(
                controller: _confirmPasswordController,
                hintText: 'Ulangi Kata Sandi',
                prefixIcon: Icons.security_rounded,
                obscureText: _obscureConfirmPassword,
                keyName: 'input_register_confirm_password',
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  child: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 17,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Checkbox: Syarat & Ketentuan (Figma ceklis.png)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: const Alignment(-0.94, -0.69),
                    end: const Alignment(0.94, 0.78),
                    stops: const [0.45, 1.0],
                    colors: [
                      AppColors.primary.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.20),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        key: const Key('checkbox_terms'),
                        value: _isTermsAgreed,
                        activeColor: AppColors.dark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _isTermsAgreed = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        key: const Key('link_syarat_ketentuan'),
                        onTap: _showTermsAndConditions,
                        child: RichText(
                          text: TextSpan(
                            text: 'Saya menyetujui ',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              color: AppColors.dark,
                            ),
                            children: [
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  color: AppColors.dark,
                                ),
                              ),
                              const TextSpan(text: ' RideOn.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tombol BUAT AKUN
              SizedBox(
                height: 42,
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('btn_buat_akun'),
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'BUAT AKUN',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer: Sudah punya akun? Masuk di sini
              GestureDetector(
                key: const Key('link_ke_halaman_masuk'),
                onTap: () => Navigator.of(context).pop(),
                child: RichText(
                  text: TextSpan(
                    text: 'Sudah punya akun? ',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.dark,
                    ),
                    children: [
                      TextSpan(
                        text: 'Masuk di sini',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? keyName,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 42,
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
            color: Colors.black.withValues(alpha: 0.12),
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
          Icon(prefixIcon, size: 19, color: AppColors.dark),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: keyName != null ? Key(keyName) : null,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppColors.dark.withValues(alpha: 0.70),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          ?suffixIcon,
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3303045E),
            offset: Offset(0, 2),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13.0),
          onTap: _submitRegistration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.googleIcon,
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Lanjutkan Dengan Google',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.40),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'ATAU',
            style: GoogleFonts.roboto(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppColors.dark,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.40),
          ),
        ),
      ],
    );
  }
}
