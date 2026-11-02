import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TokoLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final String? initialIdentifier;

  const TokoLoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.initialIdentifier,
  });

  @override
  State<TokoLoginScreen> createState() => _TokoLoginScreenState();
}

class _TokoLoginScreenState extends State<TokoLoginScreen> {
  // 0: Login, 1: Register Toko Step 1, 2: Register Toko Step 2, 3: OTP, 4: Success
  int _currentStep = 0;

  late final TextEditingController _identifierController;
  final TextEditingController _passwordController = TextEditingController();

  // Register Controllers
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRegisterPassword = true;
  bool _hasLoginError = false;
  bool _isLoading = false;
  bool _agreeTerms = false;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.initialIdentifier ?? '');
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _registerPasswordController.dispose();
    _storeNameController.dispose();
    _storeDescController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _hasLoginError = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasLoginError = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _hasLoginError = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  void _showForgotPasswordSheet() {
    final phoneResetController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: minAxis(),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lupa Kata Sandi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Masukkan nomor WhatsApp atau email yang terdaftar untuk menerima kode reset.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneResetController,
              decoration: InputDecoration(
                hintText: 'No. WhatsApp / Email',
                prefixIcon: const Icon(Icons.contact_mail_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode verifikasi reset kata sandi telah dikirimkan.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('KIRIM KODE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static MainAxisSize minAxis() => MainAxisSize.min;

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
        return _buildRegisterStep1Card();
      case 2:
        return _buildRegisterStep2Card();
      case 3:
        return _buildOtpCard();
      case 4:
        return _buildSuccessCard();
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

          const SizedBox(height: 6),

          // Mitra Toko Badge Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.50), width: 0.8),
            ),
            child: const Text(
              'MITRA TOKO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.dark,
              ),
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
          ),

          const SizedBox(height: 14),

          // Input 2: Kata Sandi
          _buildGlassInputField(
            controller: _passwordController,
            hintText: 'Kata Sandi',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            keyName: 'input_login_password',
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
              onTap: _showForgotPasswordSheet,
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
                children: const [
                  Icon(Icons.error_outline_rounded, color: Color(0xFFE83535), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email/WhatsApp atau kata sandi yang Anda masukkan salah.',
                      style: TextStyle(
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
            onTap: () => setState(() => _currentStep = 1),
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

  Widget _buildRegisterStep1Card() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Daftar Akun',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lengkapi data diri pemilik untuk memulai',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 16),

          // Google Button at top matching Figma
          _buildGoogleButton(),

          const SizedBox(height: 12),

          _buildOrDivider(),

          const SizedBox(height: 12),

          // Input 1: Nama Lengkap
          _buildGlassInputField(
            controller: _ownerNameController,
            hintText: 'Nama Lengkap',
            prefixIcon: Icons.person_rounded,
          ),

          const SizedBox(height: 12),

          // Input 2: No. WhatsApp Aktif
          _buildGlassInputField(
            controller: _phoneController,
            hintText: 'No. WhatsApp Aktif',
            prefixIcon: Icons.chat_bubble_rounded,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          // Input 3: Alamat Email
          _buildGlassInputField(
            controller: _emailController,
            hintText: 'Alamat Email',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          // Input 4: Kata Sandi
          _buildGlassInputField(
            controller: _registerPasswordController,
            hintText: 'Kata sandi (Min. 8 karakter)',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscureRegisterPassword,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
              child: Icon(
                _obscureRegisterPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.dark,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Button: LANJUTKAN
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text(
                'LANJUTKAN',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Footer link
          GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
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

  Widget _buildRegisterStep2Card() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Kelengkapan Toko',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informasi toko untuk pelanggan Anda',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 18),

          _buildGlassInputField(
            controller: _storeNameController,
            hintText: 'Nama Toko / Resto',
            prefixIcon: Icons.storefront_rounded,
          ),

          const SizedBox(height: 12),

          _buildGlassInputField(
            controller: _storeDescController,
            hintText: 'Kategori / Deskripsi Toko',
            prefixIcon: Icons.description_rounded,
          ),

          const SizedBox(height: 12),

          _buildGlassInputField(
            controller: _addressController,
            hintText: 'Alamat Lengkap Toko',
            prefixIcon: Icons.location_on_rounded,
          ),

          const SizedBox(height: 12),

          _buildGlassInputField(
            controller: _postalController,
            hintText: 'Kode Pos',
            prefixIcon: Icons.markunread_mailbox_rounded,
            keyboardType: TextInputType.number,
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
                          ),
                        ),
                        TextSpan(text: ' Mitra RideOn.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text(
                'BUAT AKUN',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 14),

          GestureDetector(
            onTap: () => setState(() => _currentStep = 1),
            child: const Text(
              '← Kembali ke Data Pemilik',
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
            child: const Icon(Icons.chat_bubble_rounded, color: AppColors.dark, size: 26),
          ),

          const SizedBox(height: 14),

          const Text(
            'Verifikasi WhatsApp',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
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
            height: 46,
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
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _currentStep = 4),
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

          const SizedBox(height: 14),

          GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
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

  Widget _buildSuccessCard() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          const Text(
            'Akun berhasil dibuat!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Akun Anda telah berhasil dibuat.\nSilakan masuk dan bereksplorasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: widget.onLoginSuccess,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(
                'MASUK SEKARANG',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
          const SizedBox(height: 6),
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
