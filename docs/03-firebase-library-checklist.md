# RideOn - Firebase & Flutter Library Integration Checklist

Dokumen ini adalah panduan kerja dan checklist implementasi library Firebase untuk ketiga aplikasi: **Customer App**, **Driver App**, dan **Store/Toko App (`page_toko`)**.

---

## 📊 Status Ringkasan Ekosistem

| Komponen / Setup | Customer App | Driver App | Page Toko | Status Terkini |
| :--- | :---: | :---: | :---: | :---: |
| **Android Application ID** | `com.rideon.customer` | `com.rideon.driver` | `com.rideon.page_toko` | ✅ Selesai |
| **Kotlin Package Structure** | `com.rideon.customer` | `com.rideon.driver` | `com.rideon.page_toko` | ✅ Selesai |
| **`google-services.json`** | Versi 122 baris (SHA-1) | Versi 122 baris (SHA-1) | Versi 122 baris (SHA-1) | ✅ Selesai |
| **Gradle Plugins (KTS)** | Terpasang | Terpasang | Terpasang | ✅ Selesai |
| **Firebase Auth Provider** | Google, Phone, Anon, Email | Google, Phone, Anon, Email | Google, Phone, Anon, Email | ✅ Selesai di Console |
| **Firestore & RTDB Rules** | Configured | Configured | Configured | ✅ Selesai di Console |

---

## 📦 Matriks Kebutuhan Library per Aplikasi

| Library (Package) | Customer App | Driver App | Page Toko | Deskripsi & Fungsi |
| :--- | :---: | :---: | :---: | :--- |
| `firebase_core` | `^3.12.1` | `^3.12.1` | `^3.12.1` | Inisialisasi utama Firebase App |
| `firebase_auth` | `^5.5.1` | `^5.5.1` | `^5.5.1` | Autentikasi User (Google, Email, Phone) |
| `google_sign_in` | `^6.2.2` | `^6.2.2` | `^6.2.2` | Native dialog Google Login Android |
| `cloud_firestore` | `^5.6.5` | `^5.6.5` | `^5.6.5` | Database profil, menu, order, rating, promo |
| `firebase_database` | `^11.3.1` | `^11.3.1` | `^11.3.1` | Lokasi GPS driver, radar ping, countdown 18s |
| `firebase_storage` | `^12.4.4` | `^12.4.4` | `^12.4.4` | Upload foto profil, foto menu, bukti kirim |
| `firebase_messaging` | `^15.2.4` | `^15.2.4` | `^15.2.4` | Push Notification (FCM) pesanan & promo |
| `geolocator` | `^13.0.2` | `^13.0.2` | `^13.0.2` | Pengambilan koordinat GPS perangkat |
| `latlong2` / `google_maps_flutter` | `^0.9.1` | `^0.9.1` | `^0.9.1` | Render peta rute & marker |

---

## 📋 Checklist Pekerjaan Bertahap

### FASE 1: Setup Library `customer_app`
- [x] **1.1. Tambahkan Dependencies di `apps/customer_app/pubspec.yaml`**
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    firebase_core: ^3.12.1
    firebase_auth: ^5.5.1
    google_sign_in: ^6.2.2
    cloud_firestore: ^5.6.5
    firebase_database: ^11.3.1
    firebase_storage: ^12.4.4
    firebase_messaging: ^15.2.4
  ```
- [x] **1.2. Jalankan `flutter pub get` di folder `apps/customer_app`**
- [x] **1.3. Inisialisasi Firebase di `apps/customer_app/lib/main.dart`**
  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  ```
- [x] **1.4. Uji Coba Build & Run**: Aplikasi customer terbukti berhasil running di perangkat fisik/Infinix tanpa crash.
- [x] **1.5. Implementasi & Hubungkan Auth**:
  - [x] Implementasi `AuthService` (`apps/customer_app/lib/features/auth/data/auth_service.dart`)
  - [x] Integrasi Google Sign-In & Email/Password di `login_screen.dart`
  - [x] Sinkronisasi otomatis data profil user ke Firestore `/users/{uid}` saat login pertama kali

