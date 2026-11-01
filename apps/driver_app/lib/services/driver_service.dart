import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service untuk menangani Autentikasi dan Tracking Driver
class DriverService {
  final FirebaseAuth? _authInstance;
  final FirebaseFirestore? _firestoreInstance;
  final FirebaseDatabase? _rtdbInstance;
  final GoogleSignIn? _googleSignInInstance;

  DriverService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? rtdb,
    GoogleSignIn? googleSignIn,
  })  : _authInstance = auth,
        _firestoreInstance = firestore,
        _rtdbInstance = rtdb,
        _googleSignInInstance = googleSignIn;

  FirebaseAuth? get _auth {
    if (_authInstance != null) return _authInstance;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseDatabase? get _rtdb {
    if (_rtdbInstance != null) return _rtdbInstance;
    try {
      return FirebaseDatabase.instance;
    } catch (_) {
      return null;
    }
  }

  GoogleSignIn get _googleSignIn => _googleSignInInstance ?? GoogleSignIn();

  User? get currentDriver => _auth?.currentUser;

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

      final auth = _auth;
      if (auth == null) return null;

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

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
      final auth = _auth;
      if (auth == null) {
        throw StateError('Firebase Auth is not initialized');
      }
      final credential = await auth.signInWithEmailAndPassword(
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
    String? driverId,
  }) async {
    try {
      final uid = driverId ?? currentDriver?.uid;
      final rtdb = _rtdb;
      if (uid == null || rtdb == null) return;

      final locationRef = rtdb.ref('driver_locations/$uid');
      await locationRef.set({
        'driverId': uid,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'isOnline': isOnline,
        'serviceType': serviceType,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (_) {
      // Graceful error handling for offline/mock environments
    }
  }

  /// Set Status Online / Offline Driver
  Future<void> setDriverPresence(bool isOnline, {String? driverId}) async {
    try {
      final uid = driverId ?? currentDriver?.uid;
      final rtdb = _rtdb;
      if (uid == null || rtdb == null) return;

      final presenceRef = rtdb.ref('driver_presence/$uid');
      await presenceRef.set({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (_) {
      // Graceful error handling for offline/mock environments
    }
  }

  /// Simpan / Inisialisasi Profil Driver di Firestore
  Future<void> _saveDriverProfile(User user) async {
    final firestore = _firestore;
    if (firestore == null) return;

    final driverDoc = firestore.collection('drivers').doc(user.uid);
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
    try {
      if (currentDriver != null) {
        await setDriverPresence(false);
      }
      if (_googleSignInInstance != null || currentDriver != null) {
        await _googleSignIn.signOut();
      }
      await _auth?.signOut();
    } catch (_) {
      // Graceful error handling for test/offline environments
    }
  }
}
