import '../../../data/auth_service.dart';

/// State, controllers, validasi, dan logika signIn untuk halaman Login.
///
/// Digunakan oleh [_LoginScreenState] sebagai controller terpisah.
/// Tidak meng-extend State agar mudah diuji secara unit.
class LoginLogic {
  final AuthService authService = AuthService();
}

