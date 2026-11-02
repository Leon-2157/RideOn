import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/features/pengaturan/presentation/widgets/sub_header_widget.dart';

/// Form Card Step 1: Input Kata Sandi Akun + Email Lama (jika ada) + Email Baru
class AlamatEmailFormCard extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController oldEmailController;
  final TextEditingController newEmailController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool hasCurrentEmail;
  final String currentEmail;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const AlamatEmailFormCard({
    super.key,
    required this.passwordController,
    required this.oldEmailController,
    required this.newEmailController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.hasCurrentEmail,
    required this.currentEmail,
    required this.isLoading,
    this.hasError = false,
    this.errorMessage,
    required this.onSubmit,
  });

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
          Row(
            children: [
              Expanded(
                child: Text(
                  hasCurrentEmail ? 'Perbarui Alamat Email' : 'Hubungkan Email Anda',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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

          // Jika sudah ada email sebelumnya: Tampilkan Field Email Lama
          if (hasCurrentEmail) ...[
            Text(
              'Alamat Email Lama',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 8),
            buildInputField(
              controller: oldEmailController,
              hintText: 'Contoh: $currentEmail',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
          ],

          // Field Email Baru / Email Aktif
          Text(
            hasCurrentEmail ? 'Alamat Email Baru' : 'Alamat Email Aktif',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          buildInputField(
            controller: newEmailController,
            hintText: 'peter@gmail.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          if (hasError && errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Tombol VERIFIKASI EMAIL / KIRIM KODE OTP
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
                        'VERIFIKASI EMAIL',
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
