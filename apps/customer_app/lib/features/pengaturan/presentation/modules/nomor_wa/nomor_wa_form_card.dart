import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/features/pengaturan/presentation/widgets/country_code_selector.dart';

/// Form Card Step 1: Input Kata Sandi + No WA Lama (jika ada) + No WA Baru
class NomorWaFormCard extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController oldPhoneController;
  final TextEditingController newPhoneController;
  final CountryCode selectedOldCountry;
  final CountryCode selectedNewCountry;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSelectOldCountry;
  final VoidCallback onSelectNewCountry;
  final bool hasCurrentPhone;
  final bool isLoading;
  final VoidCallback onSubmit;

  const NomorWaFormCard({
    super.key,
    required this.passwordController,
    required this.oldPhoneController,
    required this.newPhoneController,
    required this.selectedOldCountry,
    required this.selectedNewCountry,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSelectOldCountry,
    required this.onSelectNewCountry,
    required this.hasCurrentPhone,
    required this.isLoading,
    required this.onSubmit,
  });

  Widget _buildPhoneInputField({
    required TextEditingController controller,
    required CountryCode selectedCountry,
    required VoidCallback onCountryTap,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCD7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          InkWell(
            onTap: onCountryTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    selectedCountry.dialCode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF17152B),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 22,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFF17152B).withValues(alpha: 0.25),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                PhoneNumberFormatter(),
              ],
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF17152B),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xFF17152B).withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field 1: Konfirmasi Kata Sandi Akun dengan Eye Toggle
          Text(
            'Konfirmasi Kata Sandi Akun',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDCD7FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: Color(0xFF17152B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xFF17152B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi akun',
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 13,
                        color: const Color(0xFF17152B).withValues(alpha: 0.45),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF17152B).withValues(alpha: 0.7),
                  ),
                  onPressed: onTogglePassword,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Field 2: Nomor WhatsApp Lama (Hanya tampil jika akun sudah ada nomor sebelumnya)
          if (hasCurrentPhone) ...[
            Text(
              'Nomor WhatsApp Lama',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 8),
            _buildPhoneInputField(
              controller: oldPhoneController,
              selectedCountry: selectedOldCountry,
              onCountryTap: onSelectOldCountry,
              hintText: '812 3456 7890',
            ),
            const SizedBox(height: 16),
          ],

          // Field 3: Nomor WhatsApp Baru
          Text(
            'Nomor WhatsApp Baru',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          _buildPhoneInputField(
            controller: newPhoneController,
            selectedCountry: selectedNewCountry,
            onCountryTap: onSelectNewCountry,
            hintText: '853 2344 1080',
          ),
          const SizedBox(height: 24),

          // Tombol Submit Form
          GestureDetector(
            onTap: isLoading ? null : onSubmit,
            child: Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1832),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'KIRIM KODE OTP WHATSAPP',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
