# RideOn - Dokumentasi Sistem Autentikasi Multi-Aplikasi

Dokumen ini menjelaskan secara menyeluruh arsitektur, alur otentikasi (Authentication Flow), struktur data pengguna, skema sesi, serta panduan implementasi untuk ketiga aplikasi di dalam ekosistem **RideOn**:
1. **Customer App** (`com.rideon.customer`)
2. **Driver App** (`com.rideon.driver`)
3. **Store/Merchant App (`page_toko`)** (`com.rideon.page_toko`)

---

## 1. Arsitektur & Provider Autentikasi

Ekosistem RideOn menggunakan **Firebase Authentication** sebagai single identity provider terpusat yang diintegrasikan dengan **Cloud Firestore** sebagai penyimpan profil peran (Role-based profile) dan **Firebase Realtime Database** untuk status kehadiran (*presence*).

```
                      +-----------------------------+
                      |   Firebase Authentication   |
                      |  (Google, Email/PW, Phone)  |
                      +--------------+--------------+
                                     |
               +---------------------+---------------------+
               |                     |                     |
               v                     v                     v
       [CUSTOMER APP]          [DRIVER APP]           [STORE APP]
   Role: CUSTOMER         Role: DRIVER           Role: STORE_OWNER
   Firestore: /users/{uid} Firestore: /drivers/{uid} Firestore: /stores/{uid}
```

### Matriks Provider per Aplikasi

| Provider Login | Customer App | Driver App | Page Toko | Alasan & Kasus Penggunaan |
| :--- | :---: | :---: | :---: | :--- |
| **Google Sign-In** | ✅ Ya | ✅ Ya | ✅ Ya | Login cepat sekali-klik, mengurangi friction registrasi pengguna baru |
| **Email & Password** | ✅ Ya | ✅ Ya | ✅ Ya | Alternatif kredensial standar & untuk manajemen akun formal (Toko/Admin) |
| **Phone / WhatsApp OTP** | ✅ Ya | ✅ Ya | ✅ Ya | Verifikasi nomor aktif untuk keperluan kontak pesanan, chat & panggilan |
| **Anonymous** | ✅ Dev Only | ❌ Tidak | ❌ Tidak | Khusus pengujian lokal tanpa autentikasi nyata |

---

## 2. Alur & Logika Autentikasi per Aplikasi

### 2.1. Customer App (`com.rideon.customer`)

#### A. Alur Login & Registrasi
1. **Pilihan Masuk**: Pengguna membuka halaman Login dengan tampilan glassmorphism sesuai desain Figma.
2. **Metode Google**:
   - Pengguna menekan tombol *"Lanjutkan Dengan Google"*.
   - Muncul dialog akun Google native Android.
   - Aplikasi menerima token kredensial dan melakukan sign-in ke Firebase Auth.
   - Sistem memeriksa koleksi Firestore `/users/{uid}`.
     - **Jika baru pertama kali**: Buat dokumen profil awal dengan saldo awal dompet 0, status aktif, dan rating default 5.0.
     - **Jika sudah ada**: Perbarui timestamp `updatedAt`.
3. **Metode Email/Password**:
   - Pengguna menginput Email / No. WhatsApp dan kata sandi.
   - Validasi kredensial via `FirebaseAuth.instance.signInWithEmailAndPassword()`.
   - Jika salah, tampilkan error banner merah sesuai Figma (*"Email/WhatsApp atau kata sandi yang Anda masukkan salah."*).
4. **Navigasi**: Setelah kredensial valid, arahkan ke `MainScreen()` (Beranda).

#### B. Skema Dokumen Firestore: `/users/{userId}`
```json
{
  "uid": "USER_FIREBASE_UID",
  "name": "Budi Santoso",
  "email": "budi@gmail.com",
  "phoneNumber": "+6281234567890",
  "photoUrl": "https://lh3.googleusercontent.com/...",
  "role": "CUSTOMER",
  "rating": 5.0,
  "wallet": {
    "balance": 0,
    "currency": "IDR"
  },
  "fcmToken": "FCM_TOKEN_STRING",
  "createdAt": "TIMESTAMP",
  "updatedAt": "TIMESTAMP"
}
```

