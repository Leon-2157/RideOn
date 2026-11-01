# RideOn - Spesifikasi Arsitektur Sistem OTP WhatsApp Gateway & Monorepo

**Dokumen Standar Arsitektur Teknis Sistem Autentikasi, Notifikasi & Microservice Monorepo**  
*Status: Approved Architecture Blueprint (Pre-Implementation Documentation)*  
*Target Lingkungan: Monorepo Root (`services/wa-gateway/`), `apps/customer_app`, `apps/driver_app`, `apps/page_toko`*  

---

## 1. Penempatan Arsitektur: Root `services/` vs `apps/`

### A. Struktur Direktori Monorepo RideOn
RideOn menggunakan struktur **Monorepo** yang menaungi 3 aplikasi frontend/mobile dan layanan backend bersama (*shared microservices*):

```
RideOn/ (Monorepo Root)
├── apps/                               # Klien Antarmuka (Flutter Mobile & Web)
│   ├── customer_app/                   # Aplikasi Penumpang (Ride, Food, Courier)
│   ├── driver_app/                     # Aplikasi Mitra Driver
│   └── page_toko/                      # Aplikasi Web/Mobile Mitra Merchant Toko
│
├── services/                           # Shared Backend Microservices (Node.js/Go)
│   └── wa-gateway/                     # ⭐ LAYANAN RESMI WHATSAPP GATEWAY (DI ROOT)
│       ├── src/
│       │   ├── bot/telegram_watchdog.ts # Notifikasi otomatis jika sesi WA putus
│       │   ├── controllers/            # Endpoint /send-otp, /verify-otp, /health
│       │   ├── middleware/             # Rate limiter (cooldown 60s & 3x/jam), Auth key
│       │   ├── services/baileys.ts     # Engine WhatsApp Web Headless
│       │   └── index.ts                # Server Express
│       ├── .env.example                # Template konfigurasi rahasia
│       ├── Dockerfile                  # Kontainerisasi Docker
│       ├── ecosystem.config.js         # PM2 Process Manager
│       └── package.json
│
├── packages/                           # Shared Dart Packages (Model data, Theme, Util)
│
└── docs/                               # ⭐ PUSAT DOKUMENTASI SISTEM (SINGLE SOURCE OF TRUTH)
    ├── 01-system-architecture.md       # Arsitektur sistem menyeluruh
    ├── 02-database-design.md           # Skema Firestore & Relasi
    ├── 03-firebase-library-checklist.md# Integrasi Firebase
    ├── 04-authentication-guide.md      # Panduan autentikasi dasar
    ├── 05-project-worklog-and-handover.md # Log pengerjaan & serah terima
    ├── 06-auth-registration-otp-revision.md # Spesifikasi revisi UI/UX form registrasi
    └── 07-whatsapp-gateway-and-otp-architecture.md # ⭐ (Dokumen Ini)
```

---

### B. Mengapa WA Gateway Wajib Ditaruh di Root `services/` dan BUKAN di `apps/`?

1. **Prinsip Layanan Bersama (Shared Microservice untuk 3 Aplikasi):**
   - Di dalam monorepo RideOn terdapat **3 aplikasi berbeda**:
     1. `apps/customer_app` (Customer mendaftar & login butuh OTP)
     2. `apps/driver_app` (Driver masuk & notifikasi order butuh OTP/WA)
     3. `apps/page_toko` (Toko menerima pesanan makanan/belanja baru via notifikasi WA)
   - Jika service WA Gateway ditaruh di dalam `apps/customer_app`, maka `driver_app` dan `page_toko` akan memiliki ketergantungan aneh (*tight coupling / circular dependency*) ke folder aplikasi customer. Ini adalah pelanggaran arsitektur software (*bad practice*).
   - Menaruhnya di `services/wa-gateway/` di root monorepo membuat service ini berstatus **netral, independen, dan dapat diakses bersama secara bersih** oleh ketiga aplikasi.

2. **Efisiensi Finansial & Operasional (1 Nomor WhatsApp Resmi & 1 Server VPS):**
   - Kita tidak perlu membeli 3 nomor WhatsApp atau menyewa 3 VPS terpisah untuk masing-masing aplikasi.
   - Cukup **1 nomor WhatsApp resmi RideOn** yang terhubung di `services/wa-gateway/` di VPS untuk melayani ribuan pengguna dari ketiga aplikasi sekaligus.

