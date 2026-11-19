# Audit Kepatuhan Blueprint, Rencana Remediasi AI, & Panduan Setup Manual RideOn

> **Dokumen Acuan Utama (SSOT):** `docs/15-ecosystem-infrastructure-and-integration-discussion.md` (Bagian 1–10)
> **Tanggal Audit:** 19 November 2026
> **Status Baseline Saat Audit:** 7 container Podman lokal sehat (`mysql`, `nginx`, `wa-gateway`, `rideon-api`, `payg`, `ai-service`, `admin`), unit/widget test Flutter lulus (`customer_app`: 69, `driver_app`: 104, `page_toko`: 28), Go tests & E2E lokal lulus, namun masih terdapat beberapa celah keamanan, bug integrasi lintas-perangkat, sisa Cloud Firestore, dan penyimpangan spesifikasi yang harus dibereskan sebelum produksi.
> **Catatan Penting:** Dokumen ini **tidak mengubah** `docs/15-ecosystem-infrastructure-and-integration-discussion.md`. Konfigurasi manual eksternal (Firebase, Resend, Gmail, Static QRIS, MacroDroid, API Key AI, QR WhatsApp, VM OCI) dipisahkan di Bagian 6 agar jelas antara **kekurangan kode** vs **setup manual yang belum diisi**.

---

## Daftar Isi

