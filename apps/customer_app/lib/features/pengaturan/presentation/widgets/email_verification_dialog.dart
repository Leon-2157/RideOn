import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dialog Menunggu Verifikasi Email dari Gmail (Auto-reload Polling 3 Detik)
class EmailVerificationDialog extends StatefulWidget {
  final String newEmail;
  final String? password;
  final Duration pollInterval;
  final Future<bool> Function()? onCheckVerification;

  const EmailVerificationDialog({
    super.key,
    required this.newEmail,
    this.password,
    this.pollInterval = const Duration(seconds: 3),
    this.onCheckVerification,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  Timer? _timer;
  bool _isChecking = false;
  bool _isManualChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<bool> _checkAndSave({bool isManual = false}) async {
    bool isVerified = false;
    String? currentUid;

    if (widget.onCheckVerification != null) {
      isVerified = await widget.onCheckVerification!();
    } else {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      currentUid = currentUser.uid;

      final targetEmailClean = widget.newEmail.trim().toLowerCase();

      // 1. Coba reload session dengan token baru
      try {
        await currentUser.getIdToken(true);
        await currentUser.reload();
      } catch (_) {}

      final refreshedUser = FirebaseAuth.instance.currentUser;
      final currentAuthEmail = refreshedUser?.email?.trim().toLowerCase();

      if (refreshedUser != null &&
          currentAuthEmail == targetEmailClean &&
          refreshedUser.emailVerified == true) {
        isVerified = true;
      }

      // 2. Fallback Re-auth: HANYA saat user menekan tombol secara manual!
      // Mencegah spam signInWithPassword berulang-ulang di background timer yang memicu Recaptcha rate-limit.
      if (!isVerified && isManual && widget.password != null && widget.password!.isNotEmpty) {
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: targetEmailClean,
            password: widget.password!,
          );
          if (cred.user != null) {
            isVerified = true;
            currentUid = cred.user!.uid;
          }
        } catch (_) {}
      }
    }

    if (isVerified) {
      _timer?.cancel();

      try {
        final uid = currentUid ?? FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'email': widget.newEmail,
            'emailVerified': true,
            'authEmail': widget.newEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Firestore update error in dialog: $e');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    }
    return false;
  }

  void _startPolling() {
    _timer = Timer.periodic(widget.pollInterval, (timer) async {
      if (_isChecking) return;
      _isChecking = true;
      try {
        await _checkAndSave();
      } catch (e) {
        debugPrint('Email verification polling error: $e');
      } finally {
        _isChecking = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FC).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: Color(0xFF6B48FC),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tautan Verifikasi Terkirim!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF17152B).withValues(alpha: 0.75),
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'Tautan verifikasi telah dikirim ke:\n'),
                TextSpan(
                  text: widget.newEmail,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text: '\n\nSilakan periksa Kotak Masuk (Inbox) atau folder Spam pada akun Gmail Anda, lalu klik tautan verifikasi yang kami kirimkan.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FC).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6B48FC).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B48FC)),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Menunggu verifikasi dari Gmail...',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B48FC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tombol Aksi Langsung: SAYA SUDAH VERIFIKASI DI GMAIL
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _isManualChecking
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() {
                        _isManualChecking = true;
                      });
                      final ok = await _checkAndSave(isManual: true);
                      if (!ok && mounted) {
                        setState(() {
                          _isManualChecking = false;
                        });
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tautan belum diklik atau masih diproses Google. Silakan klik tautan di Gmail terlebih dahulu.',
                            ),
                            backgroundColor: Color(0xFFE53935),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1832),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isManualChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'SAYA SUDAH VERIFIKASI DI GMAIL',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.of(context).pop(false);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1B1832), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1832),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
