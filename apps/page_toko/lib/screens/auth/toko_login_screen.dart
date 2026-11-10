import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/toko_state.dart';
import '../../theme/app_colors.dart';

class TokoLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final String? initialIdentifier;
  final Set<int>? initialUploadedIndices;

  const TokoLoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.initialIdentifier,
    this.initialUploadedIndices,
  });

  @override
  State<TokoLoginScreen> createState() => _TokoLoginScreenState();
}

class _TokoLoginScreenState extends State<TokoLoginScreen> {
  // 0: Login (frame 15)
  // 1: Lupa Kata Sandi (frame 20)
  // 2: Verifikasi WhatsApp OTP (frame 22)
  // 3: Lengkapi Daftar Toko (frame 27)
  // 4: Berkas Berhasil di Upload (frame 31)
  // 5: Buat Kata Sandi Baru
  int _currentStep = 0;

  late final TextEditingController _identifierController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotIdentifierController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Lengkapi Toko Controllers (matching Figma + owner name)
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _storeDescController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'Indonesia');

  // Track uploaded document indices
  final Set<int> _uploadedIndices = {};

  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasLoginError = false;
  String _loginErrorMessage = 'Email/WhatsApp dan kata sandi wajib diisi.';
  bool _isLoading = false;
  bool _agreeTerms = false;

  Timer? _otpTimer;
  int _otpSecondsLeft = 300;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.initialIdentifier ?? '');
    if (widget.initialUploadedIndices != null) {
      _uploadedIndices.addAll(widget.initialUploadedIndices!);
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    _forgotIdentifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _storeDescController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step != 2) {
      _otpTimer?.cancel();
    }
    setState(() {
      _hasLoginError = false;
      _currentStep = step;
    });
    if (step == 2) {
      _startOtpTimer();
    }
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => _otpSecondsLeft = 300);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpSecondsLeft > 0) {
        setState(() => _otpSecondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  bool _isValidIdentifier(String value) {
    final v = value.trim();
    if (v.contains('@')) {
      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    }
    final digits = v.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    return RegExp(r'^0?\d{8,15}$').hasMatch(digits);
  }

  Future<void> _submitLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _hasLoginError = true;
        _loginErrorMessage = 'Email/WhatsApp dan kata sandi wajib diisi.';
      });
      return;
    }

    if (!_isValidIdentifier(identifier) || password.length < 6) {
      setState(() {
        _hasLoginError = true;
        _loginErrorMessage = 'Masukkan email / No. WA valid dan sandi minimal 6 karakter.';
      });
      return;
    }

    // ponytail: local format validation gates login until backend auth API is connected
    setState(() {
      _isLoading = true;
      _hasLoginError = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _hasLoginError = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  void _showPhotoPickerSheet(int itemIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pilih Foto',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Ambil Dari Kamera',
                  subtitle: 'Buka Kamera dan Ambil Foto',
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.camera);
                      if (picked != null && mounted) {
                        setState(() => _uploadedIndices.add(itemIndex));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengambil foto: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildPickerOption(
                  icon: Icons.image_rounded,
                  title: 'Pilih Dari Galeri',
                  subtitle: 'Pilih Foto Dari Perangkat',
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null && mounted) {
                        setState(() => _uploadedIndices.add(itemIndex));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal memilih foto: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2DCFE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.dark, size: 22),
          ],
        ),
      ),
    );
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF1EFFE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Syarat & Ketentuan Mitra Toko RideOn',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ketentuan umum kemitraan toko kuliner & merchant',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.dark),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFC6BCFF)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    const Text(
                      'Selamat datang di RideOn Merchant. Dengan mendaftarkan toko dan menggunakan platform ini, Anda menyatakan tunduk dan terikat pada ketentuan kemitraan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.dark),
                    ),
                    const SizedBox(height: 12),
                    _buildTermsSection(
                      '1. Ketentuan Umum Kemitraan Toko',
                      [
                        'RideOn adalah platform perantara yang menghubungkan Mitra Toko Makanan dengan Pelanggan serta Mitra Pengemudi untuk layanan pemesanan dan pengantaran kuliner.',
                        'Mitra Toko bertanggung jawab atas keabsahan informasi toko, alamat outlet, jam operasional, serta daftar menu yang ditampilkan pada aplikasi.',
                        'Pendaftar atau pengelola akun Mitra Toko wajib berusia minimal 17 tahun dan memiliki identitas serta izin usaha yang sah.',
                      ],
                    ),
                    _buildTermsSection(
                      '2. Kualitas Menu & Kebersihan Pangan',
                      [
                        'Mitra Toko wajib memastikan seluruh makanan dan minuman yang disajikan bersih, aman dikonsumsi, halal sesuai keterangan menu, dan sesuai deskripsi serta harga.',
                        'Mitra Toko wajib memperbarui ketersediaan stok menu secara berkala dan mengemas pesanan dengan rapi agar aman selama pengantaran oleh kurir.',
                      ],
                    ),
                    _buildTermsSection(
                      '3. Pemrosesan Pesanan & Pencairan Saldo',
                      [
                        'Mitra Toko wajib merespons pesanan masuk dalam batas waktu konfirmasi dan menyiapkan pesanan sesuai estimasi waktu masak.',
                        'Hasil penjualan non-tunai masuk ke Saldo Aktif Toko setelah pesanan selesai dan dapat dicairkan ke rekening bank terverifikasi milik pemilik toko.',
                      ],
                    ),
                    _buildTermsSection(
                      '4. Batasan Tanggung Jawab',
                      [
                        'RideOn berhak menonaktifkan sementara akun toko apabila ditemukan pelanggaran keamanan pangan, penolakan pesanan berulang tanpa alasan, atau penyalahgunaan data.',
                        'Perselisihan antara Mitra Toko, Pelanggan, atau Mitra Pengemudi akan diselesaikan melalui mekanisme mediasi tim operasional RideOn.',
                      ],
                    ),
                  ],
                ),
              ),
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
                      setState(() => _agreeTerms = true);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'SAYA MENGERTI & SETUJU',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildTermsSection(String heading, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
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
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
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
    // ponytail: single root screen handles auth states; upgrade to route-based when deep linking needed
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
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 18.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 24,
                ),
                child: _buildCurrentCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCard() {
    switch (_currentStep) {
      case 0:
        return _buildGlassLoginCard();
      case 1:
        return _buildForgotPasswordCard();
      case 2:
        return _buildOtpCard();
      case 3:
        return _buildRegisterStep2Card();
      case 4:
        return _buildSuccessCard();
      case 5:
        return _buildResetPasswordCard();
      default:
        return _buildGlassLoginCard();
    }
  }

  Widget _buildGlassCardWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: const Color(0xFFF1F1FD).withValues(alpha: 0.65),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 8),
                blurRadius: 24.0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ===========================================================================
  // Step 0: Login Card (Figma frame 15)
  // ===========================================================================
  Widget _buildGlassLoginCard() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo RideOn (White vector/png)
          Image.asset(
            'assets/images/logo_white.png',
            width: 124,
            height: 75,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.bolt_rounded,
              size: 54,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Input 1: No. WhatsApp / Email
          _buildGlassInputField(
            controller: _identifierController,
            hintText: 'No. WhatsApp / Email',
            prefixIcon: Icons.person_rounded,
            keyboardType: TextInputType.emailAddress,
            keyName: 'input_login_identifier',
            onChanged: (_) {
              if (_hasLoginError) setState(() => _hasLoginError = false);
            },
          ),

          const SizedBox(height: 14),

          // Input 2: Kata Sandi
          _buildGlassInputField(
            controller: _passwordController,
            hintText: 'Kata Sandi',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            keyName: 'input_login_password',
            onChanged: (_) {
              if (_hasLoginError) setState(() => _hasLoginError = false);
            },
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.dark,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Lupa kata sandi?
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _goToStep(1),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Error banner
          if (_hasLoginError) ...[
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
                      _loginErrorMessage,
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

          // Button: MASUK
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('btn_masuk_login'),
              onPressed: _isLoading ? null : _submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13.0),
                ),
                padding: EdgeInsets.zero,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'MASUK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // Divider: ATAU
          _buildOrDivider(),

          const SizedBox(height: 14),

          // Button: Lanjutkan Dengan Google
          _buildGoogleButton(),

          const SizedBox(height: 22),

          // Footer: Belum punya akun? Daftar Sekarang
          GestureDetector(
            key: const Key('link_daftar_sekarang'),
            onTap: () => _goToStep(3),
            child: RichText(
              text: TextSpan(
                text: 'Belum punya akun? ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.85),
                ),
                children: const [
                  TextSpan(
                    text: 'Daftar Sekarang',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      decoration: TextDecoration.underline,
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

  // ===========================================================================
  // Step 1: Lupa Kata Sandi Card (Figma frame 20)
  // ===========================================================================
  Widget _buildForgotPasswordCard() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.60), width: 1),
            ),
            child: const Icon(Icons.vpn_key_rounded, color: AppColors.dark, size: 24),
          ),

          const SizedBox(height: 16),

          const Text(
            'Lupa Kata Sandi?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan nomor WhatsApp atau alamat email\nyang terdaftar di akun RideOn Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 20),

          _buildGlassInputField(
            controller: _forgotIdentifierController,
            hintText: 'No. WhatsApp / Email',
            prefixIcon: Icons.person_rounded,
            keyboardType: TextInputType.emailAddress,
            keyName: 'input_forgot_identifier',
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final ident = _forgotIdentifierController.text.trim();
                if (ident.isEmpty || !_isValidIdentifier(ident)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan nomor WhatsApp atau email yang valid.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                _goToStep(2);
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'KIRIM KODE OTP',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _goToStep(0),
            child: const Text(
              '← Kembali ke halaman Masuk',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 2: Verifikasi WhatsApp OTP (Figma frame 22)
  // ===========================================================================
  Widget _buildOtpCard() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.60), width: 1),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: AppColors.dark, size: 24),
          ),

          const SizedBox(height: 16),

          const Text(
            'Verifikasi WhatsApp',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan OTP yang dikirim ke WhatsApp Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
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
            child: Center(
              child: TextField(
                key: const Key('input_otp_code'),
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '1 2 3 4 5 6',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    letterSpacing: 6,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textMuted.withValues(alpha: 0.45),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Kode kadaluarsa dalam\n${(_otpSecondsLeft ~/ 60)}:${(_otpSecondsLeft % 60).toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.70),
            ),
          ),

          const SizedBox(height: 6),

          GestureDetector(
            onTap: () {
              _startOtpTimer();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode OTP baru telah dikirimkan ke WhatsApp Anda.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text(
              'Kirim Ulang Kode',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final otp = _otpController.text.trim();
                if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan 6 digit kode OTP yang valid.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (_otpSecondsLeft <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode OTP sudah kadaluarsa. Silakan kirim ulang kode.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                _goToStep(5);
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'VERIFIKASI',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _goToStep(0),
            child: const Text(
              '← Kembali ke halaman Masuk',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 5: Buat Sandi Baru (setelah verifikasi OTP berhasil)
  // ===========================================================================
  Widget _buildResetPasswordCard() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.60), width: 1),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.dark, size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Buat Sandi Baru',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan kata sandi baru minimal 6 karakter\nuntuk mengamankan akun toko Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassInputField(
            controller: _newPasswordController,
            hintText: 'Kata Sandi Baru',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscureNewPassword,
            keyName: 'input_new_password',
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              child: Icon(
                _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildGlassInputField(
            controller: _confirmPasswordController,
            hintText: 'Konfirmasi Kata Sandi',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            keyName: 'input_confirm_password',
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              child: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              key: const Key('btn_save_new_password'),
              onPressed: () {
                final newPass = _newPasswordController.text;
                final confirmPass = _confirmPasswordController.text;
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kata sandi baru minimal 6 karakter.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Konfirmasi kata sandi tidak cocok.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                _newPasswordController.clear();
                _confirmPasswordController.clear();
                _otpController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kata sandi berhasil diperbarui. Silakan masuk.'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _goToStep(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text(
                'SIMPAN KATA SANDI',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _goToStep(0),
            child: const Text(
              '← Kembali ke halaman Masuk',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 3: Lengkapi Daftar Toko (Figma frame 27)
  // ===========================================================================
  Widget _buildRegisterStep2Card() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Lengkapi Daftar Toko',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lengkapi Toko untuk memulai',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 18),

          // Field 1: Nama Toko
          _buildUploadField(
            index: 0,
            controller: _storeNameController,
            hintText: 'Nama Toko',
            prefixIcon: Icons.storefront_rounded,
            keyName: 'input_reg_store_name',
          ),

          const SizedBox(height: 12),

          // Field: Nama Pemilik
          _buildGlassInputField(
            controller: _ownerNameController,
            hintText: 'Nama Pemilik',
            prefixIcon: Icons.badge_rounded,
            keyName: 'input_reg_owner_name',
          ),

          const SizedBox(height: 12),

          // Field 2: Deskripsi
          _buildUploadField(
            index: 1,
            controller: _storeDescController,
            hintText: 'Deskripsi',
            prefixIcon: Icons.subject_rounded,
          ),

          const SizedBox(height: 12),

          // Field 3: Alamat Lengkap
          _buildUploadField(
            index: 2,
            controller: _addressController,
            hintText: 'Alamat Lengkap',
            prefixIcon: Icons.location_on_rounded,
            keyName: 'input_reg_address',
          ),

          const SizedBox(height: 12),

          // Field 4: Kode Pos
          _buildUploadField(
            index: 3,
            controller: _postalController,
            hintText: 'Kode Pos',
            prefixIcon: Icons.markunread_mailbox_rounded,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          // Field 5: Negara
          _buildUploadField(
            index: 4,
            controller: _countryController,
            hintText: 'Negara',
            prefixIcon: Icons.public_rounded,
          ),

          const SizedBox(height: 14),

          // Checkbox container matching Figma
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.18),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  activeColor: AppColors.dark,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsSheet,
                    child: RichText(
                      text: TextSpan(
                        text: 'Saya menyetujui ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.85),
                        ),
                        children: const [
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' RideOn.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Button: UPLOAD
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final storeName = _storeNameController.text.trim();
                final address = _addressController.text.trim();
                final postal = _postalController.text.trim();
                final country = _countryController.text.trim();
                final messenger = ScaffoldMessenger.of(context);

                if (storeName.isEmpty) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Nama Toko wajib diisi.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (address.isEmpty) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Alamat Lengkap wajib diisi.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (postal.isNotEmpty && !RegExp(r'^\d{5,}$').hasMatch(postal)) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Kode Pos harus minimal 5 digit angka.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (country.isEmpty) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Negara wajib diisi.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (_uploadedIndices.isEmpty) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Unggah minimal 1 foto/berkas verifikasi toko.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                if (!_agreeTerms) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Harap setujui Syarat & Ketentuan terlebih dahulu.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  return;
                }

                TokoState.storeName.value = storeName;
                if (_ownerNameController.text.trim().isNotEmpty) {
                  TokoState.ownerName.value = _ownerNameController.text.trim();
                }
                if (_storeDescController.text.trim().isNotEmpty) {
                  TokoState.storeCategory.value = _storeDescController.text.trim();
                }
                TokoState.storeAddress.value = address;
                if (postal.isNotEmpty) {
                  TokoState.storePostal.value = postal;
                }
                TokoState.storeCountry.value = country;

                _goToStep(4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text(
                'UPLOAD',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Footer link
          GestureDetector(
            onTap: () => _goToStep(0),
            child: RichText(
              text: TextSpan(
                text: 'Sudah punya akun? ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.85),
                ),
                children: const [
                  TextSpan(
                    text: 'Masuk di sini',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      decoration: TextDecoration.underline,
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

  // Helper widget with camera scanner suffix & floating Terupload badge
  Widget _buildUploadField({
    required int index,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? keyName,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isUploaded = _uploadedIndices.contains(index);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildGlassInputField(
          controller: controller,
          hintText: hintText,
          prefixIcon: prefixIcon,
          keyName: keyName,
          keyboardType: keyboardType,
          suffixIcon: GestureDetector(
            key: Key('btn_upload_doc_$index'),
            onTap: () => _showPhotoPickerSheet(index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(Icons.crop_free_rounded, size: 21, color: AppColors.dark),
                  Icon(Icons.camera_alt_rounded, size: 10, color: AppColors.dark),
                ],
              ),
            ),
          ),
        ),
        if (isUploaded)
          Positioned(
            top: -7,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Terupload',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // Step 4: Berkas Berhasil di Upload (Figma frame 31)
  // ===========================================================================
  Widget _buildSuccessCard() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 14),

          const Text(
            'BERKAS BERHASIL DI UPLOAD',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.dark,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Tim operasional sedang memvalidasi Keaslian Berkas\nAnda. Proses verifikasi berkas toko memakan waktu 1×24 jam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _goToStep(0),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(
                'KEMBALI KE HALAMAN MASUK',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menghubungkan ke Tim CS WhatsApp RideOn...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text(
              'Bantuan Pendaftaran Mitra (CS WhatsApp)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? keyName,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
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
      child: Row(
        children: [
          Icon(
            prefixIcon,
            size: 18,
            color: AppColors.dark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: keyName != null ? Key(keyName) : null,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hintText,
                hintStyle: TextStyle(
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
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2003045E),
            offset: Offset(0, 2),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('btn_google_login'),
          borderRadius: BorderRadius.circular(13.0),
          onTap: _isLoading ? null : _handleGoogleLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/google_icon.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.g_mobiledata_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Lanjutkan Dengan Google',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
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
            color: AppColors.dark.withValues(alpha: 0.30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'ATAU',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.75),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.30),
          ),
        ),
      ],
    );
  }
}