1. [Ringkasan Kepatuhan per Bagian (`docs/15` Bagian 1–10)](#1-ringkasan-kepatuhan-per-bagian-docs15-bagian-110)
2. [Kategori 1 — Semua Temuan Kritis (Bug Lintas-Aplikasi & Keamanan)](#2-kategori-1--semua-temuan-kritis-bug-lintas-aplikasi--keamanan)
3. [Kategori 2 — Semua Fitur Kurang / Melenceng dari Blueprint](#3-kategori-2--semua-fitur-kurang--melenceng-dari-blueprint)
4. [Kategori 3 — Deviasi Minor & Item yang Wajar Belum Dikerjakan](#4-kategori-3--deviasi-minor--item-yang-wajar-belum-dikerjakan)
5. [Tahapan Pengerjaan Remediasi untuk AI & Daftar Skill per Tahap](#5-tahapan-pengerjaan-remediasi-untuk-ai--daftar-skill-per-tahap)
6. [Panduan Lengkap Mengisi Setup Manual & Langkah Lanjut ke Produksi (OCI)](#6-panduan-lengkap-mengisi-setup-manual--langkah-lanjut-ke-produksi-oci)

---

## 1. Ringkasan Kepatuhan per Bagian (`docs/15` Bagian 1–10)

| Bagian `docs/15` | Ruang Lingkup | Status Kepatuhan | Ringkasan Kondisi Aktual |
|---|---|---|---|
| **Bagian 1 & 2A** | Filosofi Ekosistem & Pola I (1 MySQL `rideon_db`) | **Sesuai** | 1 database MySQL (`127.0.0.1:3306`), 22 tabel (21 blueprint + `system_settings`), seeder Lhokseumawe & Aceh Utara lengkap, saldo awal driver `0`, batas minus `-20000`, komisi `5%:5%`, atomic anti-rebutan `409 Conflict`. |
| **Bagian 2B** | Batasan Firebase (Tanpa Firestore; RTDB + FCM + Auth) | **Melenceng** | `cloud_firestore` masih terpasang dan dipakai di `customer_app` & `driver_app`; `firebase_messaging` belum dipanggil di `lib/` 3 app Flutter; schema key RTDB `driver_locations` tidak sinkron antar writer/reader; `onDisconnect()` belum dipasang. |
| **Bagian 3** | Skema Database 21+ Tabel & Seeder | **Hampir Sesuai** | 22 tabel terbentuk; nominal default `pricing_rules` berbeda dari Bagian 8.5, belum ada kolom `base_distance_km` & `extra_stop_fee`, serta `registrations.applicant_role` baru mencakup `DRIVER` & `STORE` (belum `CUSTOMER`). |
| **Bagian 4** | Integrasi 3 App Flutter & Web Admin | **Sebagian Melenceng** | Alur inti jalan, tetapi terdapat mismatch nama status order di `customer_app`, WebRTC baru 1 arah (`startCall` tanpa `answerCall`), double QRIS generate, chat masih lokal, FlexRide QRIS dummy 5 detik, dan koordinat pickup/dropoff/wisata masih hardcoded. |
| **Bagian 5 & 6** | Jaringan, Reverse Proxy Nginx, Podman, VM OCI | **Lokal OK / 6B Belum** | 7 container sehat di lokal (`:8088`); belum ada blok landing page `rideons.app` (unduh APK & privasi) di `nginx.conf`, image `compose.yaml` belum prefix `docker.io/library/`, dan Tahap 6B (OCI + TLS `:443`) belum dijalankan. |
| **Bagian 7A–7C** | WA Gateway, PayG QRIS, Dual-Email | **Hampir Sesuai** | `wa-gateway` (sesi tersimpan di MySQL `whatsapp_sessions` + auto-reply AI) & `payg` (EMVCo Tag 54 + CRC-16 + kode unik `1..999` + SVG + MacroDroid webhook) berfungsi baik; **prioritas Resend vs Gmail terbalik** untuk balasan tiket CS 2 arah. |
| **Bagian 7D** | Universal AI Service (`ai-service`) | **Ada Celah Keamanan & Gap** | Enkripsi AES-256-GCM, multi-provider `openai_compatible`/`gemini_native`, & priority failover sesuai; **endpoint `/ai/providers` tanpa autentikasi JWT Admin**, `DELETE` belum ada, konteks MySQL kurang `store_menus`/`qris_transactions`/`withdrawals`, dan belum ada safe action otomatis. |
| **Bagian 8** | 15 Alur Bisnis End-to-End (8.1–8.15) | **Sebagian Melenceng** | Alur daftar mitra, approve/reject, komisi `5%:5%`, atomic accept `409`, nota + parkir, withdraw PIN 6 digit, & klaim talangan donasi 2 langkah lulus; alur QRIS pre-payment gate, tracking customer, tarif default, promo admin, chat, & VoIP 2 arah masih bermasalah. |
| **Bagian 9 & 10** | Postman Collection & Package Name Android | **Sesuai** | Postman Collection (`docs/postman/RideOn-Ecosystem.postman_collection.json`, 28 request dalam 6 folder) terverifikasi; Android `applicationId` 100% sesuai (`com.rideon.customer`, `com.rideon.driver`, `com.rideon.page_toko`). |

---

## 2. Kategori 1 — Semua Temuan Kritis (Bug Lintas-Aplikasi & Keamanan)

Seluruh temuan berikut **berisiko fatal** saat dijalankan pada skenario nyata multi-HP atau dipublikasikan ke internet (`api.rideons.app`):

### K1. Endpoint CRUD `/ai/providers` Tidak Dilindungi Autentikasi JWT Admin (`Bagian 7D`)
- **Lokasi:**
  - `services/ai-service/main.go:62-63`
  - `services/ai-service/main.go:305-549` (`handleProvidersCollection`, `handleProviderByID`)
- **Masalah:** Tidak ada pengecekan `Authorization: Bearer <admin-jwt>` (role `ADMIN`) pada `GET/POST /ai/providers` maupun `PUT /ai/providers/:id`. Selain itu method `DELETE /ai/providers/:id` belum didukung.
- **Dampak:** Siapa pun di internet yang mengakses `https://api.rideons.app/ai/providers` dapat melihat daftar provider, menyuntikkan provider baru, atau menimpa `base_url`/`api_key` AI sistem tanpa login Admin.
- **Target Perbaikan:** Tambahkan middleware verifikasi HS256 JWT dengan klaim `role == "ADMIN"` (menggunakan `JWT_SECRET` yang sama dengan `rideon-api` & `payg`) untuk seluruh endpoint `/ai/providers*` dan tambahkan dukungan `DELETE /ai/providers/:id`.

### K2. FCM Push Notification Belum Aktif di 3 Aplikasi Flutter & Backend Tidak Menyimpan `fcm_token` (`Bagian 2B, 4, 8.2, 8.11`)
- **Lokasi:**
  - `apps/customer_app/pubspec.yaml`, `apps/driver_app/pubspec.yaml`, `apps/page_toko/pubspec.yaml` (paket `firebase_messaging` terpasang, tetapi 0 pemanggilan di seluruh `lib/`).
  - `services/rideon-api/handlers_auth.go:626-654` (`PATCH /v1/auth/me` belum menerima atau menyimpan kolom `fcm_token`).
  - `services/rideon-api/main.go:367-370` (`notifyUserAsync` membaca `users.fcm_token` yang selalu `NULL`).
  - `services/rideon-api/handlers_orders.go:1286-1313` (`POST /v1/internal/qris-paid`) & `services/payg/main.go:457-460`.
- **Masalah:**
  1. Ketiga app Flutter tidak pernah meminta izin notifikasi, tidak mengambil `FirebaseMessaging.instance.getToken()`, tidak memantau `onTokenRefresh`, dan tidak mengirim `fcm_token` ke `PATCH /v1/auth/me` saat login/startup.
  2. Backend `PATCH /v1/auth/me` tidak menyimpan field `fcm_token` ke tabel `users`.
  3. Saat `payg` melunasi QRIS (`ORDER_PAYMENT` maupun `DRIVER_TOPUP`), `rideon-api` hanya melakukan ping RTDB `live_orders/{id}` dan tidak mengirim FCM push ke `page_toko` (pesanan baru masuk setelah lunas), `customer_app` (pembayaran terkonfirmasi), maupun `driver_app` (saldo top-up masuk).
- **Dampak:** Saat aplikasi berada di background atau layar mati, mitra toko, driver, dan customer tidak menerima notifikasi push.

### K3. Ketidakcocokan Schema Key & Node ID RTDB `driver_locations` + Tidak Ada `onDisconnect()` (`Bagian 2B, 4, 5C`)
- **Lokasi:**
  - Writer 1 (Backend): `services/rideon-api/handlers_driver.go:181-190` — menulis ke `driver_locations/{driver_id}` dengan key `lat`, `lng`, `is_online`, `driver_id`, `name`, `vehicle_type`, `vehicle_plate`.
  - Writer 2 (Driver App): `apps/driver_app/lib/services/driver_service.dart:114-127` — menulis ke `driver_locations/{uid}` dengan key **`latitude`, `longitude`, `isOnline`** (menggunakan `.set()`, sehingga menimpa dan menghapus key `lat`/`lng`/`name`/`vehicle_type`).
  - Pemanggil di Driver App: `apps/driver_app/lib/screens/radar/radar_screen.dart:422-428` & `481-487` — memanggil `updateDriverLocation` **tanpa meneruskan `driverId` MySQL** (`currentDriver?.uid` bernilai `null` saat login via JWT REST tanpa sesi Firebase Auth, atau berbeda dari `drivers.id`).
  - Reader 1 (Customer App): `apps/customer_app/lib/features/flexride/presentation/pages/flexride_screen.dart:268-274` — membaca `driver_locations/{driverId}` dengan key `lat` & `lng`.
  - Reader 2 (Web Admin Peta Aktif): `apps/admin-RideOn/src/components/dashboard.tsx:1164-1176` — membaca SSE `driver_locations.json` dengan key `val.lat`, `val.lng`, `val.is_online`.
  - Presence: `apps/driver_app/lib/services/driver_service.dart:134-148` — `setDriverPresence` belum memanggil `onDisconnect().set(...)` maupun `locationRef.onDisconnect().update({'is_online': false})`.
- **Dampak:** Titik koordinat live yang dikirim HP driver diabaikan oleh peta customer & Peta Aktif Web Admin; dan jika HP driver mati mendadak / hilang sinyal, status driver tidak otomatis berubah menjadi `offline`.

### K4. Ketidakcocokan Nama Status Order antara Backend (`rideon-api`) vs `apps/customer_app` (`Bagian 4 & 8`)
- **Lokasi:**
  - Kontrak Enum MySQL & `rideon-api`: `docker/mysql/init/01_schema.sql:268-280`, `services/rideon-api/handlers_orders.go:974` — memakai: `CREATED`, `WAITING_STORE_CONFIRM`, `STORE_PREPARING`, `SEARCHING_DRIVER`, `DRIVER_ASSIGNED`, `DRIVER_AT_PICKUP`, `IN_TRANSIT`, `DELIVERED`, `COMPLETED`, `CANCELLED`. (`driver_app` & `page_toko` sudah selaras dengan enum ini.)
  - Mismatch di `apps/customer_app`:
    - `apps/customer_app/lib/features/flexfood/presentation/modules/tracking/food_tracking_view.dart:121-137` memeriksa `COOKING`, `ARRIVED_AT_STORE`, `PICKED_UP`, `ON_THE_WAY`.
    - `apps/customer_app/lib/features/flexride/presentation/pages/flexride_screen.dart:294-310` memeriksa `ARRIVED_AT_PICKUP`, `PICKED_UP`, `ON_THE_WAY`.
    - `apps/customer_app/lib/features/flexsend/presentation/pages/flexsend_screen.dart:247-263` memeriksa `SHOPPING`, `PICKED_UP`, `ON_THE_WAY`, `ARRIVED_AT_DROPOFF`.
- **Dampak:** UI progres tracking di `customer_app` berhenti di tahap awal dan tidak berpindah saat toko/driver mengubah status ke `STORE_PREPARING`, `DRIVER_AT_PICKUP`, `IN_TRANSIT`, atau `DELIVERED`.

### K5. Double QRIS Generation & Order QRIS Belum Lunas Sudah Masuk Toko / Radar Driver (`Bagian 4, 8.7–8.8`)
- **Lokasi:**
  - `services/rideon-api/handlers_orders.go:464-476` & `563-569`
  - `services/rideon-api/handlers_orders.go:1286-1313` (`handleInternalQRISPaid`)
  - `apps/customer_app/lib/features/flexfood/presentation/modules/checkout/checkout_view.dart:173-190`
  - `apps/customer_app/lib/features/flexride/presentation/pages/flexride_screen.dart:211-219`
- **Masalah:**
  1. Saat `POST /v1/orders` dengan `payment_method = 'QRIS'`, `rideon-api` sudah memanggil `s.callPayGGenerate(...)` dan mengembalikan payload `qris`. Namun `checkout_view.dart` dan `flexride_screen.dart` mengabaikan field `qris` tersebut dan memanggil `POST /pay/qris/generate` **untuk kedua kalinya** → tercipta **2 record `qris_transactions` PENDING** dengan 2 kode unik berbeda untuk 1 order.
  2. Order QRIS yang masih `payment_status = 'PENDING'` langsung diset berstatus `WAITING_STORE_CONFIRM` (FlexFood) atau `SEARCHING_DRIVER` (FlexRide/FlexSend) dan langsung di-broadcast ke `order_offers` RTDB sebelum customer membayar.
- **Target Perbaikan:**
  - Gunakan 1 sumber tunggal QRIS dari response `POST /v1/orders` (`resp["qris"]`), dan hanya fallback ke `POST /pay/qris/generate` jika `qris` kosong.
  - Untuk order `QRIS`, simpan dengan `status = 'CREATED'` (`payment_status = 'PENDING'`) tanpa broadcast ke toko/driver terlebih dahulu. Baru saat `POST /v1/internal/qris-paid` dipanggil oleh `payg` (status `PAID`), `rideon-api` memindahkan status ke `WAITING_STORE_CONFIRM` (untuk `FLEX_FOOD`) atau `SEARCHING_DRIVER` + `offer_expires_at` + broadcast RTDB `order_offers` (untuk `FLEX_RIDE`/`FLEX_SEND`) sekaligus mengirim FCM push.

### K6. WebRTC VoIP Baru 1 Arah — Tidak Ada Listener Panggilan Masuk & `answerCall()` (`Bagian 4 & 8.12`)
- **Lokasi:**
  - `apps/customer_app/lib/core/services/webrtc_call_service.dart`
  - `apps/driver_app/lib/services/webrtc_call_service.dart`
- **Masalah:** Kedua service hanya menyediakan alur pemanggil (`startCall()` membuat SDP Offer di `/calls/{orderId}` lalu menunggu `answer`). Tidak ada listener incoming call pada `/calls/{orderId}` maupun fungsi `answerCall()` + UI pop-up "Panggilan Masuk (Terima / Tolak)" di sisi lawan.
- **Dampak:** Panggilan suara gratis P2P WebRTC tidak pernah tersambung secara nyata antara HP Customer dan HP Driver.

### K7. Cloud Firestore Masih Terpasang & Dipakai Aktif di `customer_app` dan `driver_app` (`Bagian 2B`)
- **Lokasi:**
  - Dependensi: `apps/customer_app/pubspec.yaml:43` (`cloud_firestore: ^5.6.5`), `apps/driver_app/pubspec.yaml:44` (`cloud_firestore: ^5.6.5`).
  - Pemakaian aktif di `apps/customer_app/lib/` (16+ file): `lokasi_anda_screen.dart`, `lokasi_anda_logic.dart`, `nomor_wa_screen.dart`, `nomor_wa_logic.dart`, `alamat_email_screen.dart`, `alamat_email_logic.dart`, `keamanan_akun_screen.dart`, `keamanan_akun_logic.dart`, `pengaturan_akun_screen.dart`, `ubah_profil_screen.dart`, `email_verification_dialog.dart`, `main_screen.dart`, `auth_service.dart`, `global_search_screen.dart`, `location_picker_module.dart`, `osm_nominatim_service.dart`.
  - Pemakaian sisa di `apps/driver_app/lib/`: `driver_service.dart:151-160` (`_saveDriverProfile`).
- **Masalah:** Melanggar aturan tegas `docs/15` Bagian 2B (*"TIDAK MENGGUNAKAN CLOUD FIRESTORE — Firestore dimatikan / tidak dipakai; seluruh data bisnis, katalog, profil, dan transaksi berada di MySQL VPS"*). Layar Pengaturan Akun (`Lokasi Anda`, `Nomor WA`, `Alamat Email`, `Keamanan Akun`) akan gagal menyimpan atau tidak sinkron ke MySQL saat Firestore dimatikan di Firebase Console.
- **Target Perbaikan:** Migrasikan seluruh read/write alamat tersimpan, ubah WA/email, keamanan akun/password, riwayat pencarian, dan profil ke endpoint `rideon-api` MySQL (atau `SharedPreferences` untuk riwayat lokal non-kritis), lalu hapus total dependensi `cloud_firestore` dari `pubspec.yaml` `customer_app` & `driver_app`.

---

## 3. Kategori 2 — Semua Fitur Kurang / Melenceng dari Blueprint

### F1. Prioritas Dual-Email Terbalik untuk Balasan Tiket CS 2 Arah (`Bagian 7C`)
- **Lokasi:**
  - `services/rideon-api/handlers_admin.go:1113`
  - `services/rideon-api/main.go:325-357` (`sendEmailMessage`)
- **Masalah:** `docs/15` Bagian 7C membagi peran secara jelas:
  - **Resend (`noreply@rideons.app`)** → Primary untuk email sistem 1 arah (OTP, Approval/Rejection, Notifikasi Sistem), dengan Gmail SMTP sebagai failover.
  - **Gmail Resmi Admin (`smtp.gmail.com`)** → **Primary untuk balasan Tiket CS 2 arah** agar user bisa langsung klik *Reply* dan balasannya masuk ke Inbox Gmail Admin.
  - Saat ini `handlers_admin.go` memanggil `sendEmailMessage()` yang selalu memprioritaskan Resend terlebih dulu, sehingga balasan CS terkirim dari `noreply@rideons.app` ketika `RESEND_API_KEY` diisi.
- **Target Perbaikan:** Tambahkan helper `sendTwoWaySupportEmail(...)` (prioritas Gmail SMTP → fallback Resend dengan header `Reply-To: GMAIL_USER`) khusus untuk balasan tiket CS.

### F2. Konteks MySQL `ai-service` Belum Lengkap & Belum Ada Safe Action Otomatis (`Bagian 7D.2–7D.3`)
- **Lokasi:** `services/ai-service/internal/context/reader.go:66-200`, `services/ai-service/main.go`
- **Masalah:**
  1. `readCustomerSnapshot` hanya membaca 5 nama `stores` dan 3 `orders` terakhir — belum membaca tabel `store_menus` (menu & harga nyata untuk AI Food Recommender) dan `qris_transactions` (untuk menjawab status transaksi QRIS).
  2. `readStoreSnapshot` belum membaca tabel `withdrawals` (untuk menjawab status pencairan saldo Mitra Toko).
  3. Belum ada *safe action* terverifikasi (misal: fungsi batalkan pesanan otomatis hanya bila status masih `CREATED`/`SEARCHING_DRIVER`, dan pembuatan baris `support_tickets` otomatis dari chat CS AI saat masalah butuh eskalasi ke Admin manusia).

### F3. Rumus Tarif Default `pricing_rules` & `extra_stop_fee` FlexSend Belum Sesuai (`Bagian 8.5`)
- **Lokasi:** `docker/mysql/init/01_schema.sql`, `docker/mysql/init/02_seed_lhokseumawe.sql:128-131`, `services/rideon-api/handlers_orders.go`
- **Perbandingan Spesifikasi vs Implementasi Saat Ini:**

| Layanan | Kesepakatan `docs/15` Bagian 8.5 | Implementasi Seeder Saat Ini |
|---|---|---|
| `RIDE_MOTOR` (FlexRide Motor) | Base `Rp 8.000` (≤2 km) + `Rp 2.500/km`, App Fee `Rp 2.000` | Base `5.000` + `2.200/km`, Min `8.000`, App Fee `0` |
| `RIDE_MOBIL` (FlexRide Mobil) | Base `Rp 15.000` (≤2 km) + `Rp 4.000/km`, App Fee `Rp 3.000` | Base `12.000` + `4.500/km`, Min `18.000`, App Fee `0` |
| `FLEX_FOOD` | Base `Rp 6.000` (≤2 km) + `Rp 2.000/km`, App Fee `Rp 2.000` | Base `5.000` + `2.200/km`, Min `8.000`, App Fee `0` |
| `FLEX_SEND` | Base `Rp 8.000` (≤2 km) + `Rp 2.500/km` + **`Rp 3.000`/lokasi singgah tambahan**, App Fee `Rp 2.000` | Base `6.000` + `2.500/km`, Min `10.000`, App Fee `0`, **`extra_stop_fee` belum ada** |

- **Target Perbaikan:** Tambahkan migrasi idempoten kolom `base_distance_km` (default `2.00`) dan `extra_stop_fee` (default `0`, `3000` untuk `FLEX_SEND`) di `pricing_rules`, perbarui seeder & rumus `calculateDeliveryFee` di `rideon-api` (serta form Pengaturan Tarif di Web Admin).

### F4. Sisa Simulasi & State Lokal di `apps/customer_app` & `apps/driver_app` (`Bagian 8.5, 8.12, 8.13`)
- **FlexRide QRIS masih simulasi 5 detik:** `apps/customer_app/lib/features/flexride/presentation/modules/vehicle_selection/vehicle_selection_sheet.dart:58-65` masih menggunakan timer dummy 5 detik (`Saldo Berhasil Masuk`) sebelum konfirmasi pesanan — harus diganti dengan tampilan QRIS dinamis nyata dari `POST /v1/orders` (`payg`) + polling/listener status `PAID`.
- **Koordinat pickup/dropoff FlexRide & Rekomendasi Wisata masih hardcoded:** `apps/customer_app/lib/features/flexride/presentation/pages/flexride_screen.dart:118-210` memanggil `estimateOrder`/`createOrder`/OSRM dengan koordinat default `5.2041, 97.0638` → `5.2015, 97.0619` alih-alih meneruskan `LatLng` aktual dari hasil pencarian OSM Nominatim/GPS maupun koordinat destinasi wisata di `apps/customer_app/lib/features/home/presentation/pages/beranda_screen.dart:93-102`.
- **Chat Customer ↔ Driver belum sinkron antar HP:** `apps/customer_app/lib/features/chat/presentation/pages/chat_screen.dart` dan `apps/driver_app/lib/screens/chat/chat_detail_screen.dart:49` baru menyimpan pesan di memori lokal `_messages` — perlu dihubungkan ke RTDB `/order_chats/{orderId}` (atau endpoint `rideon-api` + RTDB) agar pesan masuk real-time antar HP.
- **Tombol Favorit di Beranda & FlexFood Grid belum simpan ke MySQL + katalog dikunci session:**
  - `apps/customer_app/lib/features/home/presentation/modules/pilihan_terlaris/food_section_view.dart:41,76-81` dan `apps/customer_app/lib/features/flexfood/presentation/modules/food_grid/food_grid_view.dart:49,226-243` baru toggle favorit secara lokal (hanya `favorit_screen.dart` yang memanggil API).
  - Fetch `GET /v1/menus` di kedua file tersebut juga masih mensyaratkan `api.hasSession`, padahal endpoint katalog bersifat publik.

### F5. Gap Fitur & Keamanan Minor di Web Admin (`apps/admin-RideOn`) (`Bagian 8.2 & 8.13`)
- **Belum ada UI CRUD Promo (`promotions`):** `apps/admin-RideOn/src/components/dashboard.tsx` belum memiliki menu/form untuk menambah, mengedit, atau menonaktifkan promo di tabel `promotions` (padahal `Bagian 8.13` mensyaratkan promo dikelola dari Web Admin dan endpoint `/v1/promotions` sudah tersedia di `rideon-api`).
- **Registrasi Customer tidak tercatat di tabel `registrations`:** `docker/mysql/init/01_schema.sql:179` membatasi `applicant_role ENUM('DRIVER', 'STORE')`, sehingga customer baru tidak masuk ke daftar `Pendaftaran Baru` berstatus `APPROVED` seperti tertulis pada `Bagian 8.2`.
- **Prefill password Admin di layar Login:** `apps/admin-RideOn/src/app/login/page.tsx:9-10` masih mengisi default `useState` dengan `admin@rideons.app` dan `RideOnAdmin2026!`. Harus dikosongkan (`""`) agar kredensial tidak terekspos di bundle JS produksi `admin.rideons.app`.

---

## 4. Kategori 3 — Deviasi Minor & Item yang Wajar Belum Dikerjakan

### D1. Deviasi Minor Teknis (Tidak Memblokir Fungsi Inti, Perlu Dirapikan Sebelum OCI)
1. **Belum ada Landing Page `https://rideons.app` (`Bagian 5C`):** `docker/nginx/nginx.conf` belum memiliki server block / halaman statis untuk domain utama `rideons.app` (unduh APK Customer/Driver/Toko & halaman Kebijakan Privasi).
2. **Konvensi Nama Image Podman di `compose.yaml` (`Bagian 6B`):** Saat ini masih tertulis `mysql:8.0` dan `nginx:alpine`; sesuai `docs/15` Bagian 6B sebaiknya memakai registry penuh `docker.io/library/mysql:8.0` dan `docker.io/library/nginx:alpine` agar tidak memicu prompt interaktif di lingkungan Podman/Ubuntu server.
3. **Perbedaan Port Internal Container (Non-Breaking):** `payg:8082`, `ai-service:8083`, `wa-gateway:3100` di `compose.yaml` (vs ilustrasi `8085`, `8086`, `3000` di diagram `Bagian 5C/6C`). Karena seluruh trafik melewati Nginx reverse proxy (`/pay/`, `/ai/`, `/wa/`), perbedaan port internal ini tidak memengaruhi klien — cukup jaga konsistensi internal.
4. **Penamaan Endpoint Konfirmasi Toko (Non-Breaking):** Backend & `page_toko` memakai `POST /v1/orders/{id}/store-confirm` (di `Bagian 4` tertulis `/accept-store`). Boleh tambahkan route alias `/accept-store` di `rideon-api` agar kompatibel 100% dengan dokumen tanpa memecah klien existing.
5. **Kebersihan File Lokal Sensitif:** Pastikan `services/wa-gateway/.env` dan `services/wa-gateway/storage/sessions/*` tetap ter-ignore oleh `.gitignore` (sudah tercatat di `.gitignore`) dan tidak ikut masuk git commit.

### D2. Item yang Wajar Belum Dikerjakan (Sesuai Status Proyek Saat Ini)
1. **Tahap 6B — Deployment VM Oracle Cloud (`rideon-prod`, ARM64 4 OCPU / 24 GB RAM):** Instalasi Podman di Ubuntu ARM64, konfigurasi Cloudflare DNS (`Full (Strict)`), sertifikat TLS Let's Encrypt/Certbot, pengaktifan blok HTTPS `:443` di `docker/nginx/nginx.conf`, dan build APK rilis.
2. **Pengaturan Manual & Kredensial Eksternal (Belum Anda Jalankan):**
   - Pengisian variabel kosong pada `.env` (`NEXT_PUBLIC_FIREBASE_API_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID`, `RESEND_API_KEY`, `GMAIL_USER`, `GMAIL_APP_PASSWORD`, `PAYG_STATIC_QRIS`).
   - Penempatan `secrets/firebase-service-account.json` dan 3 file `google-services.json` (`customer_app`, `driver_app`, `page_toko`).
   - Konfigurasi aplikasi MacroDroid di HP Android merchant untuk meneruskan notifikasi QRIS masuk ke `payg`.
   - Penambahan API Key provider AI (Gemini / Groq / OpenAI-compatible) melalui Web Admin.
   - Scan QR WhatsApp Baileys melalui Web Admin untuk mengganti mode sandbox (`GATEWAY_SANDBOX_MODE=false`).

---

## 5. Tahapan Pengerjaan Remediasi untuk AI & Daftar Skill per Tahap

Agar pengerjaan perbaikan bersih, teruji, tidak merusak fitur Tahap 1–6A yang sudah lulus, dan hemat konteks/kuota, bagi pekerjaan AI menjadi **6 tahap berurutan (R1 → R6)**.

> **Aturan Global untuk Setiap Tahap AI:**
> - **JANGAN** mengedit `docs/15-ecosystem-infrastructure-and-integration-discussion.md`.
> - **JANGAN** mengarang kredensial/secret asli (tetap gunakan fallback aman untuk lokal & unit test).
> - Baca `SKILL.md` untuk seluruh skill wajib di tahap tersebut sebelum mengedit kode.
> - Jalankan test regresi terkait di akhir setiap tahap sebelum lanjut ke tahap berikutnya.

---

### Tahap R1 — Keamanan AI Service, Migrasi Skema & Tarif `8.5`, Dual-Email CS 2 Arah, & Konteks AI
**Fokus Masalah yang Dibereskan:** `K1`, `F1`, `F2`, `F3`, sebagian `F5` (`registrations.applicant_role`), `D1.4` (alias `/accept-store`).

- **Skill Wajib Dipakai:**
  - `migration` — migrasi skema MySQL idempoten & kompatibel-mundur (`pricing_rules`, `registrations`).
  - `antislop-code` — menjaga kebersihan komentar & kode Go.
  - `ponytail-review` — audit diff & jalur kritis keamanan (JWT middleware, query SQL, kalkulasi ongkir).
- **Ruang Lingkup Pekerjaan AI:**
  1. **`services/ai-service/`**:
     - Tambahkan middleware verifikasi JWT `ADMIN` (`JWT_SECRET`) pada `/ai/providers` & `/ai/providers/:id`, serta dukungan method `DELETE /ai/providers/:id`.
     - Perkaya `internal/context/reader.go`: tambahkan query read-only `store_menus` & `qris_transactions` ke `readCustomerSnapshot`, dan query `withdrawals` ke `readStoreSnapshot`.
     - Tambahkan *safe action* terverifikasi pada endpoint chat AI: (a) auto-create `support_tickets` bila AI/user meminta eskalasi ke Admin, dan (b) auto-cancel order milik user hanya bila status masih `CREATED` atau `SEARCHING_DRIVER`.
  2. **MySQL Schema & Seeder (`docker/mysql/init/` + migrasi runtime idempoten di `rideon-api`)**:
     - Tambah kolom `base_distance_km DECIMAL(5,2) NOT NULL DEFAULT 2.00` dan `extra_stop_fee BIGINT NOT NULL DEFAULT 0` pada tabel `pricing_rules` (beserta `ALTER TABLE` idempoten saat startup bagi volume MySQL existing).
     - Selaraskan default `pricing_rules` ke kesepakatan `docs/15` Bagian 8.5 (`RIDE_MOTOR`: 8000 / 2500 / app 2000; `RIDE_MOBIL`: 15000 / 4000 / app 3000; `FLEX_FOOD`: 6000 / 2000 / app 2000; `FLEX_SEND`: 8000 / 2500 / extra_stop 3000 / app 2000).
     - Perluas `registrations.applicant_role` menjadi `ENUM('CUSTOMER', 'DRIVER', 'STORE')` dan catat pendaftar Customer baru ke tabel `registrations` berstatus `APPROVED`.
  3. **`services/rideon-api/`**:
     - Perbarui rumus kalkulasi tarif (`calculateDeliveryFee`) agar menghitung tarif flat untuk `distance_km <= base_distance_km`, per-km selebihnya, plus `extra_stops * extra_stop_fee` untuk `FLEX_SEND`, plus `app_fee`.
     - Tambahkan helper `sendTwoWaySupportEmail()` (prioritas Gmail SMTP → fallback Resend + `Reply-To`) dan pakai di handler balasan tiket CS (`handlers_admin.go`).
     - Tambahkan alias route `POST /v1/orders/{id}/accept-store` yang mengarah ke handler `store-confirm`.
     - Tambahkan endpoint profil/alamat tersimpan customer (`GET/POST/DELETE /v1/auth/addresses`, `PATCH /v1/auth/password`, serta `PATCH /v1/auth/me` menerima `fcm_token`, `phone`, `email`) untuk menggantikan ketergantungan Firestore di Tahap R5.
- **Definition of Done (DoD):**
  - `go test ./...` lulus di `services/rideon-api`, `services/ai-service`, dan `services/payg`.
  - Request `GET/POST/PUT/DELETE /ai/providers` tanpa JWT `ADMIN` mengembalikan `401/403`; dengan JWT `ADMIN` mengembalikan `200/201`.
  - Test kalkulasi ongkir `FLEX_RIDE`, `FLEX_FOOD`, dan `FLEX_SEND` (dengan `extra_stops = 2`) cocok 100% dengan tabel Bagian 8.5.

---

### Tahap R2 — Alur QRIS Pre-Payment Gate, FCM Push End-to-End Backend, & Sinkronisasi RTDB/Chat
**Fokus Masalah yang Dibereskan:** `K2` (sisi backend), `K3` (sisi backend), `K5` (sisi backend).

- **Skill Wajib Dipakai:**
  - `antislop-code`
  - `ponytail-review`
- **Ruang Lingkup Pekerjaan AI:**
  1. **Alur QRIS Pre-Payment Gate (`services/rideon-api/handlers_orders.go` & `services/payg/main.go`)**:
     - Saat `POST /v1/orders` dengan `payment_method = 'QRIS'`, simpan order dengan `status = 'CREATED'` dan `payment_status = 'PENDING'`; **jangan** broadcast ke `order_offers` RTDB atau memunculkan di tab "Pesanan Baru" toko sebelum lunas.
     - Perbarui `GET /v1/orders` untuk role `STORE` & `DRIVER` agar tidak menampilkan order QRIS yang masih `CREATED` / `PENDING`.
     - Perbarui `services/payg/main.go` agar memanggil webhook internal `POST /v1/internal/qris-paid` untuk **kedua** jenis transaksi: `ORDER_PAYMENT` maupun `DRIVER_TOPUP` (sertakan `user_id`, `amount`, `purpose`, `order_id`).
     - Perbarui `handleInternalQRISPaid` di `rideon-api`:
       - Jika `ORDER_PAYMENT`: transisikan `CREATED` → `WAITING_STORE_CONFIRM` (untuk `FLEX_FOOD` + FCM ke owner toko & customer) atau `CREATED` → `SEARCHING_DRIVER` + `offer_expires_at` + broadcast RTDB `order_offers` (untuk `FLEX_RIDE`/`FLEX_SEND` + FCM ke driver eligible & customer).
       - Jika `DRIVER_TOPUP`: kirim FCM push konfirmasi saldo masuk ke `user_id` driver + update node RTDB bila perlu.
  2. **Endpoint Chat Pesanan (Fallback & Persistensi) + RTDB Contract**:
     - Tetapkan kontrak tunggal RTDB untuk `driver_locations/{driver_id}` (`lat`, `lng`, `heading`, `is_online`, `driver_id`, `updated_at`), `order_chats/{order_id}/{msg_id}`, dan `calls/{order_id}`.
     - Tambahkan endpoint ringan `GET/POST /v1/orders/{id}/messages` (opsional tersimpan/bridge ke RTDB `order_chats/{orderId}`) atau standar RTDB `order_chats/{orderId}` yang digunakan konsisten oleh `customer_app` dan `driver_app`.
- **Definition of Done (DoD):**
  - Order `FLEX_FOOD` QRIS berstatus `CREATED` sampai `payg` melunasi → otomatis pindah ke `WAITING_STORE_CONFIRM` dan memicu `notifyUserAsync`.
  - Order `FLEX_RIDE` QRIS berstatus `CREATED` sampai lunas → otomatis pindah ke `SEARCHING_DRIVER` dan memicu broadcast `order_offers`.
  - Unit test Go untuk `handleInternalQRISPaid` (order & top-up) dan `PATCH /v1/auth/me` (`fcm_token`) lulus.

---

### Tahap R3 — Web Admin Next.js (`apps/admin-RideOn`) & Infrastruktur Nginx/Podman
**Fokus Masalah yang Dibereskan:** `F5`, `D1.1`, `D1.2`.

- **Skill Wajib Dipakai:**
  - `impeccable` — konsistensi desain & UX tab baru (CRUD Promo & Tarif `extra_stop_fee`).
  - `ui-styling` — styling konsisten dengan design token Web Admin yang sudah ada.
  - `chrome-devtools` & `a11y-debugging` — verifikasi UI live di browser & aksesibilitas tanpa console error.
  - `antislop-code`, `ponytail-review`.
- **Ruang Lingkup Pekerjaan AI:**
  1. **`apps/admin-RideOn/`**:
     - Kosongkan prefill `email` dan `password` di `src/app/login/page.tsx` (hilangkan `RideOnAdmin2026!` dari client bundle; cukup gunakan placeholder).
     - Tambahkan UI **Manajemen Promo** (List, Tambah, Aktif/Nonaktif, Hapus) terhubung ke `/v1/promotions` di `dashboard.tsx`.
     - Perbarui form **Pengaturan Tarif (`pricing_rules`)** agar mendukung edit `base_distance_km` dan `extra_stop_fee` (FlexSend).
     - Pastikan pemanggilan `/ai/providers` dari Web Admin menyertakan header `Authorization: Bearer <admin-token>` dan tambahkan tombol Hapus (`DELETE`) provider AI.
     - Tampilkan filter/badge `Customer` di tab `Pendaftaran Baru` (`registrations`).
  2. **Infrastruktur (`compose.yaml` & `docker/nginx/`)**:
     - Ubah image di `compose.yaml` menjadi registry penuh `docker.io/library/mysql:8.0` dan `docker.io/library/nginx:alpine`.
     - Tambahkan halaman statis landing page ringan (`docker/nginx/landing/index.html` — tombol unduh APK Customer/Driver/Toko & halaman Kebijakan Privasi) dan routing server block untuk `rideons.app` / `www.rideons.app` (serta route lokal `/landing` untuk pratinjau lokal) di `docker/nginx/nginx.conf`.
- **Definition of Done (DoD):**
  - `npm run build` di `apps/admin-RideOn` sukses tanpa warning/error TypeScript.
  - Container `admin` dan `nginx` rebuild & `Up (healthy)`.
  - Verifikasi visual via browser: login tanpa prefill password, CRUD Promo jalan, CRUD Provider AI berjalan dengan JWT, landing page terbuka normal.

---

### Tahap R4 — Remediasi `apps/driver_app` & `apps/page_toko` (FCM, RTDB `driver_locations` + `onDisconnect`, WebRTC 2 Arah, Chat Sync, Hapus Firestore)
**Fokus Masalah yang Dibereskan:** `K2`, `K3`, `K6`, `K7` (sisi `driver_app`), `F4` (sisi chat driver).

- **Skill Wajib Dipakai:**
  - `dart-run-static-analysis`
  - `flutter-use-http-package`
  - `flutter-implement-json-serialization`
  - `dart-add-unit-test`
  - `flutter-add-widget-test`
  - `flutter-fix-layout-issues`
  - `dart-fix-runtime-errors`
  - `antislop-code`, `ponytail-review`
- **Ruang Lingkup Pekerjaan AI:**
  1. **`apps/page_toko/`**:
     - Tambahkan service FCM (`TokoPushService`) dengan graceful fallback: minta izin notifikasi, ambil token `FirebaseMessaging`, kirim ke `PATCH /v1/auth/me` (`fcm_token`) setelah login/restore session, tangani foreground notification (`onMessage`) untuk pesanan baru/QRIS lunas.
  2. **`apps/driver_app/`**:
     - Hapus dependensi `cloud_firestore` dari `pubspec.yaml` dan bersihkan seluruh sisa `_saveDriverProfile` Firestore di `lib/services/driver_service.dart`.
     - Selaraskan `updateDriverLocation()` agar selalu menulis ke `driver_locations/{mysqlDriverId}` dengan key `lat`, `lng`, `heading`, `is_online`, `driver_id`, `updated_at` (menggunakan `.update(...)` agar tidak menghapus metadata `name`/`vehicle_type`), serta teruskan `driverId` aktual dari `radar_screen.dart`.
     - Pasang `onDisconnect().update({'is_online': false})` pada `driver_locations/{driverId}` dan `driver_presence/{driverId}` saat driver mengaktifkan status Online.
     - Tambahkan `DriverPushService` (`firebase_messaging`) yang mengirim `fcm_token` ke `PATCH /v1/auth/me` dengan graceful fallback.
     - Lengkapi `lib/services/webrtc_call_service.dart` dengan listener panggilan masuk di `/calls/{orderId}`, metode `answerCall()`, `rejectCall()`, dan overlay pop-up panggilan masuk.
     - Hubungkan `lib/screens/chat/chat_detail_screen.dart` ke RTDB `order_chats/{orderId}` (dan/atau `GET/POST /v1/orders/{id}/messages`) agar sinkron 2 arah dengan Customer App.
- **Definition of Done (DoD):**
  - `grep -rn "cloud_firestore" apps/driver_app/ apps/page_toko/` menghasilkan 0 baris.
  - `flutter analyze` = `0 issues` di `apps/page_toko` dan `apps/driver_app`.
  - Seluruh unit & widget test lama + test baru (FCM payload, RTDB key `lat/lng`, WebRTC answer flow, chat sync) lulus 100%.

---

### Tahap R5 — Remediasi `apps/customer_app` (Hapus Total Firestore, Perbaiki Status Order, Single QRIS, FlexRide Nyata, WebRTC 2 Arah, Chat Sync, FCM, Favorit)
**Fokus Masalah yang Dibereskan:** `K2`, `K4`, `K5`, `K6`, `K7` (sisi `customer_app`), `F4`.

- **Skill Wajib Dipakai:**
  - `dart-run-static-analysis`
  - `flutter-use-http-package`
  - `flutter-implement-json-serialization`
  - `dart-add-unit-test`
  - `flutter-add-widget-test`
  - `flutter-fix-layout-issues`
  - `dart-fix-runtime-errors`
  - `antislop-code`, `ponytail-review`
- **Ruang Lingkup Pekerjaan AI:**
  1. **Hapus Total `cloud_firestore`**:
     - Hapus `cloud_firestore` dari `apps/customer_app/pubspec.yaml`.
     - Migrasikan 16+ file pengaturan/pencarian (`lokasi_anda_screen`, `nomor_wa_screen`, `alamat_email_screen`, `keamanan_akun_screen`, `pengaturan_akun_screen`, `ubah_profil_screen`, `email_verification_dialog`, `main_screen`, `auth_service`, `global_search_screen`, `location_picker_module`, `osm_nominatim_service`) ke `CustomerApiService` (MySQL `rideon-api`) + `SharedPreferences` untuk cache/riwayat pencarian lokal.
  2. **Perbaiki Mapping Status Order (`K4`)**:
     - Selaraskan `food_tracking_view.dart`, `flexride_screen.dart`, dan `flexsend_screen.dart` agar membaca status enum MySQL aktual (`CREATED`, `WAITING_STORE_CONFIRM`, `STORE_PREPARING`, `SEARCHING_DRIVER`, `DRIVER_ASSIGNED`, `DRIVER_AT_PICKUP`, `IN_TRANSIT`, `DELIVERED`, `COMPLETED`, `CANCELLED`).
  3. **Hapus Double QRIS & Hilangkan Simulasi 5 Detik FlexRide (`K5` & `F4`)**:
     - Di `checkout_view.dart` dan `flexride_screen.dart`, gunakan langsung objek `qris` dari response `POST /v1/orders` (jangan panggil `POST /pay/qris/generate` kedua kalinya).
     - Ganti simulasi timer 5 detik di `vehicle_selection_sheet.dart` dengan dialog QRIS `payg` nyata (SVG QR + kode unik + status polling/RTDB sampai `PAID`).
  4. **Koordinat Nyata FlexRide & Wisata, Favorit MySQL, Chat Sync, WebRTC 2 Arah, & FCM (`K2`, `K6`, `F4`)**:
     - Teruskan koordinat `LatLng` aktual hasil Nominatim/GPS/destinasi wisata ke `estimateOrder`, `createOrder`, dan OSRM di `flexride_screen.dart` & `beranda_screen.dart`.
     - Hubungkan tombol ikon hati di `food_section_view.dart` dan `food_grid_view.dart` ke `addFavorite`/`deleteFavorite` API, dan izinkan fetch `GET /v1/menus` tanpa mensyaratkan login (`hasSession`).
     - Hubungkan `chat_screen.dart` ke `order_chats/{orderId}` (sinkron dengan `driver_app`).
     - Lengkapi `webrtc_call_service.dart` dengan incoming call listener + `answerCall()`.
     - Tambahkan `CustomerPushService` (`firebase_messaging`) yang mendaftarkan `fcm_token` ke `PATCH /v1/auth/me` dengan graceful fallback.
- **Definition of Done (DoD):**
  - `grep -rn "cloud_firestore" apps/customer_app/` menghasilkan 0 baris.
  - `flutter analyze` = `0 issues` di `apps/customer_app`.
  - Seluruh unit & widget test lama + test baru (status mapping enum MySQL, single QRIS call, koordinat nyata, favorit, WebRTC answer, FCM token sync) lulus 100%.

---

### Tahap R6 — Verifikasi E2E Lintas-Aplikasi & Tahap 6B Go-Live VM OCI (`rideons.app`)
**Fokus:** Memastikan seluruh ekosistem sinkron 100% di lokal + eksekusi deployment produksi setelah Anda menyelesaikan Setup Manual (Bagian 6).

- **Skill Wajib Dipakai:**
  - `ponytail-review` (audit akhir perubahan sebelum deploy)
  - `chrome-devtools` (verifikasi Web Admin produksi & Peta Aktif SSE)
  - `dart-run-static-analysis` (cek akhir sebelum `flutter build apk --release`)
- **Ruang Lingkup Pekerjaan AI:**
  1. Perbarui script E2E lokal untuk menguji semua perbaikan: `/ai/providers` auth (`401` vs `200`), tarif `FLEX_SEND` + `extra_stop_fee`, QRIS `CREATED` → `payg` webhook → `WAITING_STORE_CONFIRM` (tanpa double QRIS), FCM token tersimpan di `users.fcm_token`, Web Admin CRUD Promo, dan registrasi customer tercatat di `registrations`.
  2. Setelah Anda mengonfirmasi VM OCI + DNS Cloudflare + kredensial manual siap: bantu konfigurasi `podman compose up -d --build`, aktifkan SSL Certbot `:443` di `docker/nginx/nginx.conf`, validasi HTTPS `rideons.app`, `admin.rideons.app`, dan `api.rideons.app`, serta bangun APK rilis untuk ke-3 app Flutter.

---

### Template Prompt Singkat untuk Menjalankan Tiap Tahap AI

Saat ingin menyuruh AI mengeksekusi satu tahap (misal Tahap R1), cukup kirim prompt seperti ini:

```text
Kerjakan HANYA Tahap R1 sesuai docs/16-audit-kepatuhan-remediasi-dan-panduan-setup-manual.md
(mengacu SSOT docs/15-ecosystem-infrastructure-and-integration-discussion.md).
JANGAN edit docs/15, JANGAN kerjakan Tahap R2-R6 dulu, dan JANGAN panggil swarm.
Baca SKILL.md untuk skill wajib Tahap R1 (migration, antislop-code, ponytail-review) sebelum mengedit kode,
lalu verifikasi seluruh Definition of Done Tahap R1.
```
*(Ganti `R1` dan daftar skill-nya sesuai tabel Tahap `R2`, `R3`, `R4`, `R5`, atau `R6` di atas.)*

---

## 6. Panduan Lengkap Mengisi Setup Manual & Langkah Lanjut ke Produksi (OCI)

### Urutan Kerja yang Disarankan
1. **Jalankan Tahap R1 s.d. R5 dulu bersama AI** (bisa selesai 100% di komputer lokal tanpa butuh kredensial produksi).
2. **Kerjakan Langkah Manual 1 s.d. 5 di bawah** untuk menghidupkan layanan eksternal (Firebase, Email, QRIS, AI Key, WA Gateway).
3. **Lakukan Uji Multi-HP di LAN Lokal (Langkah 6)** menggunakan 2–3 HP fisik atau emulator.
4. **Baru lanjut ke Langkah 7 + Tahap R6 (Deploy VM OCI `rideons.app`)**.

---

### Langkah 1 — Setup Firebase (`rideon-lhokseumawe`) — Auth, RTDB, & FCM (Tanpa Firestore)

1. Buka [Firebase Console](https://console.firebase.google.com/) → buat/pilih project **`rideon-lhokseumawe`**.
2. **Aktifkan HANYA 3 layanan berikut** (sesuai `docs/15` Bagian 2B, **jangan buat/aktifkan Cloud Firestore**):
   - **Authentication → Sign-in method:** aktifkan **Email/Password** dan **Google**.
   - **Realtime Database → Create Database:** pilih lokasi **Singapore (`asia-southeast1`)** sehingga URL-nya `https://rideon-lhokseumawe-default-rtdb.asia-southeast1.firebasedatabase.app`.
   - **Cloud Messaging (FCM):** aktif secara otomatis di project Firebase (API V1).
3. **Daftarkan 3 Aplikasi Android** di *Project Settings → Your apps → Add app (Android)* dengan Package Name **persis** (`docs/15` Bagian 10):
   - Customer App: `com.rideon.customer` → unduh `google-services.json` → simpan ke `apps/customer_app/android/app/google-services.json`.
   - Driver App: `com.rideon.driver` → unduh `google-services.json` → simpan ke `apps/driver_app/android/app/google-services.json`.
   - Mitra Toko App: `com.rideon.page_toko` → unduh `google-services.json` → simpan ke `apps/page_toko/android/app/google-services.json`.
   - *(Wajib agar Google Sign-In berhasil di Android)*: Ambil fingerprint SHA-1 & SHA-256 keystore debug/release Anda (`cd apps/customer_app/android && ./gradlew signingReport`) lalu masukkan ke masing-masing Android App di Firebase Console, kemudian unduh ulang `google-services.json`.
4. **Daftarkan 1 Web App** (untuk Web Admin Next.js Peta Aktif RTDB):
   - Salin `apiKey` → isi ke `.env` pada `NEXT_PUBLIC_FIREBASE_API_KEY`.
   - Salin `Web Client ID` (dari *Authentication → Google → Web SDK configuration*) → isi ke `.env` pada `GOOGLE_WEB_CLIENT_ID`.
5. **Unduh Service Account JSON (untuk `rideon-api`)**:
   - *Project Settings → Service accounts → Generate new private key* → simpan file JSON ke:
     `secrets/firebase-service-account.json` (file ini sudah masuk `.gitignore`, tidak akan ter-commit).
6. **Atur Realtime Database Rules (Tahap Awal / Produksi):**
   - Pastikan node `driver_locations`, `live_orders`, `order_offers`, `order_chats`, dan `calls` dapat dibaca/ditulis oleh pengguna terautentikasi dan Service Account Admin.

---

### Langkah 2 — Setup Dual-Email (Resend 1-Arah + Gmail App Password CS 2-Arah)

1. **Resend (Email Sistem 1 Arah — `noreply@rideons.app`):**
   - Daftar di [Resend](https://resend.com/) → menu **Domains** → tambah domain `rideons.app`.
   - Salin record DNS (**SPF, DKIM, DMARC**) yang diberikan Resend ke **Cloudflare DNS** domain `rideons.app` (Proxy status: **DNS Only / awan abu-abu** untuk record TXT/MX).
   - Klik **Verify** di Resend → buat **API Key** → isi di `.env`:
     - `RESEND_API_KEY=re_xxxxxxxxxxxx`
     - `RESEND_FROM_EMAIL=noreply@rideons.app`
2. **Gmail Resmi Admin (Failover OTP + Primary Balasan Tiket CS 2 Arah):**
   - Masuk ke akun Gmail resmi operasional RideOn → buka [Google Account Security](https://myaccount.google.com/security).
   - Aktifkan **2-Step Verification**, lalu buka **App Passwords** → buat App Password baru bernama `RideOn Backend`.
   - Salin sandi 16 karakter (tanpa spasi) → isi di `.env`:
     - `GMAIL_USER=cs.rideon@gmail.com` *(sesuaikan email Gmail Anda)*
     - `GMAIL_APP_PASSWORD=xxxxxxxxxxxxxxxx`

---

### Langkah 3 — Setup PayG Static QRIS & MacroDroid Listener Android

1. **Ambil String Static QRIS Merchant Anda:**
   - Scan gambar QRIS statis rekening penampung RideOn (BCA/BSI/GoPay Merchant/Dana Bisnis/dll.) menggunakan aplikasi QR scanner mentah untuk mendapatkan string EMVCo yang diawali `000201010211...` dan diakhiri `...6304XXXX`.
   - Isi ke `.env`:
     - `PAYG_STATIC_QRIS=000201010211...`
   - *(Opsional)*: Anda juga dapat mengubah/memperbarui string QRIS ini sewaktu-waktu lewat Web Admin → menu **Keuangan & QRIS**.
2. **Pasang & Konfigurasi MacroDroid di HP Android Penerima Notifikasi QRIS:**
   - Install aplikasi **MacroDroid** di HP yang terpasang aplikasi merchant QRIS.
   - Buat Macro baru:
     - **Trigger:** `Notification Received` → pilih aplikasi merchant QRIS Anda → *Text Content*: cocokkan kata kunci uang masuk (misal `berhasil`, `diterima`, atau `Rp`).
     - **Action:** `HTTP Request`
       - **Method:** `POST`
       - **URL (Lokal LAN):** `http://<IP-LAN-KOMPUTER>:8088/pay/webhook/macrodroid`
       - **URL (Produksi OCI):** `https://api.rideons.app/pay/webhook/macrodroid`
       - **Content Type:** `application/json`
       - **Header:** `X-PayG-Secret: <nilai PAYG_WEBHOOK_SECRET di .env>`
       - **Body JSON:**
         ```json
         {
           "notification_text": "{not_title} {not_body}",
           "verified_by": "macrodroid-android"
         }
         ```
   - `payg` akan mengekstrak nominal `Rp ...` (termasuk kode unik `1..999`), mencocokkan dengan transaksi `PENDING` yang aktif, melunasi order/top-up secara otomatis, dan men-trigger `rideon-api`.

---

### Langkah 4 — Pengisian File `.env` (Lokal vs Produksi)

Salin dari `.env.example` ke `.env` lalu pastikan variabel berikut terisi dengan benar:

| Variabel `.env` | Nilai Lokal (Testing LAN) | Nilai Produksi (VM OCI) | Keterangan |
|---|---|---|---|
| `APP_ENV` | `development` | `production` | Mode aplikasi backend |
| `PUBLIC_BASE_URL` | `http://<IP-LAN>:8088` | `https://api.rideons.app` | Base URL publik upload & link |
| `NEXT_PUBLIC_API_BASE_URL` | `http://localhost:8088` | `https://api.rideons.app` | API base untuk Web Admin |
| `MYSQL_ROOT_PASSWORD` / `MYSQL_PASSWORD` | password lokal | **Acak kuat ≥24 karakter** | Jangan pakai password default di OCI |
| `JWT_SECRET` | minimal 32 karakter | **Acak kuat ≥48 karakter** | Sama di `rideon-api`, `payg`, `ai-service` |
| `AI_ENCRYPTION_KEY` | tepat 32 byte ASCII | **Acak tepat 32 karakter** | Kunci AES-256-GCM tabel `ai_providers` |
| `WHATSAPP_GATEWAY_SECRET` | rahasia internal | **Acak kuat ≥32 karakter** | Auth internal `rideon-api` ↔ `wa-gateway` |
| `PAYG_WEBHOOK_SECRET` | rahasia webhook | **Acak kuat ≥32 karakter** | Header `X-PayG-Secret` MacroDroid |
| `GATEWAY_SANDBOX_MODE` | `true` (atau `false` jika sudah scan QR) | `false` | `false` = kirim WA sungguhan via Baileys |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | dari Firebase Web App | sama | Untuk Peta Aktif SSE Web Admin |
| `GOOGLE_WEB_CLIENT_ID` | dari Firebase Auth | sama | Validasi Google Sign-In |
| `RESEND_API_KEY` | API key Resend | sama | OTP & notif 1 arah |
| `GMAIL_USER` & `GMAIL_APP_PASSWORD` | Gmail Admin + 16 char | sama | CS 2 arah + failover OTP |
| `PAYG_STATIC_QRIS` | string EMVCo QRIS Anda | sama | Dasar generate QRIS dinamis |

Setelah `.env` diperbarui, restart container agar env baru terbaca:
```bash
podman compose up -d --build
```

---

### Langkah 5 — Aktivasi WhatsApp Gateway & Provider AI di Web Admin

1. Buka Web Admin (`http://localhost:8088` di lokal atau `https://admin.rideons.app` di produksi) dan login dengan akun Admin (`admin@rideons.app`).
   - *(Untuk produksi, segera ganti password Admin dari password seeder `RideOnAdmin2026!`!)*
2. **Aktifkan WhatsApp Gateway:**
   - Pastikan `GATEWAY_SANDBOX_MODE=false` di `.env` dan container `wa-gateway` sudah di-restart.
   - Buka menu **Pengaturan AI & Tarif** → bagian **WhatsApp Gateway** → scan **QR Code** menggunakan aplikasi WhatsApp di HP nomor operasional RideOn (*Perangkat Tertaut / Linked Devices*).
   - Sesi login akan tersimpan di MySQL tabel `whatsapp_sessions`, sehingga tidak perlu scan ulang saat container restart.
3. **Tambahkan Provider AI Universal:**
   - Masih di menu **Pengaturan AI & Tarif** → bagian **Provider AI Universal** → klik **Tambah Provider**:
     - Contoh Primary (`Priority 1`): Gemini (`gemini_native`, model `gemini-2.5-flash`, API Key dari [Google AI Studio](https://aistudio.google.com/apikey)).
     - Contoh Failover (`Priority 2`): Groq / OpenRouter / DeepSeek (`openai_compatible`, isi `Base URL`, `Model`, dan `API Key`).
   - API Key otomatis terenkripsi AES-256-GCM sebelum masuk MySQL.
   - Klik tombol **Test Prompt AI** untuk memastikan respon sukses.

---

### Langkah 6 — Uji Coba Multi-HP di Jaringan LAN Lokal (Sebelum Deploy OCI)

1. Cek IP LAN komputer Anda (misal `192.168.1.15` dengan `ip -4 addr`).
2. Pastikan port `8088` terbuka di firewall lokal komputer Anda dan seluruh HP terhubung ke Wi-Fi yang sama.
3. Jalankan / install masing-masing app Flutter dengan `--dart-define=API_BASE_URL`:
   ```bash
   # Customer App
   cd apps/customer_app && flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8088

   # Driver App
   cd apps/driver_app && flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8088

   # Mitra Toko App
   cd apps/page_toko && flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8088
   ```
4. **Checklist Uji End-to-End 3 HP + Web Admin:**
   - [ ] Login OTP WA/Email & Google Sign-In berhasil, `users.fcm_token` terisi di MySQL.
   - [ ] Driver Online → titik motor muncul real-time di `Peta Aktif` Web Admin & hilang otomatis jika HP driver dimatikan (`onDisconnect`).
   - [ ] Customer pesan FlexFood QRIS → 1 transaksi QRIS tercipta (`CREATED`), belum masuk toko → bayar QRIS / MacroDroid webhook → lunas otomatis → FCM & pesanan masuk `page_toko` → toko terima → driver terima (16 detik) → status berjalan mulus sampai `COMPLETED` → komisi `5%:5%` tercatat di mutasi.
   - [ ] Chat & panggilan suara WebRTC P2P 2 arah (dering masuk + terima panggilan) tersambung antara Customer & Driver.
   - [ ] Withdraw PIN 6 digit & Klaim Talangan Donasi 2 langkah tampil di Web Admin beserta foto bukti & bisa di-approve.

---

### Langkah 7 — Persiapan & Go-Live Tahap 6B di VM Oracle Cloud (`rideon-prod`)

1. **Provisioning VM OCI Always Free:**
   - Shape: **VM.Standard.A1.Flex (ARM64 Ampere)** — **4 OCPU, 24 GB RAM**, Ubuntu 24.04 LTS, Boot Volume minimal 50–100 GB.
   - Buka Ingress Rules di OCI Security List & UFW Ubuntu hanya untuk port: **`22` (SSH)**, **`80` (HTTP)**, dan **`443` (HTTPS)**. **Jangan pernah membuka port `3306` ke publik.**
2. **Konfigurasi Cloudflare DNS (`rideons.app`):**
   - Buat A Record mengarah ke IP Publik VM OCI:
     - `rideons.app` → `<IP_VM_OCI>` (Proxied)
     - `www.rideons.app` → `<IP_VM_OCI>` (Proxied)
     - `admin.rideons.app` → `<IP_VM_OCI>` (Proxied)
     - `api.rideons.app` → `<IP_VM_OCI>` (Proxied)
   - SSL/TLS Mode di Cloudflare: **`Full (Strict)`**.
   - Pasang Cloudflare Origin Certificate (atau Certbot Let's Encrypt) di VM OCI, lalu aktifkan blok server `:443` pada `docker/nginx/nginx.conf`.
3. **Instalasi Podman & Deploy Stack di VM OCI:**
   ```bash
   sudo apt update && sudo apt install -y podman podman-compose git
   git clone <URL_REPO_RIDEON> /opt/rideon
   cd /opt/rideon
   # Unggah/isi .env produksi & secrets/firebase-service-account.json
   chmod 600 .env secrets/firebase-service-account.json
   podman compose up -d --build
   podman ps
   ```
4. **Build APK Rilis Produksi untuk 3 Aplikasi Flutter:**
   ```bash
   cd apps/customer_app && flutter build apk --release --dart-define=API_BASE_URL=https://api.rideons.app
   cd apps/driver_app   && flutter build apk --release --dart-define=API_BASE_URL=https://api.rideons.app
   cd apps/page_toko    && flutter build apk --release --dart-define=API_BASE_URL=https://api.rideons.app
   ```
   Unggah ketiga file APK rilis tersebut ke direktori statis landing page `https://rideons.app` agar pengguna di Lhokseumawe & Aceh Utara dapat langsung mengunduh.

