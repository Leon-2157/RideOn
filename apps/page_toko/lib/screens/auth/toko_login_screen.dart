import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TokoLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const TokoLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<TokoLoginScreen> createState() => _TokoLoginScreenState();
}

class _TokoLoginScreenState extends State<TokoLoginScreen> {
  // 0: Login, 1: Register Step 1, 2: Register Step 2, 3: OTP Verification, 4: Success
  int _currentStep = 0;
  bool _obscurePassword = true;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'Indonesia');
  final TextEditingController _otpController = TextEditingController();

  bool _agreeTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _storeNameController.dispose();
    _storeDescController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: linear state machine for onboarding & auth; upgrade to multi-route Navigator if deep-linking needed
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7C5EF8),
              Color(0xFF9E8AF9),
              Color(0xFFEDE9FE),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _buildCurrentCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCard() {
    switch (_currentStep) {
      case 0:
        return _buildLoginCard();
      case 1:
        return _buildRegisterStep1Card();
      case 2:
        return _buildRegisterStep2Card();
      case 3:
        return _buildOtpCard();
      case 4:
        return _buildSuccessCard();
      default:
        return _buildLoginCard();
    }
  }

  Widget _buildLoginCard() {
    return _baseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          _buildLogo(),
          const SizedBox(height: 30),
          _inputField(
            controller: _usernameController,
            hint: 'No. WhatsApp / Email',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _passwordController,
            hint: 'Kata Sandi',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Silakan hubungi admin atau gunakan WhatsApp')),
                );
              },
              child: const Text(
                'Lupa kata sandi?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: 'MASUK',
            onTap: () => setState(() => _currentStep = 4),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('ATAU', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),
          _googleButton(),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _currentStep = 1),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'Belum punya akun? '),
                  TextSpan(
                    text: 'Daftar Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRegisterStep1Card() {
    return _baseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Daftar Pemilik Toko',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lengkapi data diri Anda untuk memulai',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _inputField(
            controller: _ownerNameController,
            hint: 'Nama Pemilik',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _phoneController,
            hint: 'No. HP / WhatsApp Aktif',
            icon: Icons.chat_bubble_outline_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _actionButton(
            label: 'LANJUTKAN',
            onTap: () => setState(() => _currentStep = 2),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'Sudah punya akun? '),
                  TextSpan(
                    text: 'Masuk di sini',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRegisterStep2Card() {
    return _baseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Lengkapi Daftar Toko',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lengkapi Toko untuk memulai',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _inputField(controller: _storeNameController, hint: 'Nama Toko', icon: Icons.storefront_outlined),
          const SizedBox(height: 12),
          _inputField(controller: _storeDescController, hint: 'Deskripsi', icon: Icons.description_outlined),
          const SizedBox(height: 12),
          _inputField(controller: _addressController, hint: 'Alamat Lengkap', icon: Icons.location_on_outlined),
          const SizedBox(height: 12),
          _inputField(controller: _postalController, hint: 'Kode Pos', icon: Icons.markunread_mailbox_outlined),
          const SizedBox(height: 12),
          _inputField(controller: _countryController, hint: 'Negara', icon: Icons.public_outlined),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                ),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      children: [
                        TextSpan(text: 'Saya menyetujui '),
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        TextSpan(text: ' RideOn.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _actionButton(
            label: 'UPLOAD',
            onTap: () => setState(() => _currentStep = 3),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'Sudah punya akun? '),
                  TextSpan(
                    text: 'Masuk di sini',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return _baseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verifikasi WhatsApp',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Masukkan OTP yang dikirim ke WhatsApp Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              filled: true,
              fillColor: AppColors.primarySoft.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kode kadaluarsa dalam\n5:00',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 22),
          _actionButton(
            label: 'VERIFIKASI',
            icon: Icons.send_rounded,
            onTap: () => setState(() => _currentStep = 4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.arrow_back, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Kembali ke halaman Masuk',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return _baseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'LOGIN BERHASIL',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selamat datang di Mitra Toko RideOn',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 30),
          _actionButton(
            label: 'MASUK SEKARANG',
            icon: Icons.login_rounded,
            onTap: widget.onLoginSuccess,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFDCD5FB).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 70,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.bolt_rounded, size: 36, color: AppColors.primary),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textPrimary, size: 20),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.6), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => setState(() => _currentStep = 4),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 4),
            Text(
              'Lanjutkan Dengan Google',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