---

### 2.2. Driver App (`com.rideon.driver`)

#### A. Alur Login & Status Verifikasi
1. **Otentikasi Kredensial**:
   - Mitra driver login via Google Sign-In atau Email/Password.
2. **Pemeriksaan Status Akun (`status`)**:
   Berbeda dengan Customer, akun Driver memiliki siklus status verifikasi dokumen (KTP, SIM, STNK, SKCK):
   - `PENDING_VERIFICATION`: Baru mendaftar, belum diverifikasi admin.
   - `ACTIVE`: Sudah disetujui, bisa mengaktifkan mode Online & menerima order radar.
   - `SUSPENDED` / `BANNED`: Akun dinonaktifkan sementara karena pelanggaran.
3. **Inisialisasi Kehadiran & Radar GPS**:
   - Begitu driver login dan menggeser toggle **Online**, aplikasi mengikat Realtime Database:
     - `/driver_locations/{driverId}`: Menyimpan koordinat GPS (lat, lng, heading) untuk dicari oleh customer di sekitar.
     - `/driver_presence/{driverId}`: Mengatur status online/offline dan mendeteksi diskoneksi otomatis (`.onDisconnect()`).
4. **Keluar / Sign Out**:
   - Sebelum sign-out, status online driver diubah menjadi `false` agar marker hilang dari radar peta customer.

#### B. Skema Dokumen Firestore: `/drivers/{driverId}`
```json
{
  "driverId": "DRIVER_FIREBASE_UID",
  "name": "Agus Pratama",
  "email": "agus.driver@gmail.com",
  "phoneNumber": "+6281298765432",
  "photoUrl": "https://...",
  "role": "DRIVER",
  "status": "ACTIVE",
  "rating": 4.95,
  "level": "BRONZE",
  "levelPoints": 150,
  "wallet": {
    "balance": 50000,
    "currency": "IDR"
  },
  "vehicle": {
    "type": "MOTORCYCLE",
    "plateNumber": "B 1234 XYZ",
    "brand": "Honda Vario 160",
    "color": "Hitam"
  },
  "stats": {
    "totalTrips": 48,
    "totalEarnings": 650000,
    "todayTrips": 6,
    "todayEarnings": 85000
  },
  "createdAt": "TIMESTAMP",
  "updatedAt": "TIMESTAMP"
}
```

#### C. Skema Realtime Database: `/driver_locations/{driverId}`
```json
{
  "driverId": "DRIVER_FIREBASE_UID",
  "latitude": -6.2088,
  "longitude": 106.8456,
  "heading": 180.5,
  "isOnline": true,
  "serviceType": "FLEXRIDE",
  "updatedAt": 1720000000000
}
```

---

### 2.3. Store / Merchant App (`com.rideon.page_toko`)

#### A. Alur Login & Hak Akses Toko
1. **Identitas Pemilik Toko**:
   - Pemilik toko login via Google atau Email/Password terdaftar.
2. **Koneksi Profil Toko**:
   - UID akun Firebase langsung dipetakan ke ID dokumen toko di Firestore: `/stores/{storeId}` (di mana `storeId == auth.uid`).
   - Dengan struktur ini, Security Rules Firestore dapat dengan mudah memastikan hanya pemilik toko yang berhak mengedit katalog menu makanan dan mengubah status operasional toko (Buka / Tutup).
3. **Penyimpanan Sesi Toko**:
   - Aplikasi toko menyimpan sesi login secara lokal sehingga setiap kali aplikasi dibuka langsung masuk ke Dashboard Pesanan Toko.

