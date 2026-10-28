# RideOn - Log Riwayat Pekerjaan & Panduan Serah Terima (Handover)

Dokumen ini mencatat seluruh riwayat konfigurasi, perubahan struktur kode, dan integrasi backend yang telah diselesaikan pada proyek **RideOn**. Dokumen ini dirancang sebagai panduan serah terima (*handover*) agar rekan satu tim yang memegang modul **Driver App** dan **Page Toko** dapat langsung melanjutkan pekerjaan tanpa kebingungan.

---

## 👥 Pembagian Tugas & Kepemilikan Modul

- **Customer App**: Dipegang oleh **Leon**
- **Driver App**: Rekan Tim Driver
- **Page Toko (Merchant)**: Rekan Tim Toko

---

## 📌 Ringkasan Status Global (Yang Sudah Dikerjakan Bersama)

1. **Akun & Project Firebase Tunggal**:
   - Project ID: `rideon-9eb77` (Project Name: **RideOn**).
   - Ketiga aplikasi berbagi 1 project Firebase yang sama agar database saling terhubung secara instan.
2. **Region Database**:
   - **Cloud Firestore**: Mode Produksi (`asia-southeast2` / Jakarta).
   - **Realtime Database**: Singapore (`asia-southeast1`) untuk lokasi GPS radar driver & chat.
3. **Penyelarasan Namespace Android**:
   - Diubah dari format default template `com.example.*` menjadi domain resmi:
     - Customer: `com.rideon.customer`
     - Driver: `com.rideon.driver`
     - Toko: `com.rideon.page_toko`
4. **Kredensial SHA-1 & Google Sign-In**:
   - SHA-1 debug laptop pengembang telah didaftarkan ke Firebase Console untuk ketiga aplikasi.
   - File `google-services.json` terbaru (122 baris) sudah menyertakan ketiga aplikasi + OAuth client Google Sign-In.
5. **Keamanan & Manajemen Rahasia (.gitignore & .env)**:
   - Root `.gitignore` telah diperbarui dengan standar industri: mengabaikan file `.env`, file fisik `google-services.json`, `local.properties`, dan file keystore Android.
   - File template `.env.example` telah dibuat di root dan di masing-masing folder aplikasi.
   - File template `google-services.json.example` telah disediakan di root sebagai acuan struktur.

---

## 📱 1. Customer App (`apps/customer_app`) - Leon

### Yang Telah Diselesaikan:
- [x] **Namespace & App ID**: Diubah menjadi `com.rideon.customer` di `android/app/build.gradle.kts`.
- [x] **Struktur Kotlin**: Memindahkan `MainActivity.kt` ke folder `android/app/src/main/kotlin/com/rideon/customer/MainActivity.kt` (`package com.rideon.customer`).
- [x] **File Konfigurasi**: Memasang `apps/customer_app/android/app/google-services.json`.
- [x] **Gradle Plugin**: Memasang `id("com.google.gms.google-services")` di `settings.gradle.kts` dan `app/build.gradle.kts`.
- [x] **Dependencies (`pubspec.yaml`)**:
  - `firebase_core: ^3.12.1`
  - `firebase_auth: ^5.5.1`
  - `google_sign_in: ^6.2.2`
  - `cloud_firestore: ^5.6.5`
  - `firebase_database: ^11.3.1`
  - `firebase_storage: ^12.4.4`
  - `firebase_messaging: ^15.2.4`
- [x] **Inisialisasi `main.dart`**: Menambahkan `WidgetsFlutterBinding.ensureInitialized()` dan `await Firebase.initializeApp()`.
- [x] **AuthService**: Dibuatkan file `lib/features/auth/data/auth_service.dart` (Google Sign-In, Email/Password, dan auto-create profil Firestore di `/users/{uid}`).
- [x] **UI Login**: Halaman `login_screen.dart` sudah terhubung langsung ke `AuthService`, tombol *Lanjutkan Dengan Google* aktif, tombol *MASUK* aktif dengan loading state.
- [x] **Pengujian**: Berhasil running lancar di perangkat fisik Android tanpa error.

---

## 🚗 2. Driver App (`apps/driver_app`) - Panduan untuk Tim Driver

### Yang Telah Diselesaikan untuk Driver:
- [x] **Pendaftaran di Firebase**: Aplikasi `com.rideon.driver` sudah resmi terdaftar di Firebase Console.
- [x] **Namespace & App ID**: Diubah menjadi `com.rideon.driver` di `apps/driver_app/android/app/build.gradle.kts`.
- [x] **Struktur Kotlin**: File `MainActivity.kt` sudah dipindahkan ke folder:
  `apps/driver_app/android/app/src/main/kotlin/com/rideon/driver/MainActivity.kt` (`package com.rideon.driver`).