---

### FASE 2: Setup Library `driver_app`
- [x] **2.1. Tambahkan Dependencies di `apps/driver_app/pubspec.yaml`**
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    firebase_core: ^3.12.1
    firebase_auth: ^5.5.1
    google_sign_in: ^6.2.2
    cloud_firestore: ^5.6.5
    firebase_database: ^11.3.1
    firebase_storage: ^12.4.4
    firebase_messaging: ^15.2.4
  ```
- [x] **2.2. Jalankan `flutter pub get` di folder `apps/driver_app`**
- [x] **2.3. Inisialisasi Firebase di `apps/driver_app/lib/main.dart`**
  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  ```
- [x] **2.4. Implementasi DriverService & Radar Realtime DB**:
  - Dibuat `apps/driver_app/lib/services/driver_service.dart`
  - Terintegrasi update posisi GPS radar ke `/driver_locations/{driverId}` (Realtime DB)
  - Terintegrasi status online/offline `/driver_presence/{driverId}`
  - Inisialisasi profil driver di Firestore `/drivers/{driverId}`
- [ ] **2.5. Uji Coba Build & Run**: Jalankan `flutter run` di folder `apps/driver_app`

---

### FASE 3: Setup Library `page_toko`
- [ ] **3.1. Tambahkan Dependencies di `apps/page_toko/pubspec.yaml`**
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    firebase_core: ^3.12.1
    firebase_auth: ^5.5.1
    google_sign_in: ^6.2.2
    cloud_firestore: ^5.6.5
    firebase_storage: ^12.4.4
    firebase_messaging: ^15.2.4
  ```
- [ ] **3.2. Jalankan `flutter pub get` di folder `apps/page_toko`**
- [ ] **3.3. Inisialisasi Firebase di `apps/page_toko/lib/main.dart`**
  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  ```
- [ ] **3.4. Uji Coba Build & Run**: Pastikan aplikasi toko running lancar.
- [ ] **3.5. Uji Coba Firestore**:
  - Toko login -> buat toko di `/stores/{storeId}`
  - Tambah menu makanan dummy di `/stores/{storeId}/menus/{menuId}`
  - Verifikasi menu muncul di Firestore console.

---

### FASE 4: Pengujian Integrasi Antar-Aplikasi (End-to-End)
- [ ] **4.1. Customer ↔ Driver (FlexRide)**:
  - Customer buka peta -> Realtime DB listener membaca posisi driver di sekitar.
  - Customer buat order -> order masuk ke `/orders/{orderId}`.
  - Driver menerima alert radar (18s countdown).
- [ ] **4.2. Customer ↔ Toko ↔ Driver (FlexFood)**:
  - Customer melihat menu dari koleksi toko.
  - Customer checkout -> Toko menerima pesanan di tab order.
  - Toko konfirmasi -> Driver menerima order pengantaran makanan.
- [ ] **4.3. Customer ↔ Driver (FlexSend)**:
  - Customer input barang & talangan -> Driver menerima kalkulasi ongkir + talangan.

---

## 📌 Catatan Error Umum & Solusi Cepat

| Error | Penyebab | Solusi |
| :--- | :--- | :--- |
| `ApiException: 10` | SHA-1 belum terdaftar di Firebase Console | Masukkan SHA-1 debug laptop ke Project Settings, unduh `google-services.json` terbaru. |
| `DefaultFirebaseOptions not found` | Belum generate options manual | Gunakan `await Firebase.initializeApp()` langsung karena `google-services.json` sudah ada di Android native. |
| `MissingPluginException` | Hot reload setelah nambah dependency baru | Lakukan **Stop** aplikasi, jalankan `flutter clean`, lalu `flutter run` ulang. |
