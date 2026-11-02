# RideOn — System Architecture Document

> **Project**: RideOn (Ride-Hailing & Multi-Service Platform)
> **Versi**: 1.0.0
> **Tanggal**: 28 Oktober 2026
> **Konteks**: Project akademik (tugas akhir) dengan standar profesional & scalable

---

## 1. Ringkasan Project

RideOn adalah platform multi-service yang terdiri dari **3 aplikasi mobile Flutter** dan **1 admin dashboard web**, saling terhubung melalui satu Firebase project.

### 1.1 Tiga Layanan Utama

| Layanan | Deskripsi | Aktor |
|---------|-----------|-------|
| **FlexRide** | Ojek motor & mobil (ride-hailing) | Customer ↔ Driver |
| **FlexFood** | Pesan makanan dari mitra toko | Customer ↔ Driver ↔ Toko |
| **FlexSend** | Titip belanja & kirim barang | Customer ↔ Driver ↔ Toko (opsional) |

### 1.2 Empat Aplikasi

| App | Platform | Teknologi | Deskripsi |
|-----|----------|-----------|-----------|
| `customer_app` | Android (Flutter) | Dart, Material 3 | App untuk pengguna memesan layanan |
| `driver_app` | Android (Flutter) | Dart, Material 3 | App untuk driver menerima & menjalankan orderan |
| `page_toko` | Android + Web (Flutter) | Dart, Material 3 | App untuk mitra toko mengelola pesanan & menu |
| `admin_dashboard` | Web (React/Next.js) | TypeScript | Dashboard kontrol pusat platform |

---

## 2. Analisis Figma — Fitur per Aplikasi

### 2.1 Customer App (`customer_app`)

**Sumber**: Figma node `0-1`

| Modul | Halaman | Fitur Kunci |
|-------|---------|-------------|
| **Splash & Auth** | Splash Screen, Login, Register, Lupa Sandi, OTP WA | Email/password login, verifikasi OTP via WhatsApp |
| **Home / Beranda** | Dashboard utama | 3 service cards (FlexRide, FlexFood, FlexSend), alamat favorit, promo banner |
| **FlexRide** | Input lokasi, Pilih kendaraan, Cari driver, Tracking, Sampai | Motor/Mobil, pickup note, real-time tracking, chat & call driver |
| **FlexFood** | Pilih toko, Menu makanan, Keranjang, Checkout, Tracking | Kategori toko, cari menu, catatan pesanan, lacak kurir |
| **FlexSend** | Input toko/alamat, Detail item, Checkout, Tracking | Titip belanja multi-toko, estimasi talangan, lacak pengiriman |
| **Chat** | Riwayat chat, Detail chat, Panggilan | Real-time messaging dengan driver, voice call |
| **Aktivitas** | Riwayat pesanan | List semua order (FlexRide/Food/Send), detail per order, re-order |
| **Favorit** | Toko & menu favorit | Bookmark toko/menu untuk akses cepat |
| **Pengaturan** | Profil, Keamanan, Tema, Kebijakan | Ubah profil, ubah sandi, dark/light mode, logout |

### 2.2 Driver App (`driver_app`)

**Sumber**: Figma node `0-1` + folder `Figma/` di driver_app

| Modul | Halaman | Fitur Kunci |
|-------|---------|-------------|
| **Splash & Auth** | Splash, Login, Register (9 step!), Lupa Sandi, OTP | Upload SIM, STNK, SKCK, foto profil, foto kendaraan, syarat & ketentuan |
| **Radar** | Peta real-time dengan status online/offline | GPS tracking, area sibuk (heatmap), toggle online/off, cari orderan terbaik |
| **Radar FlexRide** | Orderan penumpang masuk | Countdown 16 detik, geser terima/tolak, info penumpang, jarak, estimasi |
| **Radar FlexFood** | Orderan makanan masuk | Countdown, info toko, pendapatan bersih, metode bayar (Non-Tunai/E-Wallet) |
| **Radar FlexSend** | Orderan titip belanja masuk | Countdown, multi-item, estimasi talangan, modal kas driver |
| **Aktivitas** | Riwayat orderan driver | List orderan selesai, filter per tipe layanan |
| **Dompet** | Saldo aktif, transaksi, tarik dana | Pendapatan ongkir, refund talangan, fee admin, klaim dana penipuan |
| **Chat** | Riwayat chat, Detail, Telepon | Komunikasi dengan customer selama order aktif |
| **Pengaturan Akun** | Profil, Tema, Verifikasi, Kendaraan, Keamanan | Status verified, info kendaraan (plat nomor), ubah sandi, dark mode |