3. **Pemisahan Siklus Rilis (Independent Deployment Cycle):**
   - Aplikasi mobile di `apps/` di-build menjadi file binary APK / AAB dan diunggah ke Google Play Store (membutuhkan waktu review beberapa hari).
   - Layanan backend di `services/wa-gateway/` di-deploy langsung ke VPS (Linux/Ubuntu) menggunakan Docker atau PM2. Jika ada pembaruan library WA atau patch keamanan, server bisa di-restart dalam hitungan detik tanpa perlu memaksa pengguna meng-update APK mereka di PlayStore.

---

### C. Mengapa Dokumentasi Dipusatkan di Folder Root `docs/`?

- **Single Source of Truth (SSOT):** Seluruh arsitektur, skema basis data, alur bisnis, dan panduan integrasi monorepo dipusatkan di folder `docs/` di root.
- Setiap pengembang (baik frontend customer, frontend driver, frontend toko, maupun backend) memiliki satu tempat yang jelas untuk membaca aturan main sistem tanpa informasi yang tercecer atau bertolak belakang antar folder aplikasi.

---

## 2. Diagram Alur Sistem Terintegrasi

```mermaid
flowchart TD
    subgraph Klien["Aplikasi Klien (Monorepo apps/)"]
        CA["apps/customer_app (Flutter)"]
        DA["apps/driver_app (Flutter)"]
        PT["apps/page_toko (Flutter)"]
    end

    subgraph Gateway["Shared Backend: services/wa-gateway (VPS Linux)"]
        API["Express REST API (Port 5050)"]
        SEC["Auth Guard (x-gateway-key)"]
        RATE["Rate Limiter (60s Cooldown / Max 3x per jam)"]
        ENGINE["Baileys WhatsApp Engine (Multi-Device WA Web)"]
        DOG["Telegram Watchdog (Connection Monitor)"]
    end

    subgraph FirebaseCloud["Google Firebase Cloud Platform"]
        FS["Cloud Firestore (/otp_verifications/{phone})"]
        FBA["Firebase Phone Auth (SMS Backup SLA 99.99%)"]
    end

    subgraph Eksternal["Pengguna & Admin"]
        USER_WA["WhatsApp User (+62 xxx)"]
        ADMIN_TG["Telegram Admin (@admin_rideon)"]
    end

    CA -->|1. Request OTP via HTTPS| API
    DA -->|1. Request OTP via HTTPS| API
    PT -->|1. Request OTP via HTTPS| API

    API --> SEC
    SEC --> RATE
    RATE -->|Lolos Validasi| ENGINE
    ENGINE -->|2. Kirim Chat OTP WA| USER_WA
    ENGINE -->|Simpan Hash OTP| FS

    DOG -->|3. Terdeteksi Disconnect (Baterai Habis/Logout)| ADMIN_TG

    CA -.->|4. Otomatis Fallback jika WA Timeout/Down (3-5 detik)| FBA
    FBA -.->|Kirim SMS Alternatif| USER_WA
```

---

## 3. Spesifikasi Keamanan, Cooldown & Anti-Banned

WhatsApp memiliki algoritma deteksi spam yang ketat. Agar nomor server RideOn tetap aman:

### A. Aturan Jeda Waktu (Cooldown & Rate Limiting)
1. **Cooldown Antar Kirim (60 Detik):**
   - User harus menunggu 60 detik sebelum bisa menekan tombol *"Kirim Ulang"*.
   - Timer hitung mundur ditampilkan di UI layar verifikasi (`00:59` hingga `00:00`).
   - Server menolak permintaan pengiriman baru jika jeda 60 detik belum tercapai.
2. **Batas Frekuensi (Max 3 Kali per Jam):**
   - Setiap nomor telepon hanya diizinkan meminta maksimal 3 kali OTP dalam jendela waktu 1 jam.
   - Jika melebihi batas, request ditolak dengan pesan: *"Terlalu banyak permintaan OTP. Silakan tunggu 1 jam atau hubungi Bantuan RideOn."*
3. **Masa Berlaku Kode (TTL):**
   - Kode OTP berlaku selama **5 Menit (300 detik)**.
   - Setelah 5 menit, kode otomatis hangus dan tidak dapat divalidasi.

### B. Format & Enkripsi Kode OTP
- Kode berupa 6 digit angka acak yang dihasilkan secara kriptografis: `crypto.randomInt(100000, 999999)`.
- Di database Firestore (`/otp_verifications/{phoneNumber}`), kode disimpan dalam bentuk **Hash SHA-256 (salted)**, sehingga tidak ada yang bisa membaca kode OTP secara langsung di database.

