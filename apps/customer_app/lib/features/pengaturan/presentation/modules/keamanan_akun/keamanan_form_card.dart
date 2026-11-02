import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input field dengan toggle eye untuk password
class KeamananPasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscure;
  final VoidCallback onToggle;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const KeamananPasswordInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscure,
    required this.onToggle,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCD7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        onChanged: onChanged,
        style:
            GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF17152B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.roboto(
              fontSize: 12, color: const Color(0xFF6B6680)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF17152B),
            ),
            onPressed: enabled ? onToggle : null,
          ),
        ),
      ),
    );
  }
}

/// Form Card untuk Mengubah Kata Sandi Akun
class KeamananFormCard extends StatelessWidget {
  final TextEditingController oldPassController;
  final TextEditingController newPassController;
  final TextEditingController confirmPassController;
  final bool obscureOld;
  final bool obscureNew;
  final bool obscureConfirm;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onToggleOld;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onFieldChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onSavePassword;

  const KeamananFormCard({
    super.key,
    required this.oldPassController,
    required this.newPassController,
    required this.confirmPassController,
    required this.obscureOld,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    required this.onToggleOld,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onFieldChanged,
    required this.onForgotPassword,
    required this.onSavePassword,
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
          // Error Message Banner (jika ada)
          if (hasError && errorMessage != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Text(
            'Kata Sandi Saat ini *',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          KeamananPasswordInput(
            key: const Key('field_old_password'),
            controller: oldPassController,
            hintText: 'Masukkan sandi saat ini',
            obscure: obscureOld,
            enabled: !isLoading,
            onChanged: (_) => onFieldChanged(),
            onToggle: onToggleOld,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              key: const Key('link_lupa_kata_sandi'),
              onTap: isLoading ? null : onForgotPassword,
              child: Text(
                'Lupa kata sandi?',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF17152B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Kata Sandi Baru *',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          KeamananPasswordInput(
            key: const Key('field_new_password'),
            controller: newPassController,
            hintText: 'Minimal 8 karakter',
            obscure: obscureNew,
            enabled: !isLoading,
            onChanged: (_) => onFieldChanged(),
            onToggle: onToggleNew,
          ),
          const SizedBox(height: 18),

          Text(
            'Konfirmasi Sandi Baru',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          KeamananPasswordInput(
            key: const Key('field_confirm_password'),
            controller: confirmPassController,
            hintText: 'Ketik ulang sandi baru',
            obscure: obscureConfirm,
            enabled: !isLoading,
            onChanged: (_) => onFieldChanged(),
            onToggle: onToggleConfirm,
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: isLoading ? null : onSavePassword,
            child: Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isLoading
                    ? const Color(0xFF1B1832).withValues(alpha: 0.7)
                    : const Color(0xFF1B1832),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'SIMPAN SANDI BARU',
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
