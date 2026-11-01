# DOKUMENTASI MASTER CUSTOMER APP: AUTH, PENGATURAN AKUN, & INTEGRASI SERVICES

Dokumentasi ini adalah **Single Source of Truth (SSOT)** lengkap untuk seluruh fitur **Autentikasi (Login, Register, Lupa Sandi)**, **Pengaturan Akun**, serta seluruh **Layanan Pihak Ketiga (Services & Third-Party Integrations)** yang diimplementasikan pada aplikasi `customer_app` di RideOn.

---

## DAFTAR ISI
1. [Arsitektur Kode & Struktur Direktori](#1-arsitektur-kode--struktur-direktori)
2. [Peta Layanan & Third-Party Integrations (Apa, Mengapa, dan Di Mana?)](#2-peta-layanan--third-party-integrations)
   - [A. WhatsApp Gateway (Baileys Microservice)](#a-whatsapp-gateway-baileys-microservice)
   - [B. SMS Firebase Phone Authentication](#b-sms-firebase-phone-authentication)
   - [C. Firebase Email Verification & Authentication](#c-firebase-email-verification--authentication)
   - [D. OpenStreetMap (flutter_map & latlong2)](#d-openstreetmap-flutter_map--latlong2)
   - [E. GPS Hardware & Reverse Geocoding (geolocator & geocoding)](#e-gps-hardware--reverse-geocoding-geolocator--geocoding)
   - [F. Cloud Firestore NoSQL Database](#f-cloud-firestore-nosql-database)
3. [Bedah Lengkap Modul Autentikasi (Auth)](#3-bedah-lengkap-modul-autentikasi-auth)
   - [1. Halaman Login](#1-halaman-login-loginscreendart)
   - [2. Halaman Registrasi Akun](#2-halaman-registrasi-akun-registerscreendart)
   - [3. Halaman Lupa Kata Sandi](#3-halaman-lupa-kata-sandi-forgotpasswordscreendart)
   - [4. Daftar Widget Modular Auth](#4-daftar-widget-modular-auth)
4. [Bedah Lengkap Modul Pengaturan Akun (Settings)](#4-bedah-lengkap-modul-pengaturan-akun-settings)
   - [1. Layar Orkestrator Utama](#1-layar-orkestrator-utama-pengaturanakunscreendart)
   - [2. Ubah Profil & Crop Foto Avatar](#2-ubah-profil--crop-foto-avatar)
   - [3. Ubah Nomor WhatsApp](#3-ubah-nomor-whatsapp-nomorwascreendart)
   - [4. Alamat Email & Auto-Polling Verifikasi](#4-alamat-email--auto-polling-verifikasi-alamatemailscreendart)
   - [5. Keamanan Akun (Ganti Sandi)](#5-keamanan-akun-keamananakunscreendart)
   - [6. Lokasi Anda (Peta Interaktif OSM & Multi-Label Saved Places)](#6-lokasi-anda-lokasiandascreendart)
   - [7. Kebijakan Privasi & Keluar Akun](#7-kebijakan-privasi--keluar-akun)
5. [Skema Database Firestore (`users`)](#5-skema-database-firestore-users)
6. [Panduan Menjalankan & Troubleshooting (Developer SOP)](#6-panduan-menjalankan--troubleshooting-developer-sop)
7. [Status Pengujian Otomatis (Automated Test Suite)](#7-status-pengujian-otomatis-automated-test-suite)

---

## 1. ARSITEKTUR KODE & STRUKTUR DIREKTORI

Kode pada `customer_app` disusun menggunakan standar **Clean Architecture (Feature-First)** agar modular, mudah diuji (*testable*), dan tidak ada penumpukan ribuan baris di satu file monolitik.

```
apps/customer_app/lib/
├── core/                                 # Utilitas, Model, dan Widget Global
│   ├── constants/
│   │   └── app_colors.dart               # Palet warna primer, lavender, dark, status colors
│   ├── models/
│   │   └── country_code.dart             # Sentralisasi model kode negara (+62 ID, +60 MY, dll)
│   ├── utils/
│   │   └── phone_number_formatter.dart   # Sentralisasi pembersihan & format nomor HP
│   └── widgets/
│       └── user_avatar.dart              # Komponen avatar seragam (foto URL / inisial fallback)
│
├── features/
│   ├── auth/                             # FITUR 1: AUTENTIKASI
│   │   ├── data/
│   │   │   ├── auth_service.dart         # Logika Firebase Auth, Firestore, Google Sign-In, SMS
│   │   │   └── wa_gateway_service.dart   # Klien HTTP ke WhatsApp Gateway (Kirim OTP 6-Digit)
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_screen.dart             # Halaman Masuk
│   │       │   ├── register_screen.dart          # Halaman Buat Akun Multi-Step
│   │       │   └── forgot_password_screen.dart   # Halaman Pemulihan Sandi
│   │       └── widgets/
│   │           ├── auth_input_field.dart         # Input box glassmorphism dengan indikator warna
│   │           ├── auth_social_buttons.dart      # Tombol Google Login & pembatas 'Atau'
│   │           ├── country_picker_modal.dart     # Modal Bottom Sheet pemilih bendera/kode negara
│   │           ├── terms_and_conditions_modal.dart # Modal S&K dengan checkbox persetujuan
│   │           ├── register_success_dialog.dart  # Modal pop-up sukses pendaftaran
│   │           ├── fallback_sms_dialog.dart      # Modal fallback kirim OTP via SMS Firebase
│   │           ├── reset_password_success_dialog.dart # Modal sukses ubah kata sandi
│   │           └── reset_password_email_sent_dialog.dart # Modal notifikasi link email terkirim
│   │
│   └── pengaturan/                       # FITUR 2: PENGATURAN AKUN
│       └── presentation/
│           ├── pages/
│           │   ├── pengaturan_akun_screen.dart   # Menu Utama Pengaturan (Orchestrator)
│           │   ├── ubah_profil_screen.dart       # Form ganti nama & ambil foto kamera/galeri
│           │   ├── atur_posisi_foto_screen.dart  # Canvas interaktif zoom/pan & crop lingkaran
│           │   ├── nomor_wa_screen.dart          # Form ganti nomor WA + verifikasi OTP baru
│           │   ├── alamat_email_screen.dart      # Tambah/ubah email + re-auth sandi
│           │   ├── keamanan_akun_screen.dart     # Ganti kata sandi lama ke sandi baru
│           │   ├── lokasi_anda_screen.dart       # Peta OSM, GPS live, reverse geocoding, simpan alamat
│           │   └── kebijakan_privasi_screen.dart # Teks Syarat & Kebijakan Privasi platform
│           └── widgets/
│               ├── profil_header_card.dart       # Card 1: Avatar, Nama, No WA, Badge Verified
│               ├── menu_item_tile.dart           # Item baris menu berlatar lavender
│               ├── tombol_keluar_akun.dart       # Tombol logout hitam + Modal Bottom Sheet konfirmasi
│               ├── email_verification_dialog.dart# Dialog polling otomatis status email verifikasi
│               ├── sub_header_widget.dart        # Header gradient atas & form textfield reusable
│               ├── crop_frame_painter.dart       # CustomPainter untuk grid crop avatar
│               └── country_code_selector.dart    # Kompatibilitas model negara pengaturan
```

---

## 2. PETA LAYANAN & THIRD-PARTY INTEGRATIONS

Berikut adalah rangkuman seluruh teknologi eksternal yang kita pasang di `customer_app`, alasan pemilihan, letak kode, dan letak visualnya di aplikasi:

| Layanan / Library | Apa Fungsinya? | Mengapa Menggunakan Ini? | Di Mana Kodenya? | Di Mana Letaknya di Aplikasi? |
| :--- | :--- | :--- | :--- | :--- |
| **WhatsApp Gateway** (`Baileys` Node.js) | Mengirimkan kode 6-digit OTP langsung ke chat WhatsApp pengguna. | **100% Gratis & Tanpa Biaya SMS**. Pengguna di Indonesia 99% aktif di WA, verifikasi instan tanpa pulsa. | Server: [`services/wa-gateway/`](file:///home/leon/Documents/Project/RideOn/services/wa-gateway/)<br>Klien: [`wa_gateway_service.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/data/wa_gateway_service.dart) | Layar Register (Langkah 2: Verif OTP), Layar Lupa Sandi, & Layar Ubah No WA di Pengaturan. |
| **Firebase SMS Phone Auth** (`firebase_auth`) | Mengirimkan SMS kode verifikasi resmi dari Google. | Sebagai **Fail-Safe / Fallback** jika WA Gateway sedang offline atau pengguna meminta kirim lewat SMS biasa. | [`auth_service.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/data/auth_service.dart) & [`fallback_sms_dialog.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/widgets/fallback_sms_dialog.dart) | Muncul lewat pop-up tombol *"Kirim lewat SMS"* jika hitung mundur OTP WA habis. |
| **Firebase Email Verification** (`firebase_auth`) | Mengirimkan link aktivasi email resmi dari Firebase ke inbox pengguna (`p1k.1v107@gmail.com`). | Memastikan alamat email pengguna valid sebelum ditandai status **Aktif** di profil. | [`alamat_email_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/alamat_email_screen.dart) & [`email_verification_dialog.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/widgets/email_verification_dialog.dart) | Menu Pengaturan -> Alamat Email -> Tombol Simpan -> Muncul Modal Polling Verifikasi. |
| **OpenStreetMap** (`flutter_map` + `latlong2`) | Menampilkan peta interaktif yang dapat digeser dan di-zoom secara mulus. | **Zero-Cost (Gratis)**. Tidak memerlukan kartu kredit atau tagihan Google Maps API untuk tahap pengembangan. | [`lokasi_anda_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/lokasi_anda_screen.dart) | Menu Pengaturan -> Lokasi Anda (Peta di separuh atas layar dengan pin ungu di tengah). |
| **GPS Sensor & Geocoding** (`geolocator` + `geocoding`) | Membaca koordinat lintang/bujur sensor HP & menerjemahkan titik ke nama jalan/kota (Reverse Geocoding). | Mengisi form alamat pengguna secara otomatis hanya dengan menekan 1 tombol GPS tanpa ketik manual. | [`lokasi_anda_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/lokasi_anda_screen.dart#L120-L200) | Tombol *"Gunakan Titik GPS Saat Ini"* pada halaman Lokasi Anda. |
| **Cloud Firestore** (`cloud_firestore`) | Database NoSQL dokumen real-time untuk data pengguna dan alamat. | Sinkronisasi instan multi-perangkat, terintegrasi erat dengan Firebase Auth & Security Rules. | [`auth_service.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/data/auth_service.dart) & seluruh screen pengaturan. | Seluruh data nama, no WA, email, status verified, dan saved address yang tampil di UI. |

---

## 3. BEDAH LENGKAP MODUL AUTENTIKASI (AUTH)

### 1. Halaman Login ([`login_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/pages/login_screen.dart))
- **Desain:** Background ungu gradien dengan card glassmorphism di tengah.
- **Fitur:**
  - Input Email atau Nomor WhatsApp (otomatis mengenali input angka vs format email).
  - Input Kata Sandi dengan tombol intip sandi (ikon mata).
  - Tombol *"Masuk Sekarang"*.
  - Tombol *"Lupa kata sandi?"* (berpindah ke `ForgotPasswordScreen`).
  - Tombol *"Masuk dengan Google"* (Google OAuth Sign-In sekali klik).
  - Tautan footer *"Belum punya akun? Buat Akun"* (berpindah ke `RegisterScreen`).

### 2. Halaman Registrasi Akun ([`register_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/pages/register_screen.dart))
Alur pendaftaran dirancang dengan validasi ketat dan pencegahan akun bodong:
1. **Langkah 1 (Input Identitas):**
   - Nama Lengkap (min 3 huruf, hanya alfabet).
   - Pemilih Kode Negara (default `+62` Indonesia dengan bendera merah putih).
   - Nomor WhatsApp (otomatis membersihkan angka `0` di depan).
2. **Langkah 2 (Verifikasi OTP WhatsApp 6-Digit):**
   - Server WA Gateway otomatis mengirim pesan berisi 6 digit kode OTP ke WA pengguna.
   - Kotak input 6 digit dengan auto-focus maju dan mundur.
   - Timer hitung mundur 60 detik untuk kirim ulang.
   - Jika WA bermasalah, pengguna dapat memilih pop-up fallback SMS Firebase.
3. **Langkah 3 (Pengaturan Kata Sandi & Persetujuan):**
   - Kata Sandi Baru (min 8 karakter, kombinasi huruf & angka).
   - Konfirmasi Kata Sandi.
   - Tombol Syarat & Ketentuan yang membuka [`TermsAndConditionsModal`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/widgets/terms_and_conditions_modal.dart).
   - Checkbox persetujuan wajib dicentang sebelum tombol *"Buat Akun"* aktif.
4. **Langkah 4 (Pembuatan Akun):**
   - Menghasilkan kredensial Firebase Auth.
   - Menyimpan dokumen user ke koleksi Firestore `users/{uid}`.
   - Menampilkan pop-up dialog sukses [`RegisterSuccessDialog`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/widgets/register_success_dialog.dart) dan mengarahkan ke Login/Beranda.

### 3. Halaman Lupa Kata Sandi ([`forgot_password_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/pages/forgot_password_screen.dart))
Mendukung 2 opsi pemulihan mandiri:
- **Opsi WhatsApp:** Mengirimkan kode 6 digit via WA -> verifikasi OTP -> form input kata sandi baru -> pembaruan kata sandi di auth & Firestore.
- **Opsi Email:** Mengirimkan link reset password resmi Firebase ke email pengguna -> menampilkan dialog [`ResetPasswordEmailSentDialog`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/auth/presentation/widgets/reset_password_email_sent_dialog.dart).

---

## 4. BEDAH LENGKAP MODUL PENGATURAN AKUN (SETTINGS)

### 1. Layar Orkestrator Utama ([`pengaturan_akun_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/pengaturan_akun_screen.dart))
Menggabungkan seluruh komponen menjadi satu tampilan bersih:
- **Top Header Bar:** Tombol kembali panah rounded + judul *"Pengaturan Akun"*.
- **Card 1 (Profil Info):** Memanggil [`ProfilHeaderCard`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/widgets/profil_header_card.dart) yang membaca nama, nomor HP, foto avatar, dan badge *"Verified"* toska.
- **Card 2 (Pengaturan Akun):** Kartu berlatar ungu lavender berisi 6 menu interaktif:
  1. **Ubah Profil:** Mengarah ke `UbahProfilScreen`.
  2. **Ubah Tema:** Membuka Bottom Sheet pilihan tema (*Mode Terang, Mode Gelap, Ikuti Sistem*).
  3. **Nomor WhatsApp:** Menampilkan nomor aktif + badge hijau toska *"Aktif"*.
  4. **Alamat Email:** Menampilkan email atau *"Belum ditambahkan"* + badge *"+Tambahkan"* atau *"Aktif"*.
  5. **Keamanan Akun:** Mengarah ke `KeamananAkunScreen`.
  6. **Lokasi Anda:** Mengarah ke `LokasiAndaScreen`.
- **Card 3 (Kebijakan):** Menu terpisah untuk *"Kebijakan Privasi & syarat"*.
- **Tombol Bawah:** Tombol hitam elegan [`TombolKeluarAkun`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/widgets/tombol_keluar_akun.dart) yang memicu dialog konfirmasi keluar.

### 2. Ubah Profil & Crop Foto Avatar
- **File:** [`ubah_profil_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/ubah_profil_screen.dart) & [`atur_posisi_foto_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/atur_posisi_foto_screen.dart)
- **Alur Kerja:**
  1. Pengguna dapat mengubah nama lengkap pada input field.
  2. Klik ikon kamera pada avatar untuk memilih foto dari **Kamera** atau **Galeri** (menggunakan library `image_picker`).
  3. Foto yang dipilih langsung dibawa ke layar **Atur Posisi Foto**.
  4. Pada layar atur posisi foto, pengguna dapat melakukan **geser (pan)** dan **cubit (pinch-to-zoom)** untuk menyesuaikan foto di dalam lingkaran preview Figma.
  5. Tekan tombol *"PILIH FOTO"* untuk menyimpan hasil crop ke penyimpanan lokal dan mengunggahnya ke Firestore.

### 3. Ubah Nomor WhatsApp
- **File:** [`nomor_wa_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/nomor_wa_screen.dart)
- **Alur Kerja:**
  1. Menampilkan nomor lama yang sedang aktif.
  2. Pengguna memasukkan nomor WhatsApp baru.
  3. Gateway WA mengirimkan kode OTP 6 digit ke nomor baru tersebut.
  4. Pengguna memverifikasi kode OTP -> jika valid, nomor pada dokumen Firestore diperbarui dan pengguna dikembalikan ke halaman pengaturan dengan snackbar sukses.

### 4. Alamat Email & Auto-Polling Verifikasi
- **File:** [`alamat_email_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/alamat_email_screen.dart) & [`email_verification_dialog.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/widgets/email_verification_dialog.dart)
- **Fitur Cerdas (Adaptif):**
  - **Mode 2 Kolom (Tambah Baru):** Jika akun belum memiliki email, pengguna hanya mengisi email baru & kata sandi konfirmasi.
  - **Mode 3 Kolom (Ubah Email):** Jika sudah ada email aktif, pengguna mengisi email lama, email baru, dan kata sandi.
  - **Auto-Polling Verifikasi:** Setelah email terkirim, aplikasi membuka dialog pemantau. Pengguna cukup membuka Gmail di tab/HP lain dan mengklik link verifikasi. Begitu link diklik, aplikasi Flutter mendeteksi `user.reload()` secara otomatis setiap 3 detik, menutup pop-up, dan langsung memperbarui status profil menjadi terverifikasi tanpa perlu login ulang!

### 5. Keamanan Akun
- **File:** [`keamanan_akun_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/keamanan_akun_screen.dart)
- **Fitur:**
  - Form Kata Sandi Lama, Kata Sandi Baru (min 8 karakter), dan Konfirmasi Kata Sandi Baru.
  - Toggle mata (sembunyikan / intip sandi) di ketiga kolom.
  - Tautan bantuan *"Lupa kata sandi?"* yang langsung menghubungkan ke alur lupa sandi.
  - Re-autentikasi kredensial pengguna ke Firebase Auth sebelum sandi baru disimpan.

### 6. Lokasi Anda
- **File:** [`lokasi_anda_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/lokasi_anda_screen.dart)
- **Fitur Canggih:**
  - **Peta Bebas Biaya:** Menggunakan tile layer OpenStreetMap via `flutter_map`.
  - **Pin Titik Presisi:** Pin ungu di tengah peta dengan badge instruksi *"Geser peta untuk atur titik"*.
  - **Tombol GPS:** Tombol *"Gunakan Titik GPS Saat Ini"* yang memeriksa status layanan lokasi & meminta permission Android secara dinamis.
  - **Reverse Geocoding:** Menerjemahkan latitude & longitude menjadi alamat lengkap (Jalan, Kelurahan, Kecamatan, Kabupaten/Kota) secara otomatis.
  - **Multi-Label Kategori:** Pilihan label tempat: `Rumah`, `Kantor`, `Kost`, dan `Lainnya`.
  - **Catatan Patokan:** Input teks untuk informasi tambahan bagi driver (contoh: *"Pagar hitam No. 12"*).
  - **Penyimpanan Firestore:** Data tersimpan rapi pada map `savedAddress` di Firestore.

### 7. Kebijakan Privasi & Keluar Akun
- **Kebijakan Privasi:** [`kebijakan_privasi_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/kebijakan_privasi_screen.dart) menampilkan detail izin akses, privasi data pengguna, dan ketentuan layanan RideOn.
- **Keluar Akun:** [`tombol_keluar_akun.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/widgets/tombol_keluar_akun.dart) memunculkan dialog konfirmasi. Jika user menekan *"Ya, Keluar"*, sesi `FirebaseAuth.instance.signOut()` dipanggil dan navigasi diarahkan kembali ke `LoginScreen`.

---

## 5. SKEMA DATABASE FIRESTORE (`users`)

Seluruh data pengguna pada aplikasi `customer_app` disimpan pada koleksi Firestore dengan struktur dokumen:

```json
users/{uid} = {
  "uid": "USER_FIREBASE_UID",
  "name": "Muhammad Taufiq",
  "phoneNumber": "+6285323441080",
  "email": "p1k.1v107@gmail.com",
  "photoUrl": "https://storage.googleapis.com/.../avatar.jpg",
  "emailVerified": true,
  "role": "customer",
  "savedAddress": {
    "label": "Rumah",
    "address": "Jl. Medan - Banda Aceh, Tambon Baroh, Dewantara, Aceh Utara",
    "latitude": 5.2472,
    "longitude": 97.0261,
    "note": "Pagar hitam depan warung kopi"
  },
  "createdAt": "2026-10-30T00:00:00Z",
  "updatedAt": "2026-10-30T10:30:00Z"
}
```

---

## 6. PANDUAN MENJALANKAN & TROUBLESHOOTING (DEVELOPER SOP)

### 1. Menjalankan Server WhatsApp Gateway (Local Baileys)
Sebelum menguji registrasi atau ganti no WA, pastikan gateway WA aktif di terminal:
```bash
cd services/wa-gateway
node server.js
```
*(Scan QR Code yang muncul di terminal menggunakan nomor WhatsApp pengirim OTP jika sesi baru).*

### 2. Menjalankan Customer App di HP / Emulator
```bash
cd apps/customer_app
flutter run
```

### 3. Mengatasi Error `MissingPluginException (geolocator_android)`
Jika setelah menambahkan library native Android muncul pesan merah `MissingPluginException`:
- **Jangan hanya melakukan Hot Reload (`r`)**.
- Matikan aplikasi dengan menekan tombol **`q`** di terminal.
- Bersihkan cache dan kompilasi ulang APK baru:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

---

## 7. STATUS PENGUJIAN OTOMATIS (AUTOMATED TEST SUITE)

Seluruh logika bisnis, interaksi UI, transisi form, validasi input, dan mock Firebase telah dicakup oleh test suite otomatis.

Untuk menjalankan seluruh tes:
```bash
cd apps/customer_app
flutter test
```

### Hasil Verifikasi:
- **`flutter test`**: **44 / 44 Tests Passed (100% Lolos)**
- **`flutter analyze`**: **0 Issues Found (100% Bersih)**
- Pengujian mencakup:
  - `test/widget_test.dart` (Smoke test awal & splash)
  - `test/login_screen_test.dart` (Form login, register, Google Auth, forgot password)
  - `test/pengaturan_akun_test.dart` (Orkestrator pengaturan, ubah profil, keamanan akun, alamat email, auto-polling verifikasi dialog)
  - `test/lokasi_anda_screen_test.dart` (Peta OSM, pin lokasi, tombol GPS, label alamat, simpan Firestore)
  - `test/home_favorit_test.dart` (Beranda & favorit)
  - `test/flexfood_flexsend_test.dart` (Layanan antar makanan & barang)
  - `test/chat_flexride_aktivitas_test.dart` (Aktivitas transaksi & chat)

---
*Dokumentasi ini disusun sebagai acuan pengembang utama agar proses kolaborasi, refactoring, dan penambahan fitur berikutnya pada RideOn Customer App berjalan konsisten, presisi, dan terstandarisasi.*

