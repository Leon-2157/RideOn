# 08 - Panduan Setup & Eksekusi Verifikasi SMS (Firebase Phone Auth)

> **Status:** Active & Ready for Verification  
> **Modul:** Customer App Authentication (Register & Phone SMS OTP)  
> **Target Package:** `com.rideon.customer`  
> **Firebase Project:** `rideon-9eb77`

---

## 1. Analisis Akar Masalah (Root Cause)

Saat pengujian pendaftaran akun di perangkat Android fisik, ditemukan dua kendala yang saling terkait:

1. **Muncul Dialog "Layanan WhatsApp Pemeliharaan" Padahal Belum Ada WA Gateway:**
   - **Penyebab:** Pada implementasi sebelumnya, penangan error Firebase Phone Auth `onVerificationFailed` langsung memanggil dialog fallback `_showFallbackSmsDialog`. Saat Firebase menolak request SMS, dialog tersebut muncul dan ketika tombol *"KIRIM KODE VIA SMS"* ditekan, ia memanggil kembali method yang sama sehingga terjadi pengulangan (loop).
   - **Perbaikan Kode:** Kami telah memperbaiki logika di `RegisterScreen`. Sekarang jika Firebase menolak otentikasi SMS, aplikasi langsung menampilkan pesan error spesifik yang informatif (misal: SHA-256 belum ada, kuota habis, atau provider belum aktif), tanpa memunculkan dialog WhatsApp yang membingungkan.

2. **Pengiriman SMS Ditolak oleh Firebase di Android Fisik:**
   - **Penyebab:** Firebase Phone Auth pada Android menggunakan mekanisme **Google Play Integrity / SafetyNet** untuk memverifikasi keaslian aplikasi. Mekanisme ini **mewajibkan SHA-256 Certificate Fingerprint** terdaftar di Firebase Console.
   - Pada file konfigurasi `google-services.json`, baru terdaftar sertifikat **SHA-1** (`46:1c:47:0f:...`), sedangkan **SHA-256 belum ditambahkan ke Firebase Console**.
   - Selain itu, pengiriman SMS nyata dibatasi oleh kuota harian Firebase Spark (gratis) dan sering tertahan oleh filter anti-spam operator seluler.

---

## 2. Nilai Fingerprint Keystore Pengembang

Berikut adalah sertifikat debug keystore lokal yang digunakan untuk build aplikasi ke HP Anda:

| Tipe Fingerprint | Nilai Hash | Status di Firebase Console |
| :--- | :--- | :--- |
| **SHA-1** | `46:1C:47:0F:77:A0:A5:39:70:98:CE:E3:E4:4A:15:7D:75:26:68:17` | ✅ Sudah Terdaftar |
| **SHA-256** | `70:6C:9D:C8:98:8B:45:DE:57:17:64:81:A1:9D:A5:7A:44:6A:74:7D:67:26:22:82:49:4F:CA:A2:B4:38:01:7A` | ⚠️ **Wajib Ditambahkan** |

---

## 3. Langkah Konfigurasi Firebase Console (Hanya 2 Menit)

### Langkah A: Tambahkan SHA-256 ke Aplikasi Customer
1. Buka [Firebase Console](https://console.firebase.google.com/project/rideon-9eb77/settings/general).
2. Di bagian **Your apps** (Aplikasi Anda), pilih aplikasi Android **`com.rideon.customer`**.
3. Gulir ke bagian **SHA certificate fingerprints** dan klik tombol **Add fingerprint**.
4. Tempelkan (paste) nilai SHA-256 berikut:
   ```
   70:6C:9D:C8:98:8B:45:DE:57:17:64:81:A1:9D:A5:7A:44:6A:74:7D:67:26:22:82:49:4F:CA:A2:B4:38:01:7A
   ```
5. Klik **Save**.

### Langkah B: Pastikan Provider "Phone" Aktif & Izinkan Wilayah Indonesia
1. Masuk ke menu **Build** > **Authentication** > tab **Sign-in method**.
2. Cari provider **Phone** di daftar sign-in provider.
3. Pastikan statusnya **Enabled** (sudah berhasil Anda aktifkan).

### Langkah C: Izinkan Wilayah Indonesia di SMS Region Policy (Wajib untuk Kirim SMS Nyata)
Google Firebase memiliki fitur keamanan anti-fraud yang secara default memblokir SMS ke negara-negara tertentu (Error Code `17006: SMS unable to be sent until this region enabled by the app developer`).
1. Masih di menu **Authentication**, klik tab **Settings** (di sebelah kanan tab *Usage*).
2. Pilih menu **SMS region policy** (Kebijakan wilayah SMS).
3. Pilih opsi **Allowlist** (atau Edit Policy), cari dan centang negara **Indonesia (+62)**.
4. Klik **Save**.

### Langkah D: Tambahkan Nomor Pengujian (Alternatif Testing Instan Tanpa Kuota)
Jika tidak ingin memotong kuota harian Firebase Spark (10 SMS/hari):
1. Masuk ke **Authentication** > tab **Settings** > bagian **Phone numbers for testing**.
2. Tambahkan:
   - **Nomor Telepon:** `+6285323441080`
   - **Kode Verifikasi 6 Digit:** `123456`
3. Klik **Add** / **Save**.

---

## 4. Alur Eksekusi & Validasi di Aplikasi

Setelah 3 langkah di atas dilakukan:
1. Di HP Anda, buka aplikasi RideOn (`com.rideon.customer`).
2. Masuk ke form **Daftar Akun**:
   - Nama: Muhammad Taufiq
   - Email (opsional): `taufiqmemucoba@gmail.com`
   - No. HP: `853 2344 1080` (dengan bendera 🇮🇩 `+62`)
   - Kata Sandi: min. 8 karakter (misal `password123`)
   - Ulangi Sandi: `password123`
   - Centang persetujuan Syarat & Ketentuan.
3. Klik tombol **BUAT AKUN**.
4. Aplikasi akan langsung bertransisi ke layar **Verifikasi OTP (6 digit)**.
5. Masukkan kode `123456`.
6. Klik **VERIFIKASI**:
   - Akun berhasil dibuat!
   - Profil customer tersimpan di Cloud Firestore `/users/{uid}`.
   - Muncul dialog *"Akun berhasil dibuat!"* dengan tombol *"MASUK SEKARANG"*.
   - Saat ditekan, form login akan otomatis terisi nomor HP Anda!

