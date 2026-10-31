# Customer App - Task & Implementation Checklist

Dokumen ini adalah acuan kerja khusus (**Single Source of Truth**) untuk pengembangan fitur pada **Customer App (`apps/customer_app`)**. Rekan tim lain tidak terpengaruh oleh task di dokumen ini karena dokumen ini fokus pada ruang lingkup modul Customer.

---

## 🎯 Fokus Saat Ini: Modul Autentikasi & Manajemen Pengguna (Fase 1)

Status terkini: **Google Sign-In sudah terhubung dan berhasil membuat dokumen user pertama di Cloud Firestore.**

---

## 📋 Checklist Pekerjaan Bertahap

### 1. Backend Service: Autentikasi Fleksibel (`AuthService.dart`)
- [x] **1.1. Inisialisasi Firebase & Google Sign-In**
  - Berhasil login via pop-up akun Google native Android.
  - Auto-create profil di Firestore `/users/{uid}` dengan field `role: "CUSTOMER"`, `rating: 5.0`, dan dompet saldo 0 IDR.
- [x] **1.2. Implementasi Registrasi Akun Baru (`registerWithEmailOrPhone`)**
  - Membuat akun di Firebase Authentication.
  - Menyimpan data form registrasi (Nama Lengkap, No. WhatsApp/Email, Kata Sandi) ke dokumen Firestore `/users/{uid}`.
- [x] **1.3. Implementasi Smart Detector Login (`signInWithIdentifier`)**
  - Deteksi otomatis apakah input berupa format Email (mengandung `@`) atau Nomor WhatsApp (angka).
  - Jika Nomor WhatsApp: lakukan query lookup ke Firestore mencari dokumen user dengan `phoneNumber == input`, lalu proses kredensialnya.
- [x] **1.4. Fungsi Sign Out & Pembersihan Sesi**
  - Membersihkan sesi Firebase Auth dan Google Sign-In saat user logout.

---

### 2. Antarmuka Pengguna (UI Integration)

#### A. Halaman Pendaftaran (`register_screen.dart`)
- [x] **2.1. Validasi Input Form Sesuai Desain Figma**
  - Nama Lengkap (minimal 3 karakter).
  - No. WhatsApp / Email valid.
  - Kata Sandi minimal 8 karakter & Konfirmasi Sandi cocok.
  - Checkbox Syarat & Ketentuan dicentang.
- [x] **2.2. Loading State & Error Handling**
  - Tampilkan indikator loading saat tombol ditekan.
  - Tampilkan banner error jika email/nomor sudah terdaftar sebelumnya (`email-already-in-use`).
- [x] **2.3. Dialog Berhasil Daftar (Figma Pop-up)**
  - Tampilkan dialog sukses frosted glass setelah registrasi berhasil.
  - Tombol pada dialog mengarahkan pengguna kembali ke halaman Login.

#### B. Halaman Masuk (`login_screen.dart`)
- [x] **2.4. Tombol Google Login Aktif**
  - Memanggil `_handleGoogleLogin()` dengan proteksi loading state.
- [x] **2.5. Tombol MASUK (Email / No. WhatsApp + Password)**
  - Mengambil input dari controller `_identifierController` & `_passwordController`.
  - Memanggil `_authService.signInWithIdentifier()`.
  - Menampilkan banner error merah sesuai Figma jika kredensial salah.
  - Pindah ke `MainScreen()` saat sukses.

---

### 3. Sesi & Alur Navigasi Aplikasi (`main.dart` & `splash_screen.dart`)
- [x] **3.1. Auto Login (Session Persistence)**
  - Setelah animasi Splash Screen selesai, periksa `FirebaseAuth.instance.currentUser`.
  - Jika **sudah login**: langsung arahkan ke `MainScreen()`.
  - Jika **belum login**: arahkan ke `LoginScreen()`.

---

## 🗺️ Roadmap Fitur Customer App Berikutnya

1. **Sinkronisasi Beranda**: Menampilkan nama user, foto profil, dan stream saldo dompet Firestore di AppBar Beranda.
2. **Peta & Radar Driver (FlexRide)**: Menampilkan posisi real-time armada driver dari Firebase Realtime Database.
3. **Katalog Makanan (FlexFood)**: Menampilkan menu makanan dari koleksi toko di Firestore.
4. **Order Dispatching**: Alur pembuatan order FlexRide, FlexFood, dan FlexSend.

