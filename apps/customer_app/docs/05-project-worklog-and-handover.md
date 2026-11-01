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
- [x] **UI Login & Register**: Halaman `login_screen.dart`, `register_screen.dart`, dan `forgot_password_screen.dart` terhubung ke WhatsApp Gateway OTP (Baileys), SMS Firebase Fallback, dan modal Syarat & Ketentuan.
- [x] **Clean Architecture Pengaturan Akun**: Berhasil memecah file monolitik 4.419 baris menjadi 8 sub-layar mandiri di `features/pengaturan/presentation/pages/` dan 7 widget modular di `widgets/`.
- [x] **Peta & GPS Lokasi Anda**: Peta interaktif OpenStreetMap (zero-cost `flutter_map`), integrasi sensor GPS perangkat (`geolocator`), dan auto reverse-geocoding (`geocoding`).
- [x] **Auto-Polling Email Verification**: Dialog modal pemantau verifikasi email otomatis setiap 3 detik tanpa perlu login ulang.
- [x] **Sentralisasi `core/`**: Model `CountryCode` dan `PhoneNumberFormatter` disatukan agar tidak ada duplikasi kode.
- [x] **Dokumentasi Lengkap (SSOT)**: Tersedia di [docs/12-customer-app-master-guide-auth-settings-and-services.md](12-customer-app-master-guide-auth-settings-and-services.md).
- [x] **Pengujian & Verifikasi**: 44/44 Widget & Unit Tests lolos 100%, `flutter analyze` 0 issues.

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

## 🚀 SOP Setup Rekan Tim Setelah Git Pull (Wajib Dibaca)

Karena file rahasia (`google-services.json` dan `.env`) sengaja dikecualikan dari Git demi keamanan, rekan tim yang baru saja melakukan `git pull` wajib mengikuti 3 langkah ini agar aplikasi tidak error saat di-build:

### 1. Meminta & Meletakkan File `google-services.json`
Minta file `google-services.json` resmi ke **Leon** (Project Admin), lalu letakkan sesuai aplikasi yang Anda kerjakan:
- **Tim Driver**: Letakkan di `apps/driver_app/android/app/google-services.json`
- **Tim Toko**: Letakkan di `apps/page_toko/android/app/google-services.json`
- **Customer**: Letakkan di `apps/customer_app/android/app/google-services.json`

### 2. Membuat File `.env` Lokal
Salin template environment yang sudah disediakan:
```bash
# Jika Anda mengerjakan Driver App:
cp apps/driver_app/.env.example apps/driver_app/.env

# Jika Anda mengerjakan Page Toko:
cp apps/page_toko/.env.example apps/page_toko/.env
```

### 3. Mendaftarkan SHA-1 & SHA-256 Laptop Sendiri (Khusus Google Sign-In)
Agar tombol Google Login tidak error (code 10) saat dijalankan di laptop atau HP masing-masing developer:

1. **Jalankan `flutter pub get` terlebih dahulu** (Wajib agar file `local.properties` terbentuk):
   - Masuk ke folder aplikasi yang Anda kerjakan, contoh:
     ```powershell
     cd apps/page_toko      # atau cd apps/driver_app
     flutter pub get
     ```

2. **Jalankan signingReport**:
   - **Untuk Windows (PowerShell)**:
     ```powershell
     cd android
     .\gradlew.bat signingReport
     ```
   - **Untuk Windows (CMD)**:
     ```cmd
     cd android
     gradlew signingReport
     ```
   - **Untuk Linux / macOS**:
     ```bash
     cd android && ./gradlew signingReport
     ```

3. **Nilai yang Wajib Disalin**:
   Cari blok `Variant: debug` dan salin dua baris ini:
   - **SHA1**: contoh `2C:A9:51:4F:B0:FE:41:57:94:B1:68:F9:5B:85:E6:ED:A2:81:71:7A`
   - **SHA-256**: contoh `ED:52:D5:B9:C3:EB:19:B2:0A:4B:A8:67:38:A0:44:31:81:20:97:51:FF:C9:84:5A:87:AA:7A:2F:96:34:54:0C`

