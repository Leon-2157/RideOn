import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service untuk menangani Autentikasi Firebase pada Customer App
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Mendapatkan user yang sedang aktif
  User? get currentUser => _auth.currentUser;

  /// Stream status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign In dengan Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger alur otentikasi Google di Android
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User membatalkan dialog login
        return null;
      }

      // Ambil detail otentikasi
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Buat kredensial Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign-in ke Firebase dengan kredensial Google
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Simpan / update data user ke Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In dengan Email & Password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
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
      final credential = await _auth.signInAnonymously();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sinkronisasi data profil user ke Firestore
  Future<void> _saveUserToFirestore(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // Data pertama kali login (registrasi otomatis)
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Customer RideOn',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': 'CUSTOMER',
        'rating': 5.0,
        'wallet': {
          'balance': 0,
          'currency': 'IDR',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Update waktu login terakhir
      await userDoc.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