### 2.3 Toko App (`page_toko`)

**Sumber**: Figma node `28-5161` + AGENT.md

| Modul | Halaman | Fitur Kunci |
|-------|---------|-------------|
| **Auth & Pendaftaran** | Login, Lupa Sandi, OTP WA, Register (2 step) | Upload STNK, rekening bank, SKCK, foto tempat usaha, syarat & ketentuan |
| **Tab 1: Home** | Beranda toko | Toggle buka/tutup toko, ringkasan omzet hari ini, performa, notifikasi live |
| **Tab 2: Pesanan** | Manajemen order | Filter: Baru → Dimasak → Siap untuk Kurir → Selesai/Batal, detail pesanan, kontak kurir |
| **Tab 3: Menu** | Katalog menu | Daftar makanan/minuman, toggle stok (Aktif/Habis), tambah & edit menu + foto |
| **Tab 4: Keuangan** | Saldo & transaksi | Saldo aktif, riwayat transaksi masuk/keluar, pengaturan rekening bank, penarikan + PIN |
| **Tab 5: Toko** | Profil resto | Foto/nama/deskripsi toko, jam operasional per hari, pinpoint & alamat lokasi |

---

## 3. Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RIDEON PLATFORM                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────────┐   │
│  │ Customer │  │  Driver  │  │   Toko   │  │ Admin Dashboard   │   │
│  │   App    │  │   App    │  │   App    │  │   (Web)           │   │
│  │ Flutter  │  │ Flutter  │  │ Flutter  │  │ Next.js           │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬──────────┘   │
│       │              │             │                  │              │
│       └──────────────┴─────────────┴──────────────────┘              │
│                              │                                      │
│                    ┌─────────▼──────────┐                           │
│                    │  FIREBASE PROJECT  │                           │
│                    │  (Single Project)  │                           │
│                    ├────────────────────┤                           │
│                    │                    │                           │
│  ┌─────────────────┤  Firebase Auth     │                           │
│  │                 │  (Email + WA OTP)  │                           │
│  │                 ├────────────────────┤                           │
│  │                 │                    │                           │
│  │  ┌──────────────┤  Cloud Firestore   │◄── Data Struktural       │
│  │  │              │  (Main Database)   │                           │
│  │  │              ├────────────────────┤                           │
│  │  │              │                    │                           │
│  │  │  ┌───────────┤  Realtime Database │◄── Location, Chat,       │
│  │  │  │           │  (Live Data)       │    Presence               │
│  │  │  │           ├────────────────────┤                           │
│  │  │  │           │                    │                           │
│  │  │  │  ┌────────┤  Cloud Storage     │◄── Foto profil, chat,    │
│  │  │  │  │        │  (Media Files)     │    foto menu              │
│  │  │  │  │        ├────────────────────┤                           │
│  │  │  │  │        │                    │                           │
│  │  │  │  │  ┌─────┤  Cloud Functions   │◄── Backend logic,        │
│  │  │  │  │  │     │  (Serverless)      │    WA OTP, FCM            │
│  │  │  │  │  │     ├────────────────────┤                           │
│  │  │  │  │  │     │                    │                           │
│  │  │  │  │  │  ┌──┤  FCM               │◄── Push Notifications    │
│  │  │  │  │  │  │  │  (Messaging)       │                           │
│  │  │  │  │  │  │  ├────────────────────┤                           │
│  │  │  │  │  │  │  │                    │                           │
│  │  │  │  │  │  │  │  Firebase Hosting  │◄── Admin Dashboard +     │
│  │  │  │  │  │  │  │  (Web Deploy)      │    Landing Page           │
│  │  │  │  │  │  │  └────────────────────┘                           │
│  │  │  │  │  │  │                                                   │
│  └──┴──┴──┴──┴──┴───────────────┐                                   │
│                                 │                                   │
│                    ┌────────────▼────────────┐                      │
│                    │   ORACLE CLOUD (OCI)    │                      │
│                    │   (Student Account)     │                      │
│                    ├─────────────────────────┤                      │
│                    │                         │                      │
│                    │  Object Storage         │◄── Dokumen verifikasi│
│                    │  (Dokumen Besar)        │    (SIM, STNK, SKCK) │
│                    │                         │                      │
│                    │  OCI Functions          │◄── Geospatial        │
│                    │  (Heavy Processing)     │    processing,        │
│                    │                         │    analytics          │
│                    │                         │                      │
│                    │  Oracle Autonomous DB   │◄── Analytics,        │
│                    │  (Analytics/Reporting)  │    settlement,        │
│                    │                         │    reporting           │
│                    └─────────────────────────┘                      │
│                                                                     │
│                    ┌─────────────────────────┐                      │
│                    │   EXTERNAL SERVICES     │                      │
│                    ├─────────────────────────┤                      │
│                    │  WhatsApp Business API  │◄── OTP Verification  │
│                    │  Google Maps SDK        │◄── Maps, Geocoding   │
│                    │  Payment Gateway        │◄── Midtrans/Xendit   │
│                    │  (Future)               │    (masa depan)       │
│                    └─────────────────────────┘                      │
│                                                                     │
│                    ┌─────────────────────────┐                      │
│                    │   DOMAIN (GitHub EDU)   │                      │
│                    ├─────────────────────────┤                      │
│                    │  rideon.id              │◄── Landing Page      │
│                    │  admin.rideon.id        │◄── Admin Dashboard   │
│                    │  link.rideon.id         │◄── Deep Links        │
│                    └─────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Flow Interaksi Antar-App