### C. Proteksi API Key Antara Klien & Gateway
- Setiap request dari `customer_app`, `driver_app`, maupun `page_toko` wajib menyertakan header:
  `x-gateway-key: <SUPER_SECRET_KEY_RIDEON>`
- Request tanpa header yang valid akan ditolak seketika (HTTP 401 Unauthorized), mencegah pihak luar mengeksploitasi nomor WA server untuk spam.

---

## 4. Skema Data Firestore: `/otp_verifications/{phoneNumber}`

Format dokumen penyimpanan sesi OTP di Cloud Firestore:

```json
{
  "phoneNumber": "+6281234567890",
  "otpHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "channel": "whatsapp",                // "whatsapp" atau "sms_fallback"
  "targetRole": "customer",             // "customer", "driver", atau "merchant"
  "createdAt": "2026-10-29T22:30:00Z",
  "expiresAt": "2026-10-29T22:35:00Z", // TTL 5 Menit
  "attempts": 0,                        // Maksimal salah 3x sebelum diblokir
  "isVerified": false,
  "lastSentAt": "2026-10-29T22:30:00Z",
  "hourlyAttempts": 1                   // Direset tiap 1 jam
}
```

---

## 5. Format Pesan WhatsApp Resmi RideOn

Pesan yang dikirimkan ke pengguna dirancang resmi, profesional, dan ringkas:

```
🛵 *RideOn Indonesia - Kode Verifikasi*

Halo Kak! 
Kode verifikasi pendaftaran akun RideOn Anda adalah:

👉 *[ 4 8 2 9 1 0 ]*

_Kode ini berlaku selama 5 menit._
⚠️ *PENTING:* Demi keamanan akun Anda, JANGAN pernah memberikan kode ini kepada siapa pun, termasuk pihak yang mengaku sebagai staf RideOn.

Terima kasih telah bergabung bersama RideOn!
```

---

## 6. Mekanisme Redundansi & Fallback SMS (Anti-Down 99.99%)

Ketergantungan pada 1 server VPS diatasi dengan sistem **Smart Fallback Hybrid (Otomatis & Manual)**:

```
[User Klik 'Daftar Akun']
          │
          ├──> 1. Panggil Health Check & Send OTP ke WA Gateway
          │
          ├──> KONDISI A: Gateway Normal (Respons < 3 detik)
          │    ├── Layar berpindah ke "verif otp daftar.png" (Input 6 digit OTP WA)
          │    │
          │    └── [Pemicu Manual]: Jika chat WA lambat masuk, user dapat mengklik:
          │        "Tidak menerima kode di WhatsApp? Kirim via SMS"
          │        └── Memunculkan Dialog Fallback SMS ("dialog fallback sms.png")
          │
          └──> KONDISI B [Pemicu Otomatis]: Gateway Mati / Timeout (> 3 detik) / Nomor WA Terputus
               │
               ├──> 2. Aplikasi otomatis memunculkan Dialog Fallback ("dialog fallback sms.png")
               │       Judul: "Layanan WhatsApp Pemeliharaan"
               │       Pesan: "Pengiriman kode via WhatsApp sedang tidak tersedia.
               │               Apakah Anda ingin mengirimkan kode verifikasi melalui SMS?"
               │
               └──> 3. User Klik [KIRIM KODE VIA SMS]
                       └── Aplikasi memanggil Firebase Phone Auth (Google SMS Network)
                       └── OTP terkirim via SMS biasa tanpa kendala!
```

**Hasil:** Jika VPS listrik padam, internet server down, atau WhatsApp Web maintenance, operasional bisnis pendaftaran customer, driver, dan toko **tetap berjalan 100% tanpa henti**.

---

## 6.1 Alur Navigasi Pasca-Verifikasi (Post-Verification Flow)

1. **Server-Side Verification (`POST /api/otp/verify`):**
   - User memasukkan 6 digit di layar `verif otp daftar.png`.
   - Flutter mengirimkan `{ phoneNumber, otpCode }` ke server.
   - Gateway mencocokkan SHA-256 hash dengan database Firestore. Kode asli tidak pernah terekspos di sisi klien.
2. **Akun Diaktifkan:**
   - Dokumen user `/users/{uid}` di Firestore ditandai dengan `phoneVerified: true`.
