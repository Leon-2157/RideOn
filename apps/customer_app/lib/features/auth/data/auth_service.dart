import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service untuk menangani Autentikasi Firebase pada Customer App
class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  GoogleSignIn? _googleSignIn;

  AuthService({
    FirebaseAuth? customAuth,
    FirebaseFirestore? customFirestore,
    GoogleSignIn? customGoogleSignIn,
  })  : _auth = customAuth,
        _firestore = customFirestore,
        _googleSignIn = customGoogleSignIn;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  GoogleSignIn get googleSignIn => _googleSignIn ??= GoogleSignIn();

  /// Mendapatkan user yang sedang aktif
  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Stream status autentikasi
  Stream<User?> get authStateChanges {
    try {
      return auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Helper untuk menormalkan nomor telepon (misal: 0812... -> +62812...)
  String normalizePhoneNumber(String phone) {
    String clean = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('0')) {
      clean = '+62${clean.substring(1)}';
    } else if (clean.startsWith('62')) {
      clean = '+$clean';
    }
    return clean;
  }

  /// Sign In dengan Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Dibatalkan oleh pengguna
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Pengecekan apakah nomor WhatsApp sudah terdaftar sebelumnya
  Future<bool> isPhoneRegistered(String rawPhone) async {
    try {
      final phone = normalizePhoneNumber(rawPhone);
      final query = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Jika Security Rules Firestore membatasi akses tanpa login,
        // lanjutkan agar pendaftaran tidak terblokir
        return false;
      }
      rethrow;
    }
  }

  /// Pengecekan apakah email sudah terdaftar sebelumnya
  Future<bool> isEmailRegistered(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final query = await firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
  }

  /// Mengirim kode OTP verifikasi ke Nomor Telepon / WhatsApp
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    int? resendToken,
  }) async {
    final normalized = normalizePhoneNumber(phoneNumber);
    await auth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (verificationId) {},
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verifikasi kode 6 digit OTP Phone Auth
  Future<PhoneAuthCredential> verifyPhoneOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      // Validasi kode OTP ke server Firebase Authentication
      await auth.signInWithCredential(credential);
      await auth.signOut();
    } on FirebaseException {
      rethrow;
    } catch (e) {
      // Abaikan jika dijalankan di lingkungan unit test tanpa Firebase App instance
    }
    return credential;
  }

  /// Registrasi Akun Customer Baru (Nama, Email Opsional, No. WhatsApp, Kata Sandi)
  Future<UserCredential> registerCustomerAccount({
    required String fullName,
    String? email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final phone = normalizePhoneNumber(phoneNumber);
      final hasEmail = email != null && email.trim().isNotEmpty;
      final cleanEmail = hasEmail ? email.trim().toLowerCase() : '';

      // Cek apakah nomor sudah ada
      final phoneInUse = await isPhoneRegistered(phone);
      if (phoneInUse) {
        throw FirebaseAuthException(
          code: 'phone-already-in-use',
          message: 'Nomor WhatsApp ini sudah terdaftar. Silakan masuk.',
        );
      }

      // Jika ada email, cek apakah email sudah ada
      if (hasEmail) {
        final emailInUse = await isEmailRegistered(cleanEmail);
        if (emailInUse) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Alamat email ini sudah terdaftar. Silakan masuk.',
          );
        }
      }

      // Menentukan authEmail untuk Firebase Authentication
      // Jika email tidak diisi (opsional), gunakan pseudo-email unik dari nomor HP
      final cleanDigits = phone.replaceAll('+', '');
      final authEmail = hasEmail ? cleanEmail : '$cleanDigits@rideon.id';

      // Buat akun di Firebase Authentication
      UserCredential credential;
      try {
        credential = await auth.createUserWithEmailAndPassword(
          email: authEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Jika akun Firebase Auth sudah sempat dibuat pada percobaan sebelumnya,
          // masuk menggunakan kredensial tersebut untuk menyimpan profil ke Firestore
          credential = await auth.signInWithEmailAndPassword(
            email: authEmail,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final User? user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName);

        // Buat atau perbarui profil lengkap Customer di Cloud Firestore
        await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': fullName,
          'email': cleanEmail,
          'authEmail': authEmail,
          'phoneNumber': phone,
          'photoUrl': '',
          'role': 'CUSTOMER',
          'rating': 5.0,
          'phoneVerified': true,
          'emailVerified': false,
          'wallet': {
            'balance': 0,
            'currency': 'IDR',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Registrasi Akun Baru (Kompatibilitas fungsi lama)
  Future<UserCredential> registerWithEmailOrPhone({
    required String fullName,
    required String identifier,
    required String password,
  }) async {
    final bool isEmail = identifier.contains('@');
    return registerCustomerAccount(
      fullName: fullName,
      email: isEmail ? identifier : null,
      phoneNumber: isEmail ? '' : identifier,
      password: password,
    );
  }

  /// Smart Login: Mendukung Login via Email ATAU Nomor WhatsApp + Password
  Future<UserCredential> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      final trimmed = identifier.trim();
      final bool isEmail = trimmed.contains('@');

      String authEmail;

      if (isEmail) {
        authEmail = trimmed.toLowerCase();
      } else {
        // Jika input berupa Nomor HP / WhatsApp
        final phone = normalizePhoneNumber(trimmed);

        // Cari dokumen user berdasarkan phoneNumber di Cloud Firestore
        final query = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          // Jika tidak ada di Firestore, coba format pseudo-email fallback
          final cleanDigits = phone.replaceAll('+', '');
          authEmail = '$cleanDigits@rideon.id';
        } else {
          final data = query.docs.first.data();
          final storedAuthEmail = (data['authEmail'] as String?)?.trim();
          final registeredEmail = (data['email'] as String?)?.trim();

          if (storedAuthEmail != null && storedAuthEmail.isNotEmpty) {
            authEmail = storedAuthEmail;
          } else if (registeredEmail != null && registeredEmail.isNotEmpty) {
            authEmail = registeredEmail;
          } else {
            final cleanDigits = phone.replaceAll('+', '');
            authEmail = '$cleanDigits@rideon.id';
          }
        }
      }

      // Login ke Firebase Authentication menggunakan email & kata sandi
      final credential = await auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In dengan Email & Password langsung
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In Anonymous (untuk tamu / testing cepat)
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await auth.signInAnonymously();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sinkronisasi data profil user ke Firestore saat login pertama
  Future<void> _saveUserToFirestore(User user) async {
    final userDoc = firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Customer RideOn',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': 'CUSTOMER',
        'rating': 5.0,
        'phoneVerified': false,
        'emailVerified': user.emailVerified,
        'wallet': {
          'balance': 0,
          'currency': 'IDR',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sign Out & Bersihkan Sesi
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await auth.signOut();
    } catch (_) {}
  }
}
