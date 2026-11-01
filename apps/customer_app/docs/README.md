# DOKUMENTASI CUSTOMER APP

Panduan master lengkap yang merangkum arsitektur, alur pendaftaran, login, pengaturan akun, dan seluruh integrasi layanan (WhatsApp Gateway, OpenStreetMap, Firebase SMS, Firebase Email, Firestore, GPS) dapat diakses pada dokumen utama:

👉 [**docs/12-customer-app-master-guide-auth-settings-and-services.md**](../../../docs/12-customer-app-master-guide-auth-settings-and-services.md)

---

### Ringkasan Cepat Struktur Modul (`apps/customer_app/lib/`):
- `core/`: Utilitas sentral (`phone_number_formatter.dart`, `country_code.dart`, `app_colors.dart`, `user_avatar.dart`).
- `features/auth/`:
  - `data/auth_service.dart`: Kredensial Firebase, Google Sign-In, Phone SMS.
  - `data/wa_gateway_service.dart`: Integrasi WhatsApp OTP 6 digit.
  - `presentation/pages/`: `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`.
  - `presentation/widgets/`: Komponen form, dialog, modal S&K, dan tombol Google.
- `features/pengaturan/`:
  - `presentation/pages/`: `pengaturan_akun_screen.dart`, `lokasi_anda_screen.dart`, `ubah_profil_screen.dart`, `nomor_wa_screen.dart`, `alamat_email_screen.dart`, `keamanan_akun_screen.dart`, `kebijakan_privasi_screen.dart`.
  - `presentation/widgets/`: `profil_header_card.dart`, `menu_item_tile.dart`, `tombol_keluar_akun.dart`, `email_verification_dialog.dart`, `sub_header_widget.dart`, `crop_frame_painter.dart`.