#### B. Skema Dokumen Firestore: `/stores/{storeId}`
```json
{
  "storeId": "STORE_FIREBASE_UID",
  "ownerUid": "STORE_FIREBASE_UID",
  "storeName": "Warung Bakso Urat Mas Bro",
  "email": "bakso.masbro@gmail.com",
  "phoneNumber": "+6281311223344",
  "photoUrl": "https://...",
  "role": "STORE_OWNER",
  "status": "ACTIVE",
  "isOpen": true,
  "rating": 4.8,
  "address": {
    "street": "Jl. Merdeka No. 10",
    "latitude": -6.2100,
    "longitude": 106.8400
  },
  "wallet": {
    "balance": 250000,
    "currency": "IDR"
  },
  "createdAt": "TIMESTAMP",
  "updatedAt": "TIMESTAMP"
}
```

---

## 3. Matriks Keamanan & Security Rules

Untuk menjamin agar aplikasi tidak saling menimpa data atau mengakses data tanpa izin:

### 3.1. Firestore Rules (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Customer: Hanya pemilik yang bisa edit profil pribadinya
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    // Driver: Publik bisa baca rating/nama, hanya driver terkait yang bisa edit
    match /drivers/{driverId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(driverId);
    }

    // Toko: Semua user login bisa melihat profil & menu toko; hanya pemilik toko yang bisa edit
    match /stores/{storeId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(storeId);
      
      match /menus/{menuId} {
        allow read: if isAuthenticated();
        allow write: if isOwner(storeId);
      }
    }

    // Orders: Customer, Driver, dan Toko yang terlibat bisa baca dan update pesanan
    match /orders/{orderId} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

### 3.2. Realtime Database Rules (`database.rules.json`)
```json
{
  "rules": {
    "driver_locations": {
      ".read": "auth != null",
      "$driverId": {
        ".write": "auth != null && auth.uid === $driverId"
      }
    },
    "driver_presence": {
      ".read": "auth != null",
      "$driverId": {
        ".write": "auth != null && auth.uid === $driverId"
      }
    },
    "chats": {
      "$orderId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

---

## 4. Penanganan Error & Troubleshooting Autentikasi

| Kasus Error | Penyebab Utama | Solusi Penanganan |
| :--- | :--- | :--- |
| `ApiException: 10` | Sertifikat SHA-1 laptop belum didaftarkan di Firebase Console. | Dapatkan SHA-1 dari `./gradlew signingReport` dan tambahkan di Project Settings Firebase. Unduh ulang `google-services.json`. |
| `user-not-found` / `wrong-password` | Pengguna salah memasukkan kredensial email/sandi. | Tampilkan banner peringatan visual di bawah input password sesuai desain Figma. |
| `network-request-failed` | Koneksi internet terputus saat request otentikasi. | Tampilkan SnackBar info koneksi internet bermasalah. |
| `account-exists-with-different-credential` | Email sudah terdaftar lewat Email/Password, lalu mencoba login dengan Google. | Lakukan linking akun kredensial via `auth.currentUser?.linkWithCredential()`. |

---

## 5. Ringkasan File Implementasi Kode

| Aplikasi | Lokasi File | Fungsi |
| :--- | :--- | :--- |
| **Customer App** | `lib/features/auth/data/auth_service.dart` | Logika otentikasi Google, Email, dan sinkronisasi Firestore `/users` |
| **Customer App** | `lib/features/auth/presentation/pages/login_screen.dart` | Tampilan form UI login, tombol Google, dan navigasi |
| **Driver App** | `lib/services/driver_service.dart` | Otentikasi Driver, broadcast GPS ke Realtime DB, dan sinkronisasi Firestore `/drivers` |
| **Driver App** | `lib/screens/splash_screen_login.dart` | Tampilan awal login mitra driver |
| **Page Toko** | `lib/services/store_auth_service.dart` *(Akan dipasang di Fase 3)* | Otentikasi Pemilik Toko & sinkronisasi katalog toko `/stores` |
