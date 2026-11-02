import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  // 0: Login, 1: Daftar Pemilik Toko, 2: Lengkapi Daftar Toko, 3: Berkas Berhasil di Upload
  int _currentStep = 0;

  late final TextEditingController _identifierController;
  final TextEditingController _passwordController = TextEditingController();

  // Register Pemilik Controllers (3 fields matching Figma)
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Lengkapi Toko Controllers (5 fields matching Figma)
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'Indonesia');

  // Track uploaded document indices
  final Set<int> _uploadedIndices = {};

  bool _obscurePassword = true;
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
    _storeNameController.dispose();
    _storeDescController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    _countryController.dispose();
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
          mainAxisSize: MainAxisSize.min,
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

  void _showPhotoPickerSheet(int itemIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                  await picker.pickImage(source: ImageSource.camera);
                } catch (_) {}
                if (mounted) {
                  setState(() => _uploadedIndices.add(itemIndex));
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
                  await picker.pickImage(source: ImageSource.gallery);
                } catch (_) {}
                if (mounted) {
                  setState(() => _uploadedIndices.add(itemIndex));
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
                            'Syarat & Ketentuan RideOn',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ketentuan umum penggunaan layanan transportasi',
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
                      'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.dark),
                    ),
                    const SizedBox(height: 12),
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
                        'Segala sengketa atau perselisihan adalah tanggung jawab penuh antara Mitra Pengemudi dan Customer. RideOn hanya akan bertindak sebagai mediator untuk membantu menyelesaikan perselisihan jika diperlukan.',
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
        return _buildRegisterStep1Card();
      case 2:
        return _buildRegisterStep2Card();
      case 3:
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

  // ===========================================================================
  // Step 1: Daftar Pemilik Toko (Matching Figma Image 1)
  // ===========================================================================
  Widget _buildRegisterStep1Card() {
    return _buildGlassCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Daftar Pemilik Toko',
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
              color: AppColors.dark.withValues(alpha: 0.80),
            ),
          ),

          const SizedBox(height: 20),

          // Field 1: Nama Pemilik
          _buildGlassInputField(
            controller: _ownerNameController,
            hintText: 'Nama Pemilik',
            prefixIcon: Icons.person_rounded,
          ),

          const SizedBox(height: 14),

          // Field 2: No. HP / WhatsApp Aktif
          _buildGlassInputField(
            controller: _phoneController,
            hintText: 'No. HP / WhatsApp Aktif',
            prefixIcon: Icons.chat_bubble_rounded,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 14),

          // Field 3: Email
          _buildGlassInputField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 22),

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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Footer link: Sudah punya akun? Masuk di sini
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

  // ===========================================================================
  // Step 2: Lengkapi Daftar Toko (Matching Figma Image 2, 3, 4)
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
            prefixIcon: Icons.two_wheeler_rounded,
          ),

          const SizedBox(height: 12),

          // Field 4: Kode Pos
          _buildUploadField(
            index: 3,
            controller: _postalController,
            hintText: 'Kode Pos',
            prefixIcon: Icons.account_balance_wallet_rounded,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          // Field 5: Negara
          _buildUploadField(
            index: 4,
            controller: _countryController,
            hintText: 'Negara',
            prefixIcon: Icons.shield_rounded,
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
                if (!_agreeTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap setujui Syarat & Ketentuan terlebih dahulu.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  return;
                }
                setState(() => _currentStep = 3);
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

  // Helper widget with camera scanner suffix & floating Terupload badge
  Widget _buildUploadField({
    required int index,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
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
          keyboardType: keyboardType,
          suffixIcon: GestureDetector(
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
  // Step 3: Berkas Berhasil di Upload (Matching Figma Image 4 Right Panel)
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
            'Tim operasional sedang memvalidasi Keaslian Berkas\nAnda. Proses aktivasi radar memakan waktu 1x24 jam.',
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
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(
                'CEK EMAIL SEKARANG',
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