3. **Pop-up Sukses (`berhasil daftar.png`):**
   - Muncul dialog frosted glass: *"Akun Berhasil Dibuat! Silakan masuk dengan akun yang telah Anda daftarkan."*
   - Tombol **`MASUK SEKARANG`**: Mengarahkan pengguna kembali ke halaman Login (`LoginScreen`) untuk masuk pertama kali dengan nomor WhatsApp dan kata sandi baru.

---

## 6.2 Alur Verifikasi Email (Profile-Based Verification)

- **Pendaftaran Tanpa Hambatan:** Saat mendaftar, field email berlabel `Alamat Email (Opsional)` agar proses registrasi cepat dan bebas friksi.
- **Verifikasi Asli/Palsu di Profil Pengguna:**
  - Jika pengguna ingin memvalidasi emailnya (untuk login alternatif atau pemulihan sandi via email), pengguna membuka menu **Pengaturan Akun / Profil** (`HalamanPengaturanAkun/alamat email.png`).
  - Pengguna menekan tombol *"Verifikasi Email Ini"*, lalu Firebase Auth mengirimkan tautan / OTP verifikasi langsung ke inbox email pengguna.
  - Setelah diklik, status email diubah menjadi `emailVerified: true` di database.

---

## 7. Sistem Pemantau & Notifikasi Otomatis ke Telegram Admin

Modul `src/bot/telegram_watchdog.ts` memantau koneksi WhatsApp 24/7:

1. **Event Monitor:** Mendengarkan event Baileys `connection.update`.
2. **Saat Status Terputus (`close` / `logged_out`):**
   - Mengirim notifikasi darurat langsung ke akun Telegram Admin:
     ```
     🚨 [DARURAT RIDEON] WHATSAPP GATEWAY TERPUTUS!
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Waktu    : 29-10-2026 22:30:00 WIB
     Server   : VPS-Rideon-Prod-01
     Status   : Disconnected / Logged Out
     
     Tindakan Segera:
     1. Buka tautan scan QR berikut di browser HP:
        👉 https://wa-gateway.rideon.id/wa/scan
     2. Scan ulang QR Code dengan WhatsApp resmi RideOn.
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Catatan: Sistem fallback otomatis mengalihkan OTP ke SMS sementara waktu.
     ```
3. **Portal Scan QR (`GET /wa/scan`):**
   - Dilindungi kata sandi admin sederhana (*HTTP Basic Auth*).
   - Menampilkan QR Code live yang otomatis me-refresh diri setiap 15 detik. Admin cukup buka link di HP dan scan langsung tanpa perlu buka terminal atau SSH VPS.

---

## 8. Panduan Konfigurasi Lingkungan (`.env`) & Deployment

### File `.env` di `services/wa-gateway/.env`:
```ini
# Server Settings
PORT=5050
NODE_ENV=production
GATEWAY_SECRET_KEY=rideon_super_secret_auth_token_2026

# WhatsApp Session Storage
SESSION_DIR=./auth_info_baileys

# Telegram Bot Alert
TELEGRAM_BOT_TOKEN=123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ
TELEGRAM_ADMIN_CHAT_ID=987654321

# Web QR Portal Security
ADMIN_WEB_USER=admin
ADMIN_WEB_PASSWORD=password_kuat_admin_2026

# Firebase Admin SDK (Opsional untuk sync Firestore)
FIREBASE_PROJECT_ID=rideon-project
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
```

### Deployment di VPS Linux (Menggunakan PM2):
```bash
cd /var/www/RideOn/services/wa-gateway
npm install
npm run build
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

## 9. Matriks Status Dokumen & Kesiapan Proyek

| Modul | Status Desain | Status Dokumentasi | Status Kode |
| :--- | :---: | :---: | :---: |
| **Form Pendaftaran 4 Field** | Selesai (`daftar akun dengan email.png`) | Selesai (`docs/06-auth-registration-otp-revision.md`) | Siap Diimplementasi |
| **Layar Verifikasi OTP** | Selesai (`verif otp daftar.png`) | Selesai (`docs/06` & `docs/07`) | Siap Diimplementasi |
| **Dialog Fallback SMS** | Selesai (`dialog fallback sms.png`) | Selesai (`docs/07-whatsapp-gateway-and-otp-architecture.md`) | Siap Diimplementasi |
| **Microservice WA Gateway** | - | Selesai (`docs/07-whatsapp-gateway-and-otp-architecture.md`) | Menunggu Persetujuan |
| **Watchdog Telegram Admin** | - | Selesai (`docs/07-whatsapp-gateway-and-otp-architecture.md`) | Menunggu Persetujuan |
