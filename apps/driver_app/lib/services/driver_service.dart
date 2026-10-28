import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service untuk menangani Autentikasi dan Tracking Driver
class DriverService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentDriver => _auth.currentUser;

  /// Sign In Google untuk Driver
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveDriverProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In Email & Password Driver
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

  /// Update Lokasi GPS Driver ke Realtime Database (Radar Driver)
  Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
    required double heading,
    required bool isOnline,
    required String serviceType, // 'FLEXRIDE', 'FLEXFOOD', 'FLEXSEND'
  }) async {
    final driver = currentDriver;
    if (driver == null) return;

    final locationRef = _rtdb.ref('driver_locations/${driver.uid}');
    await locationRef.set({
      'driverId': driver.uid,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'isOnline': isOnline,
      'serviceType': serviceType,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Set Status Online / Offline Driver
  Future<void> setDriverPresence(bool isOnline) async {
    final driver = currentDriver;
    if (driver == null) return;

    final presenceRef = _rtdb.ref('driver_presence/${driver.uid}');
    await presenceRef.set({
      'isOnline': isOnline,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Simpan / Inisialisasi Profil Driver di Firestore
  Future<void> _saveDriverProfile(User user) async {
    final driverDoc = _firestore.collection('drivers').doc(user.uid);
    final snapshot = await driverDoc.get();

    if (!snapshot.exists) {
      await driverDoc.set({
        'driverId': user.uid,
        'name': user.displayName ?? 'Mitra Driver',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': 'DRIVER',
        'status': 'PENDING_VERIFICATION', // Butuh verifikasi KTP/SIM
        'rating': 5.0,
        'wallet': {
          'balance': 0,
          'currency': 'IDR',
        },
        'level': 'BRONZE',
        'levelPoints': 0,
        'stats': {
          'totalTrips': 0,
          'totalEarnings': 0,
          'todayTrips': 0,
          'todayEarnings': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await driverDoc.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    if (currentDriver != null) {
      await setDriverPresence(false);
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