### 4.1 FlexRide Flow

```
Customer                    Firebase                     Driver
   │                           │                            │
   ├─ Pesan FlexRide ─────────►│                            │
   │  (pickup, destination,    │                            │
   │   vehicle type)           │                            │
   │                           ├─ Cari driver terdekat ────►│
   │                           │  (geospatial query)        │
   │                           │                            │
   │                           │◄─ Driver terima order ─────┤
   │                           │   (geser dalam 16 detik)   │
   │◄─ Driver ditemukan ───────┤                            │
   │                           │                            │
   │◄─── Real-time tracking ──►│◄──── Update lokasi GPS ───┤
   │     (Realtime DB)         │      (setiap 3-5 detik)   │
   │                           │                            │
   │◄─── Chat/Call ───────────►│◄──── Chat/Call ───────────┤
   │                           │                            │
   │◄─ Driver sampai ─────────┤──── Status: arrived ──────┤
   │                           │                            │
   │◄─ Trip selesai ──────────┤──── Status: completed ────┤
   │                           │                            │
   ├─ Rating driver ──────────►│                            │
   │                           │◄─ Rating customer ────────┤
```

### 4.2 FlexFood Flow

```
Customer              Firebase              Driver                Toko
   │                     │                     │                    │
   ├─ Pesan makanan ────►│                     │                    │
   │  (toko, items,      │                     │                    │
   │   catatan)          │                     │                    │
   │                     ├─ Order masuk ───────────────────────────►│
   │                     │                     │                    │
   │                     │◄──────────────── Terima order ──────────┤
   │                     │                     │    (status: dimasak)
   │◄─ Status: dimasak ──┤                     │                    │
   │                     │                     │                    │
   │                     │◄──────────────── Makanan siap ──────────┤
   │                     │                     │    (status: siap)   │
   │                     ├─ Cari driver ──────►│                    │
   │                     │                     │                    │
   │                     │◄─ Driver terima ────┤                    │
   │◄─ Kurir ditemukan ──┤                     │                    │
   │                     │                     │                    │
   │                     │  Driver ke toko ────┤───► Ambil pesanan  │
   │                     │                     │◄─── Serahkan       │
   │                     │                     │                    │
   │◄─── Tracking ───────┤◄── Update lokasi ──┤                    │
   │                     │                     │                    │
   │◄─ Pesanan sampai ───┤─── Selesai ────────┤──── Selesai ──────┤
   │                     │                     │                    │
   ├─ Rating driver ─────►│                     │                    │
   ├─ Rating toko ───────►│                     │                    │
```