- [x] **File Konfigurasi**: `apps/driver_app/android/app/google-services.json` sudah terpasang dengan konfigurasi terbaru.
- [x] **Gradle Plugin**: Plugin Google Services (`4.4.2`) sudah terpasang di `settings.gradle.kts` dan `build.gradle.kts`.
- [x] **Dependencies (`pubspec.yaml`)**: Sudah dipasangi paket Firebase lengkap (`firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `firebase_database`, dll.) dan sudah lolos `flutter pub get`.
- [x] **Inisialisasi `main.dart`**: Sudah dipasangi `WidgetsFlutterBinding.ensureInitialized()` & `await Firebase.initializeApp()`.
- [x] **Driver Service Template**: Dibuatkan file [`apps/driver_app/lib/services/driver_service.dart`](file:///home/leon/Documents/Project/RideOn/apps/driver_app/lib/services/driver_service.dart) yang sudah siap pakai dengan fungsi:
  - `signInWithGoogle()`
  - `signInWithEmailPassword()`
  - `updateDriverLocation(...)`: Kirim GPS koordinat ke Realtime Database node `/driver_locations/{driverId}`
  - `setDriverPresence(bool isOnline)`: Status online/offline di `/driver_presence/{driverId}`
  - `_saveDriverProfile(...)`: Inisialisasi profil driver di Firestore koleksi `/drivers/{driverId}`

### 🛠️ Tugas Selanjutnya yang Perlu Dikerjakan Tim Driver:
1. **Hubungkan Halaman Login Driver**:
   - Buka `apps/driver_app/lib/screens/splash_screen_login.dart`.
   - Sambungkan tombol login ke `DriverService.signInWithGoogle()` atau `signInWithEmailPassword()`.
2. **Koneksikan Toggle Online / Offline**:
   - Ketika driver menggeser tombol *"Online"*, panggil fungsi `DriverService.setDriverPresence(true)` dan aktifkan background GPS listener menggunakan `DriverService.updateDriverLocation()`.
3. **Form Pendaftaran Dokumen (KTP, SIM, STNK)**:
   - Sesuai alur di Figma (9 tahapan registrasi driver), upload foto dokumen ke Firebase Storage pada path `drivers/{driverId}/documents/`.

> **Catatan untuk Tim Driver jika run di laptop sendiri**:
> Jika Anda menjalankan aplikasi di laptop Anda sendiri dan tombol Google Sign-In error `10`, dapatkan SHA-1 laptop Anda lewat `./gradlew signingReport` dan tambahkan ke Firebase Console di bawah app `driver`.

---

## 🏪 3. Page Toko (`apps/page_toko`) - Panduan untuk Tim Toko

### Yang Telah Diselesaikan untuk Toko:
- [x] **Pendaftaran di Firebase**: Aplikasi `com.rideon.page_toko` sudah resmi terdaftar di Firebase Console.
- [x] **Namespace & App ID**: Diubah menjadi `com.rideon.page_toko` di `apps/page_toko/android/app/build.gradle.kts`.
- [x] **Struktur Kotlin**: File `MainActivity.kt` sudah dipindahkan ke folder:
  `apps/page_toko/android/app/src/main/kotlin/com/rideon/page_toko/MainActivity.kt` (`package com.rideon.page_toko`).
- [x] **File Konfigurasi**: `apps/page_toko/android/app/google-services.json` sudah ditaruh di `apps/page_toko/android/app/` dan berisi kredensial lengkap.
- [x] **Gradle Plugin**: Plugin Google Services (`4.4.2`) sudah terpasang di `settings.gradle.kts` dan `build.gradle.kts`.

### 🛠️ Tugas Selanjutnya yang Perlu Dikerjakan Tim Toko:
1. **Tambahkan Dependencies di `apps/page_toko/pubspec.yaml`**:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     cupertino_icons: ^1.0.8
     # Firebase Core & Services
     firebase_core: ^3.12.1
     firebase_auth: ^5.5.1
     google_sign_in: ^6.2.2
     cloud_firestore: ^5.6.5
     firebase_storage: ^12.4.4
     firebase_messaging: ^15.2.4
   ```
2. **Jalankan `flutter pub get`** di folder `apps/page_toko`.
3. **Inisialisasi Firebase di `apps/page_toko/lib/main.dart`**:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(const MyApp());
   }
   ```
4. **Buat Service Toko (`store_service.dart`)**:
   - Login pemilik toko (Auth UID = Store ID).
   - Simpan data profil toko ke Firestore `/stores/{storeId}`.
   - Buat fungsi CRUD untuk katalog menu makanan di sub-koleksi `/stores/{storeId}/menus/{menuId}`.
   - Pasang listener realtime Firestore pada koleksi `/orders` di mana `storeId == auth.uid` dan status `PLACED` untuk menampilkan pop-up pesanan masuk.

---

## 🗄️ Dokumen Referensi Desain & Database

Seluruh detail teknis yang telah dirancang dapat dibaca oleh rekan tim di folder `docs/`:
- **[01-system-architecture.md](file:///home/leon/Documents/Project/RideOn/docs/01-system-architecture.md)**: Analisis seluruh desain Figma, diagram interaksi antar-aplikasi (FlexRide, FlexFood, FlexSend), dan arsitektur sistem.
- **[02-database-design.md](file:///home/leon/Documents/Project/RideOn/docs/02-database-design.md)**: Skema 20 koleksi Firestore, Realtime Database, struktur folder Cloud Storage, Security Rules, dan Cloud Functions.
- **[03-firebase-library-checklist.md](file:///home/leon/Documents/Project/RideOn/docs/03-firebase-library-checklist.md)**: Checklist pengerjaan library dan pengujian.
- **[04-authentication-guide.md](file:///home/leon/Documents/Project/RideOn/docs/04-authentication-guide.md)**: Panduan detail mekanisme login Google, Email, dan sinkronisasi profil user.