4. **Kirimkan ke Leon (Project Admin)**:
   Kirimkan nilai SHA1 & SHA-256 di atas bersama nama aplikasinya (Driver / Toko).
   Leon akan mendaftarkannya di **Firebase Console > Project Settings > Your Apps > Add Fingerprint**.
   Setelah didaftarkan oleh Leon, minta file `google-services.json` yang baru lalu ganti di folder `android/app/`.

---

## 🗄️ Dokumen Referensi Desain & Database

Seluruh detail teknis yang telah dirancang dapat dibaca oleh rekan tim di folder `docs/`:
- **[01-system-architecture.md](file:///home/leon/Documents/Project/RideOn/docs/01-system-architecture.md)**: Analisis seluruh desain Figma, diagram interaksi antar-aplikasi (FlexRide, FlexFood, FlexSend), dan arsitektur sistem.
- **[02-database-design.md](file:///home/leon/Documents/Project/RideOn/docs/02-database-design.md)**: Skema 20 koleksi Firestore, Realtime Database, struktur folder Cloud Storage, Security Rules, dan Cloud Functions.
- **[03-firebase-library-checklist.md](file:///home/leon/Documents/Project/RideOn/docs/03-firebase-library-checklist.md)**: Checklist pengerjaan library dan pengujian.
- **[04-authentication-guide.md](file:///home/leon/Documents/Project/RideOn/docs/04-authentication-guide.md)**: Panduan detail mekanisme login Google, Email, dan sinkronisasi profil user.
- **[05-project-worklog-and-handover.md](file:///home/leon/Documents/Project/RideOn/docs/05-project-worklog-and-handover.md)**: Panduan serah terima tim dan SOP setup local environment setelah git pull.
- **[06-auth-registration-otp-revision.md](file:///home/leon/Documents/Project/RideOn/docs/06-auth-registration-otp-revision.md)**: Dokumen spesifikasi revisi desain UI/UX untuk alur input Email & verifikasi OTP WhatsApp pendaftaran akun baru.
- **[07-whatsapp-gateway-and-otp-architecture.md](file:///home/leon/Documents/Project/RideOn/docs/07-whatsapp-gateway-and-otp-architecture.md)**: Dokumen arsitektur WhatsApp Gateway terpusat di root monorepo, rate limit 60s cooldown, dan smart fallback ke Firebase Phone Auth SMS.
- **[08-firebase-phone-auth-sms-setup.md](file:///home/leon/Documents/Project/RideOn/docs/08-firebase-phone-auth-sms-setup.md)**: Panduan konfigurasi Firebase Phone Auth, SMS Region Policy Indonesia (+62), SHA-256 fingerprint, dan nomor testing.
- **[09-profile-photo-storage-and-oracle-cloud-migration.md](file:///home/leon/Documents/Project/RideOn/docs/09-profile-photo-storage-and-oracle-cloud-migration.md)**: Panduan penyimpanan foto profil (Solusi A: Base64 Firestore 100% gratis) dan panduan migrasi masa depan ke Oracle Cloud (Solusi C).
- **[10-auth-security-and-password-management.md](file:///home/leon/Documents/Project/RideOn/docs/10-auth-security-and-password-management.md)**: Panduan verifikasi email resmi Google Firebase, keamanan akun (ganti sandi), revamp menyeluruh lupa kata sandi, dan analisis autentikasi Smart Login.

---

## 📅 Catatan Sesi 30 Oktober 2026

### 1. Perbaikan Layar Atur Posisi Foto (`AturPosisiFotoScreen` - Figma [1:8904])
- **Eliminasi Batas Hitam Kamera:** Mengganti mode tampilan foto dari `BoxFit.contain` ke kalkulasi aspect ratio dinamis dengan `BoxFit.cover` dan batas skala minimal `minScale: 1.0`. Foto kamera vertikal (rasio 4:3 / 16:9) otomatis terisi penuh pada container bujur sangkar tanpa letterboxing hitam di samping.
- **Masker Panduan Lingkaran Profil (`CropFramePainter`):** Menggabungkan 4 sudut siku-siku Figma `[ ]` dengan masker lingkaran (circular cutout mask). Area di luar lingkaran avatar diredupkan transparan 55%, dan lingkaran avatar diberi garis lingkar putih halus 1.5px. Pengguna dapat memperkirakan posisi dahi, wajah, dan rambut secara presisi 100% sebelum disimpan.
- **Resolusi Avatar Tajam & Ringan:** Pemotongan (crop) dibatasi pada resolusi retina 512x512 piksel (< 35 KB) yang disimpan ke Firestore dan cache lokal perangkat.

### 2. Implementasi Alur Ganti Nomor WhatsApp (`NomorWaScreen`)
- **Struktur Form 3 Kolom & Keamanan Ganda:**
  1. *Konfirmasi Kata Sandi Akun:* Dilengkapi ikon gembok dan tombol mata (*eye toggle*) untuk melihat/sembunyikan kata sandi. Divalidasi nyata ke Firebase Auth via `reauthenticateWithCredential`.
  2. *Nomor WhatsApp Lama:* Input manual nomor lama pengguna saat ini, dilengkapi tombol pemilih bendera/kode negara (default: 🇮🇩 +62) dan auto-spasi. Divalidasi harus cocok 100% dengan nomor akun yang terdaftar di database.
  3. *Nomor WhatsApp Baru:* Input nomor tujuan baru, dilengkapi pemilih bendera/kode negara dan auto-spasi. Divalidasi tidak boleh sama dengan nomor lama dan tidak boleh sudah terdaftar pada pengguna lain di Cloud Firestore.
- **Komponen Selector Bendera & Auto-Spasi:** Menggunakan model `CountryCode` (12 negara didukung) dan `PhoneNumberFormatter` yang otomatis membuang angka `0` di awal nomor serta memisahkan nomor per 4 digit (`853 2344 1080`).
- **Pengiriman Kode OTP WhatsApp:** Mengirimkan 6 digit kode OTP verifikasi ke nomor baru via layanan `WaGatewayService` (lengkap dengan simulasi SnackBar).
- **Verifikasi 6 Digit OTP:** Form 6 kotak digit OTP dengan auto-advance, hitung mundur 60 detik, tombol kirim ulang, dan tombol ubah nomor.
- **Penyimpanan Permanen ke Firestore:** Setelah OTP terverifikasi, nomor diperbarui secara permanen di Cloud Firestore path `/users/{uid}` field `phoneNumber`, status `phoneVerified: true`, dan sinkronisasi `authEmail` untuk Smart Login.

### 3. Implementasi Dinamis Layar Alamat Email (`AlamatEmailScreen` - Tautan Resmi Gmail)
- **Konsep Dinamis 2 Kolom vs 3 Kolom:**
  - *Jika belum ada email sebelumnya:* Menampilkan form **2 kolom** (Konfirmasi Kata Sandi Akun dengan tombol mata *eye toggle* & Alamat Email Aktif). Teks kartu atas mengarahkan pengguna menghubungkan email untuk e-receipt.
  - *Jika sudah pernah ada email terdaftar:* Menampilkan form **3 kolom** (Konfirmasi Kata Sandi Akun dengan *eye toggle*, Alamat Email Lama yang dicocokkan dengan akun saat ini, dan Alamat Email Baru).
- **Validasi Keamanan & Cek Duplikasi:** Kata sandi akun diverifikasi nyata ke Firebase Auth via `reauthenticateWithCredential`, dan format email divalidasi serta diperiksa apakah sudah terdaftar pada pengguna lain via `AuthService.isEmailRegistered`.
- **Transisi Verifikasi ke Tautan Resmi Google Firebase (`verifyBeforeUpdateEmail`):**
  - Menggantikan alur OTP WhatsApp sebelumnya dengan tautan verifikasi resmi yang dikirimkan Google Firebase langsung ke kotak masuk Gmail pengguna.
  - Dilengkapi dialog pemantauan `EmailVerificationDialog` dengan timer reload background dan tombol aksi manual **`SAYA SUDAH VERIFIKASI DI GMAIL`**.
  - **Prinsip Keamanan Integritas Data (Zero Premature Firestore Write):** Database Cloud Firestore **SAMA SEKALI TIDAK DITULIS** sebelum tautan email berhasil diklik dan diverifikasi di Google Firebase Auth.
  - Setelah verifikasi sukses, Firestore di-update dengan field `email`, `emailVerified: true`, `authEmail: newEmail`, dan `updatedAt: serverTimestamp()`.
- **Tampilan Dinamis di Pengaturan Akun:** Jika belum ada email atau status `emailVerified == false`, menu menampilkan `• Belum ditambahkan` dan badge `+Tambahkan`. Jika sudah tersimpan dan terverifikasi, teks menampilkan email (misal `• peter@gmail.com`) dan badge `Aktif`. Dilengkapi dialog sukses *"Alamat Email Berhasil Disimpan!"*.

### 4. Implementasi Fitur Keamanan Akun & Pengubahan Kata Sandi (`KeamananAkunScreen`)
- **Struktur Form 3 Kolom Sesuai Figma:**
  1. *Kata Sandi Saat Ini:* Input sandi lama dengan tombol mata (*eye toggle*), divalidasi langsung ke Firebase Auth via `reauthenticateWithCredential`.
  2. *Kata Sandi Baru:* Input sandi baru dengan *eye toggle* (minimal 8 karakter, dilarang sama dengan sandi lama).
  3. *Konfirmasi Sandi Baru:* Input konfirmasi dengan *eye toggle* (divalidasi harus cocok persis dengan sandi baru).
- **Banner Peringatan Galat Interaktif:** Menampilkan pesan galat merah jelas jika kata sandi salah, dan otomatis dibersihkan saat pengguna mulai mengetik kembali.
- **Tautan Lupa Sandi:** Menyediakan link *"Lupa kata sandi?"* yang langsung membuka `ForgotPasswordScreen`.
- **Penyelesaian Berhasil:** Memanggil `user.updatePassword(newPassword)` dan menampilkan dialog modal sukses Figma *"Berhasil Diubah!"*.

### 5. Revamp Total Layar Lupa Kata Sandi (`ForgotPasswordScreen`)
- **Eliminasi Mockup/Prototype Statis Lama:** Menghapus seluruh hardcode dummy OTP (`_otpControllers[0].text = '1' ... '6'`) dan judul statis WhatsApp.
- **Dual Identifier Routing (Deteksi Cerdas Input):**
  - *Jika Input adalah Email:* Tombol otomatis berlabel **`KIRIM TAUTAN RESET KE EMAIL`**, memanggil `FirebaseAuth.instance.sendPasswordResetEmail(email)`, dan memunculkan pop-up dialog sukses berisi panduan memeriksa Kotak Masuk / folder Spam di Gmail.
  - *Jika Input adalah Nomor WhatsApp:* Tombol berlabel **`KIRIM KODE OTP`**, memeriksa pendaftaran nomor di Firestore, mengirimkan OTP 6-digit nyata via `WaGatewayService`, menampilkan 6 kotak OTP kosong dengan navigasi auto-advance/backspace, hitung mundur 60 detik, dan tombol kirim ulang.
- **Integrasi Backend WhatsApp Gateway:** Ditambahkan endpoint `POST /api/auth/reset-password` di `services/wa-gateway` berbasis Firebase Admin SDK, dilengkapi fallback otomatis pengiriman link reset jika server belum terpasang service account.

### 6. Investigasi Masalah Autentikasi & Analisis Smart Login
- **Akar Masalah Kegagalan Login & Ganti Sandi:** Ditemukan saltik (typo) urutan karakter pada kata sandi yang diketik pengguna di HP (`Qwead@07` dan `Qwesad@07` vs kata sandi asli `Qweasd@07`).
- **Pembuktian Uji API Firebase:**
  - `Qwesad@07` $\rightarrow$ `400 INVALID_LOGIN_CREDENTIALS` (Ditolak).
  - `Qweasd@07` $\rightarrow$ `200 OK` (Berhasil).
- **Validitas Smart Login:** Terbukti bahwa format input `08xx`, `+62xx`, maupun Email semuanya bekerja 100% normal dan berhasil dipetakan ke dokumen Firestore akun pengguna.

### 7. Hasil Pengujian Otomatis & Standar Kualitas
- **Pengujian Widget (`flutter test`):**
  - `test/pengaturan_akun_test.dart`: **26/26 Tests Passed** (100% Lolos).
  - `test/login_screen_test.dart`: **6/6 Tests Passed** (100% Lolos).
- **Analisis Statis (`flutter analyze`):** **0 Issues Found** (Bersih dari error, warning, dan linter lint).
