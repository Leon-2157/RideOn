# RideOn - Platform On-Demand Transport & Merchant (Monorepo)

Selamat datang di repositori monorepo resmi **RideOn**. Proyek ini mencakup 3 aplikasi klien Flutter, layanan backend pendukung (*microservices*), dan paket bersama.

---

## 1. Struktur Direktori Monorepo

```
RideOn/
├── apps/                               # Klien Antarmuka Pengguna
│   ├── customer_app/                   # Aplikasi Mobile Pelanggan (Ride, Food, Mart)
│   ├── driver_app/                     # Aplikasi Mobile Mitra Pengemudi
│   └── page_toko/                      # Aplikasi Web/Mobile Mitra Toko & Restoran
│
├── services/                           # Shared Backend Microservices
│   └── wa-gateway/                     # Layanan Terpusat WhatsApp Gateway (Node.js Baileys)
│
├── packages/                           # Shared Dart Packages (Model, Utilities, Theme)
│
└── docs/                               # Dokumentasi Resmi & Spesifikasi Sistem (SSOT)
    ├── 01-system-architecture.md       # Arsitektur sistem monorepo & tech-stack
    ├── 02-database-design.md           # Skema Firestore, relasi, & aturan keamanan
    ├── 03-firebase-library-checklist.md# Checklist dependensi Firebase Flutter
    ├── 04-authentication-guide.md      # Panduan autentikasi & peran pengguna
    ├── 05-project-worklog-and-handover.md # Log pengerjaan & catatan serah terima
    ├── 06-auth-registration-otp-revision.md # Spesifikasi revisi pendaftaran & OTP Customer
    ├── 07-whatsapp-gateway-and-otp-architecture.md # Arsitektur WhatsApp Gateway & SMS Fallback
    └── 08-firebase-phone-auth-sms-setup.md # Panduan Setup & Eksekusi Verifikasi SMS (Firebase Phone Auth)
```

---

## 2. Gambaran Aplikasi (3 Apps Monorepo)

| Aplikasi | Path | Target Pengguna | Fitur Utama |
| :--- | :--- | :--- | :--- |
| **Customer App** | `apps/customer_app` | Pengguna / Penumpang | Pesan ojek/mobil, pesan makanan, kirim paket, pelacakan real-time, dompet digital. |
| **Driver App** | `apps/driver_app` | Mitra Pengemudi | Terima orderan, navigasi peta GPS, riwayat pendapatan, penarikan saldo (withdraw). |
| **Page Toko** | `apps/page_toko` | Mitra Merchant Toko | Manajemen katalog menu/produk, terima pesanan masuk, laporan penjualan harian. |

---

## 3. Layanan Bersama (Shared Services)

- **`services/wa-gateway`**:
  Microservice berbasis Node.js & Baileys yang bertindak sebagai WhatsApp Web Headless di VPS. Melayani pengiriman OTP pendaftaran untuk Customer/Driver dan notifikasi pesanan untuk Toko dengan 1 nomor WhatsApp resmi terpusat. Dilengkapi sistem pemantau otomatis via Telegram Bot dan *smart fallback* ke SMS Firebase bila layanan WhatsApp offline.

---

## 4. Indeks Dokumentasi Sistem (`docs/`)

Untuk memahami alur teknis dan aturan arsitektur secara mendalam, silakan baca dokumentasi di folder `docs/`:
1. [01 - System Architecture](docs/01-system-architecture.md)
2. [02 - Database Design & Firestore Schema](docs/02-database-design.md)
3. [03 - Firebase Library Checklist](docs/03-firebase-library-checklist.md)
4. [04 - Authentication Guide](docs/04-authentication-guide.md)
5. [05 - Project Worklog & Handover](docs/05-project-worklog-and-handover.md)
6. [06 - Auth Registration & OTP Revision](docs/06-auth-registration-otp-revision.md)
7. [07 - WhatsApp Gateway & OTP Architecture](docs/07-whatsapp-gateway-and-otp-architecture.md)

---

## 5. Persyaratan Sistem & Tooling

- **Flutter SDK:** `>=3.19.0`
- **Dart SDK:** `>=3.3.0`
- **Node.js:** `>=18.0.0` (khusus modul di `services/`)
- **Firebase CLI:** `>=13.0.0`