### 4.3 FlexSend Flow

```
Customer              Firebase              Driver
   │                     │                     │
   ├─ Titip belanja ────►│                     │
   │  (list toko+item,   │                     │
   │   estimasi talangan) │                     │
   │                     ├─ Cari driver ──────►│
   │                     │  (filter: modal kas │
   │                     │   ≥ estimasi)       │
   │                     │                     │
   │                     │◄─ Driver terima ────┤
   │◄─ Driver ditemukan ─┤                     │
   │                     │                     │
   │◄─── Tracking ───────┤◄── Belanja ────────┤
   │     (live update)   │    (update item     │
   │                     │     status per toko) │
   │                     │                     │
   │◄─ Pengantaran ──────┤◄── Antar barang ───┤
   │                     │                     │
   │◄─ Selesai ──────────┤─── Selesai ────────┤
   │  (bayar ongkir +    │    (refund talangan │
   │   talangan)         │     ke dompet)      │
```

---

## 5. Tema Warna Resmi (Design Token)

Digunakan konsisten di semua app:

| Token | Hex | Penggunaan |
|-------|-----|------------|
| Primary Purple | `#6B48FC` | CTA, accent, brand color |
| Container Pale Purple | `#C6BCFF` | Card background, container |
| Dark Navy / Ink | `#17152B` | Text utama, button dark |
| Success Green | `#16A34A` | Status online, pickup marker |
| Error Red | `#E11D48` | Error state, transaksi keluar |
| Warning Gold | `#FFB800` | Area sibuk, warning |
| Splash Gradient | `#6B48FC` → `#C6BCFF` | Header gradient |

---

## 6. Keputusan Arsitektur (ADR Summary)

| # | Keputusan | Pilihan | Alasan |
|---|-----------|---------|--------|
| 1 | Database utama | Firestore + Realtime DB | Firestore untuk data struktural, RTDB untuk lokasi/chat/presence |
| 2 | Auth | Firebase Auth + WA Business API | Email/password + OTP WhatsApp, lebih murah dari SMS |
| 3 | File storage | Cloud Storage + Oracle Object Storage | CS untuk media ringan, Oracle untuk dokumen verifikasi besar |
| 4 | Geospatial | Oracle Cloud Functions | Oracle Spatial lebih powerful dari GeoHash Firebase |
| 5 | Analytics | Oracle Autonomous DB | Settlement harian, laporan omzet, statistik platform |
| 6 | Firebase project | Single project, 3 app + 1 web | Shared database, auth, functions — dibedakan via security rules |
| 7 | Pembayaran | COD + E-wallet internal + Payment gateway (future) | Mulai COD, database sudah support multi-payment |
| 8 | Pricing | Dinamis per-km + surge pricing | Base fare + per-km + surge multiplier per zona/waktu |
| 9 | Notifikasi | FCM + Realtime DB listener | Push saat background, RTDB listener saat foreground |
| 10 | Admin | Web dashboard (Next.js + Firebase Hosting) | Kontrol pusat: verifikasi, settlement, monitor, tarif |
| 11 | Domain | GitHub Student domain (rideon.id) | Admin dashboard + landing page + deep links |
| 12 | Rating | Multi-arah | Customer↔Driver, Customer→Toko, Toko→Driver |
