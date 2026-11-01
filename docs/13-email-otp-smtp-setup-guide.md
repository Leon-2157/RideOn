# PANDUAN AKTIVASI EMAIL OTP & GMAIL SMTP (RP 0) - RIDEON

Dokumen ini adalah Standard Operating Procedure (SOP) untuk mengaktifkan pengiriman kode verifikasi 6-digit OTP Alamat Email ke Gmail pengguna secara nyata tanpa biaya sepeser pun (**Rp 0**).

---

## 1. Arsitektur Singkat (Hybrid)
* **Klien (Flutter `customer_app`):** Form Alamat Email -> 6 Kotak Putih OTP -> Dialog Sukses Figma.
* **Backend (`services/wa-gateway/server.js`):** Endpoint `POST /api/email/otp/send` & `POST /api/email/otp/verify`.
* **Transport Driver:** Nodemailer via Gmail SMTP Relay (`smtp.gmail.com:587`).
* **Database & Auth:** Cloud Firestore `users/{uid}` & Firebase Authentication.

---

## 2. Langkah-Langkah Konfigurasi (2 Menit)

### Langkah 1: Buat Sandi Aplikasi (Google App Password)
1. Buka browser dan login ke akun Google / Gmail yang akan dijadikan pengirim email RideOn:
   👉 **[https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)**
   *(Pastikan **Verifikasi 2 Langkah / 2-Step Verification** pada akun Google Anda sudah AKTIF)*.
2. Pada bagian **"App name"** (Nama aplikasi), ketik: `RideOn Gateway`.
3. Klik tombol **Create** (Buat).
4. Google akan memunculkan pop-up kotak kuning berisi **16 karakter huruf** (contoh: `abcd efgh ijkl mnop`).
5. Salin 16 karakter tersebut.

---

### Langkah 2: Masukkan Kredensial ke `services/wa-gateway/.env`
Buka file `services/wa-gateway/.env` dan lengkapi bagian SMTP:

```env
PORT=3000
WHATSAPP_GATEWAY_SECRET=rideon-wa-secret-2026
APP_NAME=RideOn
SESSION_DIR=./storage/sessions

# Gmail SMTP 100% Gratis (Rp 0 - Kuota 500 email/hari)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=emailanda@gmail.com
SMTP_PASS=abcdefghijklmnop
SMTP_FROM=
```

> **Catatan Pengisian:**
> * `SMTP_USER`: Alamat Gmail lengkap Anda (contoh: `admin.rideon@gmail.com`).
> * `SMTP_PASS`: 16 karakter sandi aplikasi dari Google **tanpa spasi** (contoh: `abcdefghijklmnop`).
> * `SMTP_FROM`: Biarkan kosong agar otomatis menggunakan nama resmi `"RideOn Security" <emailanda@gmail.com>`.

---

### Langkah 3: Restart Gateway
Jalankan perintah berikut di terminal:
```bash
cd services/wa-gateway
npm start
```

Jika berhasil terhubung, terminal akan menampilkan log:
```log
[EMAIL SMTP] Configured with host: smtp.gmail.com
🚀 RideOn WhatsApp Gateway running on port 3000
```

---

## 3. Cara Pengujian di Aplikasi
1. Buka aplikasi **Customer App** di HP Android atau Emulator.
2. Masuk ke menu **Pengaturan Akun** -> **Alamat Email**.
3. Masukkan kata sandi akun dan alamat email penerima, lalu tekan **VERIFIKASI EMAIL**.
4. Buka aplikasi Gmail di HP / browser Anda:
   * Email resmi dari RideOn Security akan masuk dalam hitungan detik berisi **6 digit angka OTP**.
5. Masukkan 6 digit angka tersebut ke dalam 6 kotak input di aplikasi RideOn.
6. Pop-up dialog frosted glass **"Email Berhasil Ditambahkan!"** akan muncul dan status email langsung berubah menjadi **Aktif**.

---

## 4. Fallback Mode Simulasi (Jika Belum Diisi)
Jika Anda belum mengisi `SMTP_USER` dan `SMTP_PASS` di file `.env`, sistem gateway secara otomatis berjalan dalam **Mode Simulasi**:
* Kode 6-digit OTP tidak akan error, melainkan dicetak langsung di console terminal server.
* Kode juga otomatis dikirimkan ke aplikasi Flutter dan ditampilkan via SnackBar ungu untuk kemudahan testing tanpa kuota.

