import 'package:firebase_auth/firebase_auth.dart';

/// Logika & state management untuk Header Banner Beranda.
/// Memisahkan dependency ke Firebase Auth & event handling dari widget tampilan.
class HeaderBannerLogic {
  /// Mengambil photoURL user yang sedang login jika tersedia.
  static String? resolvePhotoUrl({String? explicitUrl}) {
    if (explicitUrl != null && explicitUrl.isNotEmpty) return explicitUrl;
    try {
      return FirebaseAuth.instance.currentUser?.photoURL;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil display name user yang sedang login jika tersedia.
  static String? resolveUserName({String? explicitName}) {
    if (explicitName != null && explicitName.isNotEmpty) return explicitName;
    try {
      return FirebaseAuth.instance.currentUser?.displayName;
    } catch (_) {
      return null;
    }
  }

  /// Memeriksa apakah user sedang login ke aplikasi.
  static bool checkIsLoggedIn({bool? explicitStatus}) {
    if (explicitStatus != null) return explicitStatus;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }
}

