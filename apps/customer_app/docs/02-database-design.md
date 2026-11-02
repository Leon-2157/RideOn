# RideOn — Database Design Document

> **Project**: RideOn Platform
> **Versi**: 1.0.0
> **Tanggal**: 28 Oktober 2026
> **Database**: Cloud Firestore (primary) + Firebase Realtime Database (real-time)

---

## Daftar Isi

1. [Konvensi Penamaan](#1-konvensi-penamaan)
2. [User Roles & Authentication](#2-user-roles--authentication)
3. [Firestore Collections](#3-firestore-collections)
4. [Realtime Database Structure](#4-realtime-database-structure)
5. [Cloud Storage Structure](#5-cloud-storage-structure)
6. [Oracle Cloud Storage Structure](#6-oracle-cloud-storage-structure)
7. [Indexes yang Dibutuhkan](#7-indexes-yang-dibutuhkan)
8. [Security Rules Outline](#8-security-rules-outline)
9. [Cloud Functions yang Dibutuhkan](#9-cloud-functions-yang-dibutuhkan)
10. [Data Migration & Backup Strategy](#10-data-migration--backup-strategy)

---

## 1. Konvensi Penamaan

| Elemen | Konvensi | Contoh |
|--------|----------|--------|
| Collection | `camelCase` | `users`, `orders`, `menuItems` |
| Document ID | Auto-generated atau semantic | `uid` dari Auth, `orderId` generated |
| Field | `camelCase` | `firstName`, `createdAt`, `isOnline` |
| Timestamp | Firestore `Timestamp` | `Timestamp.now()` |
| Enum/Status | `UPPER_SNAKE_CASE` string | `"PENDING"`, `"IN_PROGRESS"` |
| Geolocation | Firestore `GeoPoint` | `GeoPoint(5.1801, 97.1507)` |
| Currency | Integer (dalam Rupiah, tanpa desimal) | `14000` (bukan `14000.00`) |

---

## 2. User Roles & Authentication

### 2.1 Firebase Auth

Satu Firebase Auth pool untuk semua user. Role disimpan di Firestore, bukan di Auth custom claims (kecuali untuk admin).

```
Firebase Auth User
├── uid: string (auto-generated)
├── email: string
├── password: hashed (managed by Firebase)
├── emailVerified: boolean
├── disabled: boolean
└── customClaims: { role: "admin" }  ← Hanya untuk admin
```

### 2.2 Role Matrix

| Role | App | Registrasi | Verifikasi |
|------|-----|------------|------------|
| `CUSTOMER` | customer_app | Self-register (email + OTP WA) | Otomatis aktif |
| `DRIVER` | driver_app | Self-register (9 step) | Manual oleh admin |
| `STORE_OWNER` | page_toko | Self-register (2 step) | Manual oleh admin |
| `ADMIN` | admin_dashboard | Dibuat manual di Firebase Console | Custom claim |

---

## 3. Firestore Collections

### 3.1 Collection Map (Overview)

```
firestore-root/
├── users/                    ← Semua user (customer, driver, toko owner)
├── driverProfiles/           ← Data spesifik driver (kendaraan, dokumen, level)
├── storeProfiles/            ← Data spesifik toko (menu, jam operasional)
├── orders/                   ← Semua order (FlexRide, FlexFood, FlexSend)
│   └── {orderId}/items/      ← Sub-collection untuk item pesanan
├── menuItems/                ← Katalog menu semua toko
├── transactions/             ← Transaksi keuangan (dompet driver, toko)
├── wallets/                  ← Saldo dompet (driver & toko)
├── bankAccounts/             ← Rekening bank (driver & toko)
├── withdrawals/              ← Request penarikan dana
├── ratings/                  ← Rating & review
├── promotions/               ← Promo, voucher, kode diskon
├── referrals/                ← Referral program
├── favorites/                ← Bookmark toko/menu oleh customer
├── pricingRules/             ← Aturan tarif per layanan & zona
├── surgeZones/               ← Zona surge pricing aktif
├── verificationRequests/     ← Antrian verifikasi dokumen driver/toko
├── disputes/                 ← Klaim dana / dispute
├── notifications/            ← Riwayat notifikasi
├── appConfig/                ← Konfigurasi global platform
└── driverLevels/             ← Definisi tier driver (bronze, silver, gold)
```

---

### 3.2 `users` Collection

Menyimpan data dasar semua user, terlepas dari role.

```
users/{uid}
{
  // === Identitas ===
  uid: string,                    // Firebase Auth UID
  email: string,                  // Email login
  phone: string,                  // Nomor WhatsApp (format: "628xxx")
  phoneVerified: boolean,         // Status verifikasi OTP WA
  role: string,                   // "CUSTOMER" | "DRIVER" | "STORE_OWNER"
  
  // === Profil ===
  firstName: string,              // Nama depan
  lastName: string,               // Nama belakang
  displayName: string,            // Nama tampilan (firstName + lastName)
  photoUrl: string,               // URL foto profil (Cloud Storage)
  
  // === Alamat Tersimpan (Customer) ===
  savedAddresses: [               // Maks 5 alamat favorit
    {
      label: string,              // "Rumah", "Kantor", "Mall Centre"
      address: string,            // Alamat lengkap
      location: GeoPoint,         // Koordinat
      icon: string,               // "home" | "office" | "shopping" | "custom"
    }
  ],
  
  // === Preferensi ===
  themeMode: string,              // "LIGHT" | "DARK" | "SYSTEM"
  language: string,               // "id" (default)
  fcmTokens: [string],            // Firebase Cloud Messaging tokens (multi-device)
  
  // === Referral ===
  referralCode: string,           // Kode referral unik user ini
  referredBy: string | null,      // UID user yang mereferensikan
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastLoginAt: Timestamp,
  isActive: boolean,              // Soft delete flag
  
  // === Statistik (denormalized) ===
  totalOrders: number,            // Total pesanan (customer) atau trip (driver)
  averageRating: number,          // Rata-rata rating (0.0 - 5.0)
  totalRatings: number,           // Jumlah rating yang diterima
}
```

---

### 3.3 `driverProfiles` Collection

Data spesifik driver, dipisah dari `users` agar query efisien.

```
driverProfiles/{uid}
{
  uid: string,                    // Sama dengan users/{uid}
  
  // === Status Driver ===
  verificationStatus: string,     // "PENDING" | "VERIFIED" | "REJECTED" | "SUSPENDED"
  isOnline: boolean,              // Sedang aktif mencari orderan
  currentOrderId: string | null,  // Order yang sedang dikerjakan
  
  // === Data Kendaraan ===
  vehicle: {
    type: string,                 // "MOTOR" | "MOBIL"
    brand: string,                // "Honda Beat", "Toyota Avanza"
    model: string,                // Model/tahun
    color: string,                // Warna kendaraan
    plateNumber: string,          // Nomor polisi (e.g., "BK 4892 ABC")
    year: number,                 // Tahun kendaraan
  },
  
  // === Dokumen Verifikasi (URL ke Oracle Object Storage) ===
  documents: {
    sim: {
      url: string,                // URL dokumen SIM
      status: string,             // "PENDING" | "APPROVED" | "REJECTED"
      uploadedAt: Timestamp,
      reviewedAt: Timestamp | null,
      reviewNote: string | null,  // Catatan reviewer jika ditolak
    },
    stnk: {
      url: string,
      status: string,
      uploadedAt: Timestamp,
      reviewedAt: Timestamp | null,
      reviewNote: string | null,
    },
    skck: {
      url: string,
      status: string,
      uploadedAt: Timestamp,
      reviewedAt: Timestamp | null,
      reviewNote: string | null,
    },
    vehiclePhoto: {
      url: string,
      status: string,
      uploadedAt: Timestamp,
      reviewedAt: Timestamp | null,
      reviewNote: string | null,
    },
    selfieWithKtp: {
      url: string,
      status: string,
      uploadedAt: Timestamp,
      reviewedAt: Timestamp | null,
      reviewNote: string | null,
    },
  },
  
  // === Dompet (denormalized dari wallets collection) ===
  walletBalance: number,          // Saldo aktif (Rupiah)
  modalKas: number,               // Batas modal kas untuk FlexSend
  
  // === Level / Tier Driver ===
  level: string,                  // "BRONZE" | "SILVER" | "GOLD" | "PLATINUM"
  levelPoints: number,            // Poin akumulasi untuk naik level
  
  // === Statistik ===
  stats: {
    totalTrips: number,           // Total trip selesai
    totalEarnings: number,        // Total pendapatan sepanjang waktu
    todayTrips: number,           // Trip hari ini
    todayEarnings: number,        // Pendapatan hari ini
    acceptanceRate: number,       // Persentase order diterima (0.0-1.0)
    completionRate: number,       // Persentase order diselesaikan (0.0-1.0)
    averageRating: number,        // Rating rata-rata
    cancelCount: number,          // Jumlah pembatalan
  },
  
  // === Layanan yang Diaktifkan ===
  enabledServices: [string],      // ["FLEX_RIDE", "FLEX_FOOD", "FLEX_SEND"]
  
  // === Metadata ===
  registeredAt: Timestamp,
  verifiedAt: Timestamp | null,
  lastOnlineAt: Timestamp,
}
```

---

### 3.4 `storeProfiles` Collection

Data spesifik toko mitra.

```
storeProfiles/{storeId}
{
  storeId: string,                // Auto-generated
  ownerUid: string,               // UID pemilik toko di users collection
  
  // === Informasi Toko ===
  storeName: string,              // Nama toko/resto
  description: string,            // Deskripsi singkat
  storePhoto: string,             // URL foto toko utama
  bannerPhoto: string | null,     // URL banner toko (opsional)
  category: string,               // "MAKANAN" | "MINUMAN" | "MAKANAN_MINUMAN"
  tags: [string],                 // ["Indonesian", "Fast Food", "Halal"]
  
  // === Lokasi ===
  address: string,                // Alamat lengkap
  location: GeoPoint,             // Koordinat pinpoint
  geohash: string,                // GeoHash untuk proximity query
  
  // === Status ===
  verificationStatus: string,     // "PENDING" | "VERIFIED" | "REJECTED" | "SUSPENDED"
  isOpen: boolean,                // Toggle buka/tutup manual
  isAutoOpen: boolean,            // Auto buka berdasar jam operasional
  
  // === Jam Operasional ===
  operatingHours: {
    monday:    { open: string, close: string, isOpen: boolean },  // "08:00", "22:00"
    tuesday:   { open: string, close: string, isOpen: boolean },
    wednesday: { open: string, close: string, isOpen: boolean },
    thursday:  { open: string, close: string, isOpen: boolean },
    friday:    { open: string, close: string, isOpen: boolean },
    saturday:  { open: string, close: string, isOpen: boolean },
    sunday:    { open: string, close: string, isOpen: boolean },
  },
  
  // === Dokumen Verifikasi (URL ke Oracle Object Storage) ===
  documents: {
    stnk: { url: string, status: string, uploadedAt: Timestamp },
    bankStatement: { url: string, status: string, uploadedAt: Timestamp },
    skck: { url: string, status: string, uploadedAt: Timestamp },
    storePhotos: [                // Foto-foto tempat usaha
      { url: string, uploadedAt: Timestamp }
    ],
  },
  
  // === Keuangan (denormalized) ===
  walletBalance: number,          // Saldo aktif toko
  
  // === Statistik (denormalized) ===
  stats: {
    totalOrders: number,          // Total pesanan diterima
    todayOrders: number,          // Pesanan hari ini
    todayRevenue: number,         // Omzet hari ini
    totalRevenue: number,         // Total omzet
    averageRating: number,        // Rating rata-rata
    totalRatings: number,         // Jumlah rating
    totalMenuItems: number,       // Jumlah item menu aktif
  },
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
  verifiedAt: Timestamp | null,
}
```

---

### 3.5 `orders` Collection

Collection terbesar dan terpenting — menyimpan semua jenis order.

```
orders/{orderId}
{
  orderId: string,                // Auto-generated
  orderNumber: string,            // Human-readable (e.g., "I2E4S68")
  
  // === Tipe Order ===
  serviceType: string,            // "FLEX_RIDE" | "FLEX_FOOD" | "FLEX_SEND"
  
  // === Aktor ===
  customerId: string,             // UID customer
  driverId: string | null,        // UID driver (null saat mencari)
  storeId: string | null,         // storeId (hanya untuk FLEX_FOOD & FLEX_SEND)
  
  // === Status ===
  status: string,                 // Lihat State Machine di bawah
  statusHistory: [                // Log perubahan status
    {
      status: string,
      timestamp: Timestamp,
      actor: string,              // UID yang mengubah
      note: string | null,
    }
  ],
  
  // === Lokasi ===
  pickup: {
    address: string,              // Alamat jemput
    location: GeoPoint,           // Koordinat jemput
    note: string | null,          // Patokan jemput ("Didepan Mesjid Al-Munawarah")
  },
  destination: {
    address: string,              // Alamat tujuan
    location: GeoPoint,           // Koordinat tujuan
  },
  
  // === Jarak & Waktu ===
  distance: {
    pickupToDestination: number,  // Jarak km (e.g., 2.9)
    driverToPickup: number,       // Jarak driver ke titik jemput (e.g., 2.9)
  },
  estimatedDuration: number,      // Estimasi menit (e.g., 25)
  
  // === FlexRide Specific ===
  vehicleType: string | null,     // "MOTOR" | "MOBIL" (hanya FLEX_RIDE)
  
  // === FlexFood Specific ===
  // Items disimpan di sub-collection orders/{orderId}/items
  storeNote: string | null,       // Catatan untuk toko
  
  // === FlexSend Specific ===
  sendType: string | null,        // "TITIP_BELANJA" | "KIRIM_BARANG"
  estimatedAdvance: number | null,// Estimasi talangan driver (e.g., 180000)
  actualAdvance: number | null,   // Talangan aktual setelah belanja
  // Items disimpan di sub-collection orders/{orderId}/items
  
  // === Pricing ===
  pricing: {
    baseFare: number,             // Tarif dasar
    perKmRate: number,            // Tarif per km
    distanceFare: number,         // baseFare + (perKmRate × distance)
    surgeMultiplier: number,      // Surge multiplier (1.0 = normal)
    surgeFare: number,            // Tambahan karena surge
    platformFee: number,          // Fee platform/admin
    driverEarnings: number,       // Pendapatan bersih driver
    subtotal: number,             // Subtotal sebelum promo
    discountAmount: number,       // Potongan dari promo/voucher
    totalAmount: number,          // Total yang dibayar customer
  },
  
  // === Pembayaran ===
  payment: {
    method: string,               // "CASH" | "E_WALLET" | "PAYMENT_GATEWAY"
    status: string,               // "PENDING" | "PAID" | "REFUNDED"
    paidAt: Timestamp | null,
    transactionId: string | null, // ID transaksi payment gateway
  },
  
  // === Promo ===
  promoCode: string | null,       // Kode promo yang digunakan
  promoId: string | null,         // ID promo dari promotions collection
  
  // === Countdown Driver ===
  driverAssignment: {
    offeredAt: Timestamp | null,  // Kapan order ditawarkan ke driver
    expiresAt: Timestamp | null,  // Batas waktu terima (offeredAt + 16-18 detik)
    respondedAt: Timestamp | null,// Kapan driver merespons
    response: string | null,      // "ACCEPTED" | "REJECTED" | "EXPIRED"
    rejectedDriverIds: [string],  // Driver yang sudah menolak/timeout
  },
  
  // === Rating (denormalized) ===
  customerRatingToDriver: number | null,   // 1-5
  customerRatingToStore: number | null,     // 1-5 (FLEX_FOOD)
  driverRatingToCustomer: number | null,   // 1-5
  storeRatingToDriver: number | null,      // 1-5 (FLEX_FOOD)
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
  completedAt: Timestamp | null,
  cancelledAt: Timestamp | null,
  cancelReason: string | null,
  cancelledBy: string | null,     // "CUSTOMER" | "DRIVER" | "STORE" | "SYSTEM"
}
```

### 3.5.1 Sub-collection: `orders/{orderId}/items`

Untuk FlexFood dan FlexSend.

```
orders/{orderId}/items/{itemId}
{
  itemId: string,
  
  // === FlexFood Item ===
  menuItemId: string | null,      // Referensi ke menuItems collection
  name: string,                   // Nama item
  quantity: number,               // Jumlah
  unitPrice: number,              // Harga satuan
  totalPrice: number,             // quantity × unitPrice
  note: string | null,            // Catatan khusus ("Pedas level 5")
  
  // === FlexSend Item ===
  storeName: string | null,       // Nama toko belanja (FlexSend)
  storeAddress: string | null,    // Alamat toko
  itemDescription: string | null, // Deskripsi barang yang dititipkan
  estimatedPrice: number | null,  // Estimasi harga
  actualPrice: number | null,     // Harga aktual setelah dibeli
  
  // === Status ===
  status: string,                 // "PENDING" | "PREPARING" | "READY" | "PICKED_UP"
}
```

### 3.5.2 Order State Machine

```
┌────────────────────────────────────────────────────────────────────────┐
│                    ORDER STATUS STATE MACHINE                          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────┐                                                          │
│  │ CREATED  │ ← Customer submit order                                  │
│  └────┬─────┘                                                          │
│       │                                                                │
│       ▼                                                                │
│  ┌───────────────────┐                                                 │
│  │ SEARCHING_DRIVER  │ ← Mencari driver terdekat                       │
│  └────┬──────────────┘                                                 │
│       │                                                                │
│       ├──────────────────────────────────┐                             │
│       ▼                                  ▼                             │
│  ┌──────────────────┐          ┌──────────────────┐                    │
│  │ DRIVER_ASSIGNED  │          │ NO_DRIVER_FOUND  │ → CANCELLED        │
│  └────┬─────────────┘          └──────────────────┘                    │
│       │                                                                │
│       │ ─── FlexRide ───────────────────────────────┐                 │
│       │                                              │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ DRIVER_EN_ROUTE  │ ← Driver menuju pickup         │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ DRIVER_ARRIVED   │ ← Driver sampai di pickup      │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ IN_PROGRESS      │ ← Trip berjalan / dalam perjalanan │            │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ COMPLETED        │ ← Sampai tujuan / selesai      │                 │
│  └──────────────────┘                                │                 │
│                                                      │                 │
│       │ ─── FlexFood ───────────────────────────────┤                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ WAITING_STORE    │ ← Menunggu toko terima         │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ STORE_PREPARING  │ ← Toko sedang memasak          │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ STORE_READY      │ ← Makanan siap, cari driver    │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ DRIVER_TO_STORE  │ ← Driver menuju toko           │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ DRIVER_AT_STORE  │ ← Driver di toko, ambil pesanan│                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ DELIVERING       │ ← Driver antar ke customer     │                 │
│  └────┬─────────────┘                                │                 │
│       ▼                                              │                 │
│  ┌──────────────────┐                                │                 │
│  │ COMPLETED        │                                │                 │
│  └──────────────────┘                                │                 │
│                                                      │                 │
│       │ ─── FlexSend ───────────────────────────────┘                 │
│       ▼                                                                │
│  ┌──────────────────┐                                                  │
│  │ DRIVER_SHOPPING  │ ← Driver belanja di toko-toko                    │
│  └────┬─────────────┘                                                  │
│       ▼                                                                │
│  ┌──────────────────┐                                                  │
│  │ DELIVERING       │ ← Driver antar barang belanjaan                  │
│  └────┬─────────────┘                                                  │
│       ▼                                                                │
│  ┌──────────────────┐                                                  │
│  │ COMPLETED        │                                                  │
│  └──────────────────┘                                                  │
│                                                                        │
│  ─── Dari status mana pun ──────────────────────────                   │
│       ▼                                                                │
│  ┌──────────────────┐                                                  │
│  │ CANCELLED        │ ← Dibatalkan oleh customer/driver/store/system   │
│  └──────────────────┘                                                  │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 3.6 `menuItems` Collection

Katalog menu dari semua toko.

```
menuItems/{menuItemId}
{
  menuItemId: string,
  storeId: string,                // Referensi ke storeProfiles
  
  // === Data Menu ===
  name: string,                   // Nama menu
  description: string | null,     // Deskripsi
  photoUrl: string | null,        // URL foto makanan (Cloud Storage)
  category: string,               // "Makanan" | "Minuman" | "Snack"
  
  // === Harga ===
  price: number,                  // Harga dalam Rupiah
  
  // === Ketersediaan ===
  isAvailable: boolean,           // Toggle stok (Aktif / Habis)
  
  // === Urutan Tampilan ===
  sortOrder: number,              // Untuk mengurutkan di katalog
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

---

### 3.7 `wallets` Collection

Dompet digital untuk driver dan toko.

```
wallets/{uid}
{
  uid: string,                    // UID pemilik (driver atau store owner)
  ownerType: string,             // "DRIVER" | "STORE"
  
  // === Saldo ===
  balance: number,                // Saldo aktif (Rupiah)
  pendingBalance: number,         // Saldo tertahan (menunggu settlement)
  totalEarnings: number,          // Total pendapatan sepanjang waktu
  totalWithdrawn: number,         // Total yang sudah ditarik
  
  // === Khusus Driver ===
  modalKasLimit: number | null,   // Batas modal kas untuk FlexSend
  pendingRefund: number | null,   // Talangan yang menunggu refund
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastTransactionAt: Timestamp | null,
}
```

---

### 3.8 `transactions` Collection

Riwayat semua transaksi keuangan.

```
transactions/{transactionId}
{
  transactionId: string,
  
  // === Pemilik ===
  walletId: string,               // UID pemilik wallet
  walletType: string,             // "DRIVER" | "STORE"
  
  // === Detail Transaksi ===
  type: string,                   // "EARNING" | "FEE" | "WITHDRAWAL" | "REFUND" | "ADVANCE" | "ADVANCE_RETURN" | "BONUS" | "PENALTY"
  direction: string,              // "IN" | "OUT"
  amount: number,                 // Jumlah (selalu positif, arah ditentukan direction)
  
  // === Referensi ===
  orderId: string | null,         // Order terkait
  orderNumber: string | null,     // Human-readable order number ("I2E4S68")
  description: string,            // Deskripsi ("Ongkos Kirim", "Fee admin")
  
  // === Saldo Setelah Transaksi ===
  balanceAfter: number,           // Saldo setelah transaksi ini
  
  // === Metadata ===
  createdAt: Timestamp,
}
```

---

### 3.9 `bankAccounts` Collection

Rekening bank untuk penarikan dana.

```
bankAccounts/{accountId}
{
  accountId: string,
  ownerUid: string,               // UID pemilik
  ownerType: string,              // "DRIVER" | "STORE"
  
  // === Data Bank ===
  bankName: string,               // "BCA", "BRI", "Mandiri", dll
  bankCode: string,               // Kode bank (untuk API transfer)
  accountNumber: string,          // Nomor rekening
  accountHolder: string,          // Nama pemegang rekening
  
  // === Status ===
  isDefault: boolean,             // Rekening default untuk penarikan
  isVerified: boolean,            // Sudah diverifikasi admin
  
  // === Metadata ===
  createdAt: Timestamp,
}
```

---

### 3.10 `withdrawals` Collection

Request penarikan dana dari dompet.

```
withdrawals/{withdrawalId}
{
  withdrawalId: string,
  walletId: string,               // UID pemilik wallet
  bankAccountId: string,          // Rekening tujuan
  
  // === Detail ===
  amount: number,                 // Jumlah penarikan
  fee: number,                    // Biaya admin (jika ada)
  netAmount: number,              // amount - fee
  
  // === Status ===
  status: string,                 // "PENDING" | "PROCESSING" | "COMPLETED" | "REJECTED"
  
  // === Verifikasi ===
  pinVerified: boolean,           // PIN/sandi sudah diverifikasi
  
  // === Metadata ===
  requestedAt: Timestamp,
  processedAt: Timestamp | null,
  completedAt: Timestamp | null,
  rejectedReason: string | null,
  processedBy: string | null,     // Admin UID yang memproses
}
```

---

### 3.11 `ratings` Collection

Rating multi-arah setelah order selesai.

```
ratings/{ratingId}
{
  ratingId: string,
  orderId: string,                // Order terkait
  
  // === Siapa Menilai Siapa ===
  fromUid: string,                // UID penilai
  fromRole: string,               // "CUSTOMER" | "DRIVER" | "STORE"
  toUid: string,                  // UID yang dinilai
  toRole: string,                 // "CUSTOMER" | "DRIVER" | "STORE"
  
  // === Rating ===
  score: number,                  // 1-5
  comment: string | null,         // Ulasan teks (opsional)
  tags: [string] | null,          // Tag cepat: ["Ramah", "Tepat Waktu", "Bersih"]
  
  // === Metadata ===
  createdAt: Timestamp,
}
```

---

### 3.12 `promotions` Collection

Promo, voucher, dan kode diskon.

```
promotions/{promoId}
{
  promoId: string,
  
  // === Info Promo ===
  code: string,                   // Kode promo (e.g., "RIDEON50")
  title: string,                  // "Diskon 50% FlexRide!"
  description: string,            // Deskripsi lengkap
  bannerUrl: string | null,       // Banner promo
  
  // === Tipe Diskon ===
  discountType: string,           // "PERCENTAGE" | "FIXED_AMOUNT"
  discountValue: number,          // 50 (50%) atau 15000 (Rp 15.000)
  maxDiscount: number | null,     // Maks potongan (untuk percentage)
  minOrderAmount: number,         // Minimum order
  
  // === Scope ===
  applicableServices: [string],   // ["FLEX_RIDE", "FLEX_FOOD", "FLEX_SEND"]
  
  // === Batasan ===
  totalQuota: number,             // Total penggunaan maks
  usedCount: number,              // Sudah dipakai berapa kali
  perUserLimit: number,           // Maks per user (default: 1)
  
  // === Periode ===
  startDate: Timestamp,
  endDate: Timestamp,
  isActive: boolean,
  
  // === Metadata ===
  createdAt: Timestamp,
  createdBy: string,              // Admin UID
}
```

---

### 3.13 `referrals` Collection

Tracking referral program.

```
referrals/{referralId}
{
  referralId: string,
  
  referrerUid: string,            // UID yang mengajak
  refereeUid: string,             // UID yang diajak
  referralCode: string,           // Kode yang digunakan
  
  // === Reward ===
  referrerReward: number,         // Bonus untuk pengajak (Rupiah)
  refereeReward: number,          // Bonus untuk yang diajak (Rupiah)
  referrerRewardClaimed: boolean, // Sudah diklaim
  refereeRewardClaimed: boolean,  // Sudah diklaim
  
  // === Syarat ===
  refereeFirstOrderCompleted: boolean,  // Syarat: yang diajak harus selesai order pertama
  
  // === Metadata ===
  createdAt: Timestamp,
  claimedAt: Timestamp | null,
}
```

---

### 3.14 `favorites` Collection

Bookmark toko dan menu oleh customer.

```
favorites/{favoriteId}
{
  favoriteId: string,
  customerUid: string,            // UID customer
  
  // === Target ===
  targetType: string,             // "STORE" | "MENU_ITEM"
  targetId: string,               // storeId atau menuItemId
  
  // === Denormalized Data (untuk tampilan cepat) ===
  targetName: string,             // Nama toko / nama menu
  targetPhoto: string | null,     // Foto
  targetStoreId: string | null,   // storeId (jika target = MENU_ITEM)
  
  // === Metadata ===
  createdAt: Timestamp,
}
```

---

### 3.15 `pricingRules` Collection

Aturan tarif dinamis per layanan dan zona.

```
pricingRules/{ruleId}
{
  ruleId: string,
  
  // === Scope ===
  serviceType: string,            // "FLEX_RIDE" | "FLEX_FOOD" | "FLEX_SEND"
  vehicleType: string | null,     // "MOTOR" | "MOBIL" (untuk FLEX_RIDE)
  
  // === Tarif ===
  baseFare: number,               // Tarif dasar (Rupiah)
  perKmRate: number,              // Per kilometer (Rupiah)
  minimumFare: number,            // Tarif minimum
  platformFeePercent: number,     // Persentase fee platform (e.g., 0.20 = 20%)
  platformFeeFixed: number,       // Fee platform tetap (jika ada)
  
  // === FlexSend Specific ===
  perItemRate: number | null,     // Tarif per item (FlexSend kuota item)
  
  // === Zona (opsional) ===
  zoneId: string | null,          // Berlaku untuk zona tertentu
  
  // === Periode ===
  isActive: boolean,
  effectiveFrom: Timestamp,
  effectiveTo: Timestamp | null,  // null = berlaku selamanya
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
  updatedBy: string,              // Admin UID
}
```

---

### 3.16 `surgeZones` Collection

Zona surge pricing aktif (area sibuk).

```
surgeZones/{zoneId}
{
  zoneId: string,
  
  // === Area ===
  centerLocation: GeoPoint,      // Pusat zona
  radiusKm: number,              // Radius zona (km)
  geohash: string,               // GeoHash untuk query
  name: string,                  // "Area Sibuk - Jl. Nisam"
  
  // === Surge ===
  surgeMultiplier: number,        // 1.5 = 50% lebih mahal, 2.0 = 2x lipat
  reason: string,                 // "HIGH_DEMAND" | "LOW_SUPPLY" | "WEATHER" | "EVENT"
  
  // === Status ===
  isActive: boolean,
  activatedAt: Timestamp,
  expiresAt: Timestamp | null,    // Auto-deactivate
  
  // === Metadata ===
  createdBy: string,              // "SYSTEM" (auto) atau Admin UID (manual)
}
```

---

### 3.17 `verificationRequests` Collection

Antrian verifikasi dokumen untuk admin review.

```
verificationRequests/{requestId}
{
  requestId: string,
  
  // === Pemohon ===
  applicantUid: string,           // UID driver/toko owner
  applicantType: string,          // "DRIVER" | "STORE"
  applicantName: string,          // Nama pemohon
  
  // === Status ===
  status: string,                 // "PENDING" | "IN_REVIEW" | "APPROVED" | "REJECTED"
  
  // === Review ===
  reviewedBy: string | null,      // Admin UID
  reviewedAt: Timestamp | null,
  reviewNote: string | null,      // Catatan admin
  rejectionReasons: [string] | null,  // Alasan penolakan spesifik per dokumen
  
  // === Metadata ===
  submittedAt: Timestamp,
  updatedAt: Timestamp,
}
```

---

### 3.18 `disputes` Collection

Klaim dana dan penyelesaian sengketa.

```
disputes/{disputeId}
{
  disputeId: string,
  
  // === Order Terkait ===
  orderId: string,
  orderNumber: string,
  
  // === Pelapor ===
  reporterUid: string,
  reporterRole: string,           // "CUSTOMER" | "DRIVER" | "STORE"
  
  // === Detail ===
  type: string,                   // "CANCEL_FRAUD" | "ITEM_MISSING" | "QUALITY_ISSUE" | "OVERCHARGE" | "OTHER"
  title: string,                  // "Customer Batalkan/Penipuan Belanjaan"
  description: string,            // Penjelasan detail
  evidence: [string],             // URL foto bukti
  
  // === Klaim ===
  claimedAmount: number,          // Jumlah yang diklaim
  approvedAmount: number | null,  // Jumlah yang disetujui
  
  // === Status ===
  status: string,                 // "OPEN" | "IN_REVIEW" | "RESOLVED" | "REJECTED"
  resolution: string | null,      // "REFUND" | "PARTIAL_REFUND" | "NO_ACTION"
  
  // === Admin ===
  assignedTo: string | null,      // Admin UID yang menangani
  resolvedAt: Timestamp | null,
  resolvedNote: string | null,
  
  // === Metadata ===
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

---

### 3.19 `driverLevels` Collection

Definisi tier/level driver.

```
driverLevels/{levelId}
{
  levelId: string,                // "BRONZE" | "SILVER" | "GOLD" | "PLATINUM"
  
  // === Info Level ===
  name: string,                   // "Bronze", "Silver", "Gold", "Platinum"
  minPoints: number,              // Minimum poin untuk level ini
  maxPoints: number | null,       // Maks poin (null = unlimited untuk level tertinggi)
  
  // === Benefit ===
  benefits: {
    priorityOrder: boolean,       // Dapat orderan duluan
    reducedFee: number,           // Pengurangan fee platform (e.g., 0.02 = 2%)
    bonusMultiplier: number,      // Bonus penghasilan (e.g., 1.1 = 10% bonus)
    badgeColor: string,           // Warna badge di app
  },
  
  // === Aturan Poin ===
  pointRules: {
    perCompletedTrip: number,     // Poin per trip selesai
    perFiveStarRating: number,    // Poin per rating 5 bintang
    perConsecutiveDay: number,    // Poin per hari berturut-turut online
  },
  
  // === Metadata ===
  updatedAt: Timestamp,
  updatedBy: string,              // Admin UID
}
```

---

### 3.20 `appConfig` Collection

Konfigurasi global platform (document tunggal atau beberapa dokumen tematik).

```
appConfig/general
{
  // === Platform ===
  platformName: string,           // "RideOn"
  platformVersion: string,        // "1.0.0"
  maintenanceMode: boolean,       // Mode maintenance
  maintenanceMessage: string | null,
  
  // === Order ===
  driverSearchTimeoutSeconds: number,  // Batas waktu cari driver (e.g., 120)
  driverOfferTimeoutSeconds: number,   // Countdown terima order (e.g., 16)
  maxRejectedDriversBeforeCancel: number, // Maks driver tolak sebelum cancel (e.g., 5)
  
  // === Referral ===
  referralEnabled: boolean,
  referrerRewardAmount: number,   // Bonus untuk pengajak
  refereeRewardAmount: number,    // Bonus untuk yang diajak
  
  // === Penarikan ===
  minWithdrawalAmount: number,    // Minimum penarikan (e.g., 50000)
  withdrawalFee: number,          // Biaya penarikan (e.g., 2500)
  
  // === Metadata ===
  updatedAt: Timestamp,
  updatedBy: string,
}
```

---

## 4. Realtime Database Structure

Realtime Database digunakan khusus untuk data yang membutuhkan latensi sangat rendah dan frekuensi update tinggi.

```
realtime-db-root/
│
├── driverLocations/              ← GPS driver real-time
│   └── {uid}/
│       ├── latitude: number      // e.g., 5.1801
│       ├── longitude: number     // e.g., 97.1507
│       ├── heading: number       // Arah hadap (0-360 derajat)
│       ├── speed: number         // Kecepatan km/h
│       ├── accuracy: number      // Akurasi GPS (meter)
│       ├── geohash: string       // GeoHash untuk proximity query
│       ├── isOnline: boolean     // Status online
│       ├── currentService: string // "FLEX_RIDE" | "FLEX_FOOD" | "FLEX_SEND" | null
│       ├── vehicleType: string   // "MOTOR" | "MOBIL"
│       └── updatedAt: number     // Unix timestamp (ms)
│
├── orderTracking/                ← Live tracking order aktif
│   └── {orderId}/
│       ├── driverLocation/
│       │   ├── latitude: number
│       │   ├── longitude: number
│       │   ├── heading: number
│       │   └── updatedAt: number
│       ├── status: string        // Status order terkini
│       ├── eta: number           // Estimasi menit sampai
│       └── updatedAt: number
│
├── presence/                     ← Online/offline presence
│   └── {uid}/
│       ├── isOnline: boolean
│       ├── lastSeen: number      // Unix timestamp
│       └── deviceInfo: string    // "Android 14, customer_app v1.0"
│
├── chats/                        ← Real-time messaging
│   └── {chatId}/                 // chatId = orderId (1 order = 1 chat room)
│       ├── metadata/
│       │   ├── orderId: string
│       │   ├── participants/
│       │   │   ├── {uid1}: true
│       │   │   └── {uid2}: true
│       │   ├── lastMessage: string
│       │   ├── lastMessageAt: number
│       │   └── createdAt: number
│       └── messages/
│           └── {messageId}/
│               ├── senderId: string
│               ├── senderName: string
│               ├── type: string      // "TEXT" | "IMAGE" | "CALL_LOG"
│               ├── content: string    // Teks pesan atau URL gambar
│               ├── callDuration: number | null  // Durasi panggilan (detik)
│               ├── callStatus: string | null    // "MISSED" | "ANSWERED" | "ENDED"
│               ├── isRead: boolean
│               └── timestamp: number
│
├── notifications/                ← In-app notifications real-time
│   └── {uid}/
│       └── {notificationId}/
│           ├── type: string      // "NEW_ORDER" | "ORDER_UPDATE" | "PROMO" | "SYSTEM"
│           ├── title: string
│           ├── body: string
│           ├── data: object      // Payload tambahan (orderId, etc.)
│           ├── isRead: boolean
│           └── timestamp: number
│
└── orderOffers/                  ← Order yang ditawarkan ke driver (countdown)
    └── {uid}/                    // UID driver
        └── {orderId}/
            ├── orderId: string
            ├── serviceType: string
            ├── customerName: string
            ├── pickupAddress: string
            ├── destinationAddress: string
            ├── distance: number
            ├── estimatedEarnings: number
            ├── estimatedAdvance: number | null  // FlexSend
            ├── paymentMethod: string
            ├── expiresAt: number     // Unix timestamp batas waktu
            ├── offeredAt: number     // Unix timestamp ditawarkan
            └── storeInfo: object | null  // FlexFood: { storeName, storeAddress }
```

---

## 5. Cloud Storage Structure

Firebase Cloud Storage untuk media ringan dan sering diakses.

```
cloud-storage-root/
│
├── users/
│   └── {uid}/
│       ├── profile/
│       │   └── photo.jpg                 // Foto profil (max 2MB)
│       └── chat/
│           └── {orderId}/
│               └── {messageId}.jpg       // Foto dari chat
│
├── stores/
│   └── {storeId}/
│       ├── profile/
│       │   ├── store_photo.jpg           // Foto utama toko
│       │   └── banner.jpg               // Banner toko
│       └── menu/
│           └── {menuItemId}/
│               └── photo.jpg            // Foto menu
│
└── disputes/
    └── {disputeId}/
        └── evidence_{n}.jpg              // Bukti dispute
```

---

## 6. Oracle Cloud Storage Structure

Oracle Object Storage untuk dokumen verifikasi besar dan arsip.

```
oracle-object-storage/
│
├── bucket: rideon-verification-docs
│   ├── drivers/
│   │   └── {uid}/
│   │       ├── sim.pdf|jpg               // SIM driver
│   │       ├── stnk.pdf|jpg              // STNK kendaraan
│   │       ├── skck.pdf|jpg              // SKCK
│   │       ├── vehicle_photo.jpg         // Foto kendaraan
│   │       ├── selfie_ktp.jpg            // Selfie dengan KTP
│   │       └── metadata.json             // Info upload (timestamp, hash)
│   │
│   └── stores/
│       └── {storeId}/
│           ├── stnk.pdf|jpg              // STNK pemilik
│           ├── bank_statement.pdf|jpg    // Rekening bank
│           ├── skck.pdf|jpg              // SKCK pemilik
│           ├── store_photo_1.jpg         // Foto tempat usaha
│           ├── store_photo_2.jpg
│           └── metadata.json
│
├── bucket: rideon-analytics-exports
│   └── reports/
│       └── {year}/{month}/
│           ├── daily_settlement_{date}.json
│           ├── driver_performance_{date}.json
│           └── store_revenue_{date}.json
│
└── bucket: rideon-backups
    └── firestore/
        └── {date}/
            └── backup.json               // Firestore backup periodik
```

---

## 7. Indexes yang Dibutuhkan

### 7.1 Firestore Composite Indexes

```
┌────────────────────────────────────────────────────────────────────────┐
│ Collection        │ Fields                          │ Order            │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ orders            │ customerId, createdAt            │ ASC, DESC        │
│ orders            │ driverId, status                 │ ASC, ASC         │
│ orders            │ storeId, status                  │ ASC, ASC         │
│ orders            │ serviceType, status, createdAt   │ ASC, ASC, DESC   │
│ orders            │ driverId, createdAt              │ ASC, DESC        │
│ orders            │ storeId, createdAt               │ ASC, DESC        │
│ orders            │ customerId, serviceType, status  │ ASC, ASC, ASC    │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ transactions      │ walletId, createdAt              │ ASC, DESC        │
│ transactions      │ walletId, type, createdAt        │ ASC, ASC, DESC   │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ menuItems         │ storeId, isAvailable, sortOrder  │ ASC, ASC, ASC    │
│ menuItems         │ storeId, category, isAvailable   │ ASC, ASC, ASC    │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ ratings           │ toUid, createdAt                 │ ASC, DESC        │
│ ratings           │ orderId, fromRole                │ ASC, ASC         │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ favorites         │ customerUid, targetType          │ ASC, ASC         │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ promotions        │ isActive, startDate, endDate     │ ASC, ASC, ASC    │
│ promotions        │ code                             │ ASC              │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ verificationReqs  │ status, submittedAt              │ ASC, ASC         │
│ verificationReqs  │ applicantType, status            │ ASC, ASC         │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ disputes          │ status, createdAt                │ ASC, DESC        │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ withdrawals       │ walletId, status                 │ ASC, ASC         │
│ withdrawals       │ status, requestedAt              │ ASC, ASC         │
├───────────────────┼─────────────────────────────────┼──────────────────┤
│ storeProfiles     │ isOpen, geohash                  │ ASC, ASC         │
│ storeProfiles     │ verificationStatus, category     │ ASC, ASC         │
└────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Realtime Database Indexes

```json
{
  "rules": {
    "driverLocations": {
      ".indexOn": ["geohash", "isOnline", "vehicleType"]
    },
    "chats": {
      "$chatId": {
        "messages": {
          ".indexOn": ["timestamp"]
        }
      }
    },
    "notifications": {
      "$uid": {
        ".indexOn": ["timestamp", "isRead"]
      }
    },
    "orderOffers": {
      "$uid": {
        ".indexOn": ["expiresAt"]
      }
    }
  }
}
```

---

## 8. Security Rules Outline

### 8.1 Firestore Security Rules (Pseudocode)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // === Helper Functions ===
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(uid) {
      return request.auth.uid == uid;
    }
    
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    function isAdmin() {
      return request.auth.token.role == 'admin';
    }
    
    function isDriver() {
      return getUserRole() == 'DRIVER';
    }
    
    function isCustomer() {
      return getUserRole() == 'CUSTOMER';
    }
    
    function isStoreOwner() {
      return getUserRole() == 'STORE_OWNER';
    }
    
    // === Users ===
    match /users/{uid} {
      allow read: if isAuthenticated();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // === Driver Profiles ===
    match /driverProfiles/{uid} {
      allow read: if isAuthenticated();
      allow create: if isOwner(uid) && isDriver();
      allow update: if isOwner(uid) || isAdmin();
    }
    
    // === Store Profiles ===
    match /storeProfiles/{storeId} {
      allow read: if isAuthenticated();
      allow create: if isStoreOwner();
      allow update: if (isStoreOwner() && 
        resource.data.ownerUid == request.auth.uid) || isAdmin();
    }
    
    // === Orders ===
    match /orders/{orderId} {
      allow read: if isAuthenticated() && (
        resource.data.customerId == request.auth.uid ||
        resource.data.driverId == request.auth.uid ||
        resource.data.storeId in getUserStoreIds() ||
        isAdmin()
      );
      allow create: if isCustomer();
      allow update: if isAuthenticated();  // Cloud Functions handles validation
    }
    
    // === Menu Items ===
    match /menuItems/{itemId} {
      allow read: if isAuthenticated();
      allow write: if (isStoreOwner() && 
        resource.data.storeId in getUserStoreIds()) || isAdmin();
    }
    
    // === Wallets (read-only for owners, writes via Cloud Functions) ===
    match /wallets/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow write: if false;  // Hanya Cloud Functions yang boleh write
    }
    
    // === Transactions (read-only) ===
    match /transactions/{txId} {
      allow read: if resource.data.walletId == request.auth.uid || isAdmin();
      allow write: if false;  // Hanya Cloud Functions
    }
    
    // === Promotions ===
    match /promotions/{promoId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // === Favorites ===
    match /favorites/{favId} {
      allow read, write: if isAuthenticated() && 
        resource.data.customerUid == request.auth.uid;
    }
    
    // === App Config (read-only for apps) ===
    match /appConfig/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

### 8.2 Realtime Database Security Rules (Pseudocode)

```json
{
  "rules": {
    "driverLocations": {
      "$uid": {
        ".read": true,
        ".write": "$uid === auth.uid"
      }
    },
    "orderTracking": {
      "$orderId": {
        ".read": true,
        ".write": "auth != null"
      }
    },
    "presence": {
      "$uid": {
        ".read": true,
        ".write": "$uid === auth.uid"
      }
    },
    "chats": {
      "$chatId": {
        "metadata": {
          ".read": "data.child('participants').child(auth.uid).exists()",
          ".write": "auth != null"
        },
        "messages": {
          ".read": "root.child('chats').child($chatId).child('metadata').child('participants').child(auth.uid).exists()",
          ".write": "root.child('chats').child($chatId).child('metadata').child('participants').child(auth.uid).exists()"
        }
      }
    },
    "notifications": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null"
      }
    },
    "orderOffers": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null"
      }
    }
  }
}
```

### 8.3 Cloud Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // User profile photos
    match /users/{uid}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid
        && request.resource.size < 2 * 1024 * 1024  // Max 2MB
        && request.resource.contentType.matches('image/.*');
    }
    
    // Store media
    match /stores/{storeId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024  // Max 5MB
        && request.resource.contentType.matches('image/.*');
    }
    
    // Dispute evidence
    match /disputes/{disputeId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024;
    }
  }
}
```

---

## 9. Cloud Functions yang Dibutuhkan

### 9.1 Daftar Cloud Functions

```
┌──────────────────────────────────────────────────────────────────────────┐
│ #  │ Function Name              │ Trigger          │ Deskripsi          │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 1  │ onUserCreated              │ Auth onCreate    │ Buat dokumen user  │
│    │                            │                  │ di Firestore +     │
│    │                            │                  │ generate referral  │
│    │                            │                  │ code               │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 2  │ sendWhatsAppOTP            │ HTTPS Callable   │ Kirim OTP via WA   │
│    │                            │                  │ Business API       │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 3  │ verifyWhatsAppOTP          │ HTTPS Callable   │ Verifikasi kode    │
│    │                            │                  │ OTP yang diinput   │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 4  │ onOrderCreated             │ Firestore        │ Cari driver        │
│    │                            │ onCreate         │ terdekat, kirim    │
│    │                            │ (orders)         │ offer ke RTDB      │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 5  │ onOrderStatusChanged       │ Firestore        │ Kirim FCM ke       │
│    │                            │ onUpdate         │ customer/driver/   │
│    │                            │ (orders)         │ toko saat status   │
│    │                            │                  │ berubah            │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 6  │ processDriverResponse      │ HTTPS Callable   │ Driver terima/     │
│    │                            │                  │ tolak order,       │
│    │                            │                  │ update Firestore   │
│    │                            │                  │ + cari driver lain │
│    │                            │                  │ jika ditolak       │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 7  │ handleDriverOfferTimeout   │ Scheduled        │ Cek offer yang     │
│    │                            │ (setiap 5 detik) │ expired, cari      │
│    │                            │                  │ driver berikutnya  │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 8  │ onOrderCompleted           │ Firestore        │ Hitung fee, update │
│    │                            │ onUpdate         │ wallet driver/toko,│
│    │                            │ (orders.status   │ buat transaksi,    │
│    │                            │  == COMPLETED)   │ refund talangan    │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 9  │ calculatePricing           │ HTTPS Callable   │ Hitung tarif       │
│    │                            │                  │ dinamis + surge    │
│    │                            │                  │ berdasarkan jarak  │
│    │                            │                  │ dan zona           │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 10 │ processWithdrawal          │ HTTPS Callable   │ Proses penarikan   │
│    │                            │                  │ dana, verifikasi   │
│    │                            │                  │ PIN, kurangi saldo │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 11 │ processVerification        │ HTTPS Callable   │ Admin approve/     │
│    │                            │                  │ reject dokumen     │
│    │                            │                  │ driver/toko        │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 12 │ applyPromoCode             │ HTTPS Callable   │ Validasi & apply   │
│    │                            │                  │ kode promo ke      │
│    │                            │                  │ order              │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 13 │ processReferral            │ Firestore        │ Cek syarat referral│
│    │                            │ onUpdate         │ (order pertama     │
│    │                            │ (orders)         │ selesai), kasih    │
│    │                            │                  │ reward             │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 14 │ updateDriverLevel          │ Scheduled        │ Hitung ulang poin  │
│    │                            │ (harian)         │ & level driver     │
│    │                            │                  │ setiap hari        │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 15 │ dailySettlement            │ Scheduled        │ Settlement harian: │
│    │                            │ (00:00 WIB)      │ finalisasi         │
│    │                            │                  │ pendapatan,        │
│    │                            │                  │ reset counter      │
│    │                            │                  │ harian             │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 16 │ updateSurgeZones           │ Scheduled        │ Analisis demand/   │
│    │                            │ (setiap 5 menit) │ supply, update     │
│    │                            │                  │ zona surge         │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 17 │ syncToOracle               │ Scheduled        │ Sync data ke       │
│    │                            │ (harian)         │ Oracle Cloud DB    │
│    │                            │                  │ untuk analytics    │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 18 │ autoToggleStoreStatus      │ Scheduled        │ Auto buka/tutup    │
│    │                            │ (setiap menit)   │ toko berdasar jam  │
│    │                            │                  │ operasional        │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 19 │ resolveDispute             │ HTTPS Callable   │ Admin resolve      │
│    │                            │                  │ dispute, proses    │
│    │                            │                  │ refund jika perlu  │
├────┼────────────────────────────┼──────────────────┼────────────────────┤
│ 20 │ uploadToOracle             │ HTTPS Callable   │ Upload dokumen     │
│    │                            │                  │ verifikasi ke      │
│    │                            │                  │ Oracle Object      │
│    │                            │                  │ Storage            │
└────┴────────────────────────────┴──────────────────┴────────────────────┘
```

### 9.2 Function Dependencies

```
onUserCreated
  └── Buat users/{uid} + wallets/{uid} + generate referralCode

onOrderCreated
  ├── calculatePricing (get pricing rules + surge)
  ├── Query driverLocations (RTDB) untuk cari driver terdekat
  ├── Write orderOffers/{driverUid}/{orderId} (RTDB)
  └── Send FCM ke driver

processDriverResponse
  ├── ACCEPTED → Update order.status, order.driverId
  │   ├── Hapus orderOffer dari RTDB
  │   ├── Buat orderTracking/{orderId} di RTDB
  │   ├── Buat chat/{orderId} di RTDB
  │   └── Send FCM ke customer
  └── REJECTED → Tambah ke rejectedDriverIds
      └── Cari driver berikutnya → Write orderOffer baru

onOrderCompleted
  ├── Hitung fee platform, earnings driver
  ├── Update wallets/{driverId} (tambah saldo)
  ├── Update wallets/{storeId} (tambah saldo, jika FlexFood)
  ├── Buat transactions (EARNING, FEE, ADVANCE_RETURN)
  ├── Update driverProfiles stats
  ├── Update storeProfiles stats
  ├── Hapus orderTracking dari RTDB
  └── processReferral (jika order pertama customer)
```

---

## 10. Data Migration & Backup Strategy

### 10.1 Backup

| Data | Metode | Frekuensi | Tujuan |
|------|--------|-----------|--------|
| Firestore | Firebase Export | Harian (00:00 WIB) | Oracle Object Storage |
| Realtime DB | JSON export via API | Mingguan | Oracle Object Storage |
| Cloud Storage | N/A (sudah redundant) | - | - |
| Oracle Object Storage | Built-in replication | Otomatis | Cross-region |

### 10.2 Data Retention

| Data | Retention | Alasan |
|------|-----------|--------|
| Orders (completed) | 2 tahun | Riwayat & dispute resolution |
| Transactions | 5 tahun | Kepatuhan keuangan |
| Chat messages | 90 hari setelah order selesai | Privasi + storage |
| Driver locations | Real-time only, no history | Privasi |
| Notifications | 30 hari | Storage optimization |
| Verification docs | Selama akun aktif + 1 tahun | Compliance |

### 10.3 Estimasi Volume Data (Tahun Pertama)

Asumsi: 100 driver aktif, 50 toko, 1000 customer, 200 order/hari

| Collection | Estimasi Dokumen/Tahun | Avg Doc Size | Total |
|------------|----------------------|--------------|-------|
| users | ~1,200 | 2 KB | ~2.4 MB |
| orders | ~73,000 | 3 KB | ~219 MB |
| transactions | ~365,000 | 0.5 KB | ~183 MB |
| menuItems | ~2,500 | 1 KB | ~2.5 MB |
| ratings | ~146,000 | 0.3 KB | ~44 MB |
| RTDB (live) | ~150 nodes | 0.2 KB | ~30 KB |
| Chat messages | ~730,000 | 0.3 KB | ~219 MB |
| **Total Firestore** | | | **~670 MB** |
| **Cloud Storage** | ~50,000 files | 500 KB avg | **~25 GB** |
| **Oracle Storage** | ~1,500 files | 2 MB avg | **~3 GB** |

---

## Appendix A: Entity Relationship Diagram (Logical)

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────────┐
│   users     │       │  driverProfiles  │       │ storeProfiles   │
│             │1─────1│                  │       │                 │
│ uid (PK)    │       │ uid (PK/FK)      │       │ storeId (PK)    │
│ role        │       │ vehicle{}        │       │ ownerUid (FK)   │
│ email       │1─────1│ documents{}      │       │ storeName       │
│ phone       │       │ walletBalance    │       │ location        │
│ displayName │       │ level            │       │ operatingHours{}│
│ savedAddr[] │       │ stats{}          │       │ stats{}         │
└──────┬──────┘       └──────────────────┘       └────────┬────────┘
       │                      │                           │
       │ 1                    │ 1                         │ 1
       │                      │                           │
       │ N                    │ N                         │ N
┌──────┴──────┐       ┌──────┴──────┐            ┌───────┴────────┐
│   orders    │       │  wallets    │            │  menuItems     │
│             │       │             │            │                │
│ orderId(PK) │       │ uid (PK/FK) │            │ menuItemId(PK) │
│ customerId  │       │ balance     │            │ storeId (FK)   │
│ driverId    │       │ modalKas    │            │ name           │
│ storeId     │       │             │            │ price          │
│ serviceType │       └──────┬──────┘            │ isAvailable    │
│ status      │              │                   └────────────────┘
│ pricing{}   │              │ 1
│ payment{}   │              │
└──┬───┬──────┘              │ N
   │   │              ┌──────┴──────┐
   │   │              │transactions │
   │   │              │             │
   │   │              │ txId (PK)   │
   │   │              │ walletId(FK)│
   │   │              │ type        │
   │   │              │ amount      │
   │   │              │ orderId(FK) │
   │   │              └─────────────┘
   │   │
   │   │ 1
   │   │
   │   │ N
   │   ┌──────────┐
   │   │  items   │  (sub-collection)
   │   │          │
   │   │ itemId   │
   │   │ name     │
   │   │ quantity │
   │   │ price    │
   │   └──────────┘
   │
   │ 1
   │
   │ N
┌──┴──────────┐      ┌──────────────┐     ┌──────────────┐
│  ratings    │      │  favorites   │     │  promotions  │
│             │      │              │     │              │
│ ratingId    │      │ favoriteId   │     │ promoId      │
│ orderId(FK) │      │ customerUid  │     │ code         │
│ fromUid     │      │ targetType   │     │ discountType │
│ toUid       │      │ targetId     │     │ discountValue│
│ score       │      └──────────────┘     └──────────────┘
└─────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ bankAccounts │     │ withdrawals  │     │  disputes    │
│              │     │              │     │              │
│ accountId    │     │ withdrawalId │     │ disputeId    │
│ ownerUid(FK) │     │ walletId(FK) │     │ orderId(FK)  │
│ bankName     │     │ bankAcctId   │     │ reporterUid  │
│ accountNum   │     │ amount       │     │ claimedAmount│
│ isDefault    │     │ status       │     │ status       │
└──────────────┘     └──────────────┘     └──────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ pricingRules │     │ surgeZones   │     │ referrals    │
│              │     │              │     │              │
│ ruleId       │     │ zoneId       │     │ referralId   │
│ serviceType  │     │ centerLoc    │     │ referrerUid  │
│ baseFare     │     │ radiusKm     │     │ refereeUid   │
│ perKmRate    │     │ multiplier   │     │ rewardAmount │
└──────────────┘     └──────────────┘     └──────────────┘

┌────────────────────┐     ┌──────────────┐
│ verificationReqs   │     │ driverLevels │
│                    │     │              │
│ requestId          │     │ levelId      │
│ applicantUid (FK)  │     │ name         │
│ applicantType      │     │ minPoints    │
│ status             │     │ benefits{}   │
└────────────────────┘     └──────────────┘
```

---

## Appendix B: Checklist Implementasi

- [ ] Setup Firebase project (single project, 4 apps registered)
- [ ] Enable Firebase Auth (Email/Password provider)
- [ ] Setup Cloud Firestore (production mode)
- [ ] Setup Realtime Database
- [ ] Setup Cloud Storage
- [ ] Setup Firebase Cloud Messaging
- [ ] Setup Firebase Hosting (admin dashboard + landing page)
- [ ] Deploy Firestore security rules
- [ ] Deploy RTDB security rules
- [ ] Deploy Storage security rules
- [ ] Create Firestore composite indexes
- [ ] Setup Oracle Cloud account (student)
- [ ] Create Oracle Object Storage buckets
- [ ] Setup Oracle Autonomous Database (analytics)
- [ ] Claim domain via GitHub Student
- [ ] Configure custom domain di Firebase Hosting
- [ ] Setup WhatsApp Business API
- [ ] Implement Cloud Functions (20 functions)
- [ ] Setup FCM topics per role
- [ ] Create admin dashboard (Next.js)
- [ ] Integration testing antar-app

---

*Dokumen ini adalah blueprint lengkap untuk implementasi database dan backend RideOn. Setiap collection, field, dan rule telah dirancang berdasarkan analisis mendalam desain Figma dan keputusan arsitektur yang telah disetujui bersama.*
