# Master Blueprint & Dokumen Lengkap Hasil Diskusi Arsitektur, Infrastruktur, dan Integrasi Ekosistem RideOn

> **Status Dokumen**: **FINAL MASTER BLUEPRINT (Single Source of Truth — Lengkap Tanpa Disingkat)**  
> **Project Firebase**: `rideon-9eb77`  
> **Database Utama**: **MySQL 8.0 (`rideon_db` — Pola I: Single Source of Truth)** + **Firebase RTDB** (Live GPS, Sinyal Real-Time, & WebRTC)  
> **Domain Resmi**: **`rideons.app`** (`rideons.app`, `admin.rideons.app`, `api.rideons.app`)  
> **Peta & Navigasi**: **100% OpenStreetMap (OSM)** (`flutter_map`, `Leaflet`, `OSM Nominatim`, & `OSRM Routing`)  
> **Lingkup Ekosistem**:
> - **3 Aplikasi Mobile Flutter (Native)**: `apps/customer_app` (`com.rideon.customer`), `apps/driver_app` (`com.rideon.driver`), `apps/page_toko` (`com.rideon.page_toko`)
> - **1 Web Admin Dashboard**: `apps/admin-RideOn` (Next.js `16.4.3` + React `19.3.0` + Tailwind CSS `v4` + OpenStreetMap Leaflet)
> - **4 Backend Microservices (`services/` Sejajar di Container `compose.yaml`)**:
>   1. `services/wa-gateway` (Node.js — WhatsApp OTP & Forwarder Chat WA Masuk)
>   2. `services/payg` (Golang — QRIS Dinamis + Kode Unik + Webhook MacroDroid)
>   3. `services/rideon-api` (Golang — Core REST API, Auth JWT, Order, MySQL, RTDB/FCM, Email Resend + Gmail CS, Upload)
>   4. `services/ai-service` (Golang — Engine AI Universal Multi-App & CS AI 24/7)

---

## Bagian 1 — Ringkasan Audit Codebase Saat Ini & Target Integrasi

Berdasarkan pemeriksaan langsung terhadap seluruh file di repository ini:

| Komponen | Kondisi Teramati Saat Ini di Repo | Catatan Kesenjangan (*Gap*) & Target Integrasi |
|---|---|---|
| `apps/customer_app` (`com.rideon.customer`) | `flutter run` aman. Firebase Auth/Core aktif, memanggil [wa_gateway_service.dart](../apps/customer_app/lib/features/auth/data/wa_gateway_service.dart) & [email_otp_service.dart](../apps/customer_app/lib/features/auth/data/email_otp_service.dart), pencarian lokasi terhubung OSM Nominatim (`flutter_map: ^8.3.2`, `latlong2: ^0.10.1`, `geolocator: ^14.1.2`, `geocoding: ^5.0.1`). | • URL di `wa_gateway_service.dart` & `email_otp_service.dart` masih mengarah ke IP lokal (`192.168.100.14:3000`, `10.0.2.2:3000`) → akan diarahkan ke `https://api.rideons.app` (dengan fallback `--dart-define` untuk testing lokal).<br>• Belum ada pengiriman order lintas app; di [checkout_view.dart](../apps/customer_app/lib/features/flexfood/presentation/modules/checkout/checkout_view.dart) verifikasi QRIS masih memakai timer dummy 5 detik → akan dihubungkan ke `services/payg` & `services/rideon-api`. |
| `apps/driver_app` (`com.rideon.driver`) | `flutter run` aman. Firebase terinisialisasi di [main.dart](../apps/driver_app/lib/main.dart). [driver_service.dart](../apps/driver_app/lib/services/driver_service.dart#L118-L140) sudah menulis titik GPS ke RTDB `driver_locations/{uid}` dan status ke `driver_presence/{uid}`. Memiliki layar Radar (`FlexRide`, `FlexFood`, `FlexSend`), Dompet ([wallet_screen.dart](../apps/driver_app/lib/screens/wallet/wallet_screen.dart), [withdraw_screen.dart](../apps/driver_app/lib/screens/wallet/withdraw_screen.dart), [claim_talangan_screen.dart](../apps/driver_app/lib/screens/wallet/claim_talangan_screen.dart), [claim_donation_screen.dart](../apps/driver_app/lib/screens/wallet/claim_donation_screen.dart)), Telepon ([call_screen.dart](../apps/driver_app/lib/screens/chat/call_screen.dart)), & Bantuan Perjalanan ([trip_help_bottom_sheet.dart](../apps/driver_app/lib/screens/activity/trip_help_bottom_sheet.dart)). | • Data profil driver, berkas KTP/SIM/STNK ([register_upload_docs_screen.dart](../apps/driver_app/lib/screens/register/register_upload_docs_screen.dart)), order, dan saldo dompet diarahkan ke **MySQL (`rideon_db`)** melalui `services/rideon-api`.<br>• Stream lokasi GPS 3 detik (`driver_locations/{uid}`) dan status online (`driver_presence/{uid}`) tetap menggunakan **Firebase RTDB**. |
| `apps/page_toko` (`com.rideon.page_toko`) | `flutter run` aman. Saat ini masih memakai state lokal murni melalui `TokoState` ([toko_state.dart](../apps/page_toko/lib/data/toko_state.dart)). Memiliki layar Login & Registrasi Toko ([toko_login_screen.dart](../apps/page_toko/lib/screens/auth/toko_login_screen.dart)), Pesanan 4 Tab ([toko_orders_screen.dart](../apps/page_toko/lib/screens/orders/toko_orders_screen.dart)), Menu ([toko_menu_screen.dart](../apps/page_toko/lib/screens/menu/toko_menu_screen.dart)), & Keuangan/Withdraw PIN ([toko_finance_screen.dart](../apps/page_toko/lib/screens/finance/toko_finance_screen.dart)). | • Di [pubspec.yaml](../apps/page_toko/pubspec.yaml) dan [main.dart](../apps/page_toko/lib/main.dart) belum terpasang `firebase_*` → akan dipasang (`firebase_core`, `firebase_auth`, `firebase_database`, `firebase_messaging`).<br>• Seluruh data toko, koordinat lokasi GPS/OSM Nominatim, menu makanan, pesanan masuk, dan penarikan saldo dihubungkan ke **MySQL (`rideon_db`)** + notifikasi **FCM & RTDB**. |
| `apps/admin-RideOn` | Sudah berada di repo ([package.json](../apps/admin-RideOn/package.json) & [dashboard.tsx](../apps/admin-RideOn/src/components/dashboard.tsx)). Dibangun dengan Next.js `16.4.3`, React `19.3.0`, Tailwind CSS `v4`, serta `leaflet` + `react-leaflet` ([open-street-map.tsx](../apps/admin-RideOn/src/components/open-street-map.tsx)). Sudah memiliki 7 halaman UI (`Ringkasan`, `Peta Aktif`, `Pendaftaran Baru`, `Pesanan`, `Driver`, `Toko`, `Customer`), namun masih memakai array dummy statis dan belum memiliki layar login. | • Menambahkan **Halaman Login Admin**.<br>• Menghubungkan ke-7 halaman yang ada ke data nyata **MySQL (`rideon_db`)** & **Firebase RTDB** (untuk `Peta Aktif`).<br>• Menambahkan 2 halaman/tab baru: **`Keuangan & QRIS`** (Approve Withdraw Toko/Driver, Approve Klaim Talangan Donasi Panti Asuhan, Konfigurasi Static QRIS, Mutasi `payG`) dan **`Pengaturan AI & Tarif`** (CRUD Provider AI Dinamis, Tarif Ongkir, & Tiket CS AI). |
| `services/wa-gateway` | Node.js Express + `@whiskeysockets/baileys` aktif di [server.js](../services/wa-gateway/server.js) (`GET /health`, `/status`, `/qr`, `POST /api/otp/send`, `/api/otp/verify`, `/api/auth/reset-password`, `/send`, `/logout`, `/reset-chat-sessions`, `/restart`). Sudah memiliki fitur penangkap pesan WA masuk (`messages.upsert`), indikator *"mengetik..."* (`composing`), debounce pesan beruntun, `forwardToWebhook()`, serta adapter MySQL `whatsapp_sessions` di [db-auth.js](../services/wa-gateway/db-auth.js). | • Dibungkus ke dalam `compose.yaml` dan diarahkan agar menyimpan sesi ke MySQL `rideon_db` serta meneruskan chat WA masuk ke `services/ai-service` untuk **CS AI WhatsApp 24/7**. |

---

## Bagian 2 — Arsitektur Database: Pola I (1 Database MySQL Tunggal `rideon_db` + Firebase Auth/FCM/RTDB Live)

### A. Mengapa Kita Memilih Pola I (Standar Industri Ride-Hailing / FinTech)
1. **Menghindari *Dual-Write Anti-Pattern* (Bebas Selisih Data)**:  
   Menyimpan tabel bisnis yang sama di dua database permanen sekaligus (Firestore dan MySQL) sangat berisiko menyebabkan data tidak sinkron ketika koneksi terputus. Dengan menjadikan **MySQL (`rideon_db`) sebagai satu-satunya gudang penyimpanan data permanen (*Single Source of Truth*)**, data yang dilihat Customer, Driver, Toko, dan Admin di Web Admin selalu 100% identik.
2. **Transaksi Keuangan Atomik (*ACID Transaction*)**:  
   Aplikasi HP tidak pernah diizinkan mengubah saldo dompet atau status bayar langsung ke database. Semua perubahan pesanan dan keuangan wajib melewati **Backend Golang (`services/rideon-api` & `services/payg`)** di dalam transaksi SQL MySQL (`BEGIN ... COMMIT`).
3. **Memenuhi Seluruh 4 Poin Arahan Dosen**:
   - *Poin 1 (Hubungkan ke Firebase: Push Notification, Registrasi by Email atau Google)* → Dipenuhi oleh **Firebase Auth + Firebase FCM + Firebase RTDB**.
   - *Poin 2 (Hubungkan ke Database minimal MySQLi)* → Dipenuhi penuh oleh **MySQL 8.0 (`rideon_db`)** yang menyimpan seluruh 21 tabel ekosistem.
   - *Poin 3 (Buatkan Admin Dashboard via Web untuk menampilkan database)* → Dipenuhi oleh **`apps/admin-RideOn` (Next.js)** yang membaca/mengelola langsung isi database MySQL `rideon_db`.
   - *Poin 4 (Hubungkan ke Web Ketiga: Pembayaran Otomatis, Peta, dan Ekspedisi)* → Dipenuhi oleh **QRIS Otomatis (`services/payg` + MacroDroid GoPay/Shopee/DANA Bisnis)**, **OpenStreetMap (`flutter_map` + Leaflet + Nominatim + OSRM)**, dan layanan pengiriman/ekspedisi on-demand **FlexRide, FlexFood, & FlexSend**.

### B. Tabel Pembagian Peran MySQL (`rideon_db`) vs Firebase (`rideon-9eb77`)

| Layer | Teknologi | Data & Fungsi Spesifik yang Dikelola | Kenapa Ditempatkan di Sini? |
|---|---|---|---|
| **Gudang Data Permanen & Keuangan** | **MySQL 8.0 (`rideon_db`)** | Seluruh **21 tabel SQL** (Akun, Mitra Driver, Mitra Toko, Berkas Pendaftaran, Katalog Menu, Promo, Rumus Tarif, Pesanan, Item Belanja/Nota, Rating, Transaksi QRIS `payG`, Dompet Saldo, Mutasi Dompet, Withdraw, Klaim Talangan Donasi, Provider AI, Riwayat Chat AI, Tiket Bantuan CS, Kode OTP, & Sesi WA). | Terstruktur dengan relasi *Foreign Key*, aman untuk pembukuan keuangan, dan langsung tampil di Web Admin Next.js. |
| **Autentikasi & Sinkronisasi Google/Email** | **Golang JWT** + **Firebase Auth** | • Tabel `users` MySQL menyimpan `email`, `phone`, `password_hash` (`bcrypt`), `role`, & `firebase_uid`.<br>• Saat user login dengan Google, Firebase Auth memverifikasi akun Google → dikirim ke Golang → Golang menerbitkan **Token JWT RideOn**.<br>• Saat user daftar baru dengan Email + Nomor WA + Password, Golang menyimpan ke MySQL **dan** otomatis mendaftarkan user tersebut ke **Firebase Authentication Console** via Firebase Admin SDK. | Mendukung login murni memakai **Email**, **Nomor WhatsApp**, **Google**, maupun **Login Web Admin** tanpa trik email palsu, sekaligus memastikan daftar user tetap muncul di Firebase Console saat diperiksa dosen. |
| **Alarm & Push Notification** | **Firebase Cloud Messaging (FCM)** | Mengirim push notification ke HP Toko (pesanan baru), HP Driver (tawaran order 16 detik), dan HP Customer (status order / chat / persetujuan). | Ketika layar HP mati atau aplikasi Flutter ditutup di background, FCM tetap mampu membangunkan layar dan membunyikan nada dering. |
| **Radar GPS, Sinyal Cepat, & Telepon WebRTC** | **Firebase Realtime Database (RTDB)** | • `driver_locations/{uid}`: koordinat GPS `lat, lng, heading` driver yang ditimpa setiap **3–5 detik**.<br>• `driver_presence/{uid}`: status `online / offline / busy` (dengan fitur `onDisconnect()` bawaan RTDB yang otomatis mengubah status jadi `offline` jika HP driver mati/hilang sinyal).<br>• `order_offers/{driverId}/{orderId}`: sinyal pop-up penawaran order 16 detik.<br>• `live_orders/{orderId}`: ping perubahan status singkat order aktif.<br>• `calls/{orderId}`: signaling dering & koneksi telepon suara asli **WebRTC**. | Jika update GPS tiap 3 detik dimasukkan ke MySQL (600 write per 30 menit per driver), database SQL akan terbebani ribuan query lokasi sementara. Di RTDB, biaya dihitung per bandwidth (bukan per write) dengan latensi WebSocket sangat rendah. |

### C. Trik Respons Instan: Pola "MySQL Commit + RTDB Ping"
Bagaimana layar HP Customer, Toko, dan Driver tetap berubah seketika (`< 0,5 detik`) meskipun data utamanya disimpan di MySQL?
1. Setiap kali `services/rideon-api` atau `services/payg` menyimpan perubahan status ke **MySQL (`rideon_db`)** (contoh: pembayaran QRIS lunas `PAID`, atau Toko menekan `"Terima & Masak"`),
2. Detik itu juga Golang mengirimkan **sinyal kecil (ping)** ke **Firebase RTDB** pada node `/live_orders/{orderId}` (`{ status: "COOKING", paymentStatus: "PAID", updatedAt: ... }`) sekaligus menembak **FCM Push Notification**.
3. Aplikasi Flutter yang sedang terbuka mendengarkan node RTDB tersebut → layar UI langsung ter-update seketika tanpa perlu melakukan *polling* berulang-ulang ke MySQL!

---

## Bagian 3 — Struktur Lengkap 1 Database MySQL Tunggal (`rideon_db`)

Di dalam server MySQL hanya ada **1 nama database: `rideon_db`**. Tidak ada pemisahan database antar service; ke-4 service (`rideon-api`, `payg`, `ai-service`, `wa-gateway`) dan Web Admin (`admin-RideOn`) semuanya terhubung ke `DB_DATABASE=rideon_db`.

Berikut daftar lengkap **21 tabel** di dalam `rideon_db` (dikelompokkan berdasarkan fungsinya agar mudah dibaca):

```text
DATABASE MYSQL TUNGGAL: rideon_db (127.0.0.1:3306 di dalam Jaringan Container)
│
├── [1. Tabel Akun & Verifikasi Pendaftaran Mitra]
│   ├── users                (id, firebase_uid, name, email, phone, password_hash, role, avatar_url, status, fcm_token, created_at)
│   ├── drivers              (id, user_id, vehicle_type ['MOTOR'/'MOBIL'], vehicle_brand, plate_number, service_area, cash_capital_limit, is_online, verification_status, rating_avg)
│   ├── stores               (id, user_id, store_name, owner_name, description, category, address, postal_code, service_area, latitude, longitude, open_hours, is_open, withdraw_pin_hash, verification_status, rating_avg)
│   └── registrations        (id, reg_code, user_id, kind ['Customer'/'Driver'/'Toko'], submitted_at, status ['Menunggu verifikasi'/'Disetujui'/'Ditolak'], sim_url, stnk_url, ktp_url, business_doc_url, review_notes, reviewed_by)
│
├── [2. Tabel Katalog Warung, Rumus Tarif, Promo, & Favorit]
│   ├── store_menus          (id, store_id, name, description, category, price, image_url, is_available, total_sold, rating_avg, created_at)
│   ├── pricing_rules        (id, service_type ['FLEXRIDE_MOTOR'/'FLEXRIDE_MOBIL'/'FLEXFOOD'/'FLEXSEND'], base_fare, base_distance_km, per_km_rate, extra_stop_fee, app_service_fee, driver_commission_pct, store_commission_pct)
│   ├── promotions           (id, code, title, description, service_type, discount_amount, max_discount, min_order_amount, image_url, is_active, expires_at)
│   └── user_favorites       (id, user_id, target_type ['MENU'/'STORE'/'PLACE'], target_id, label, address, latitude, longitude, created_at)
│
├── [3. Tabel Pesanan & Rating (Inti Transaksi Lintas Aplikasi)]
│   ├── orders               (id, order_code, customer_id, driver_id, store_id, service_type ['FlexRide'/'FlexFood'/'FlexSend'], vehicle_type, status, pickup_label, pickup_address, pickup_lat, pickup_lng, dest_label, dest_address, dest_lat, dest_lng, distance_km, subtotal_amount, delivery_fee, service_fee, parking_fee, actual_receipt_amount, receipt_photo_url, discount_amount, total_amount, payment_method ['TUNAI'/'QRIS'], payment_status ['UNPAID'/'PAID'/'REFUNDED'], notes, created_at, accepted_at, completed_at)
│   ├── order_items          (id, order_id, menu_id, stop_index, stop_location_name, stop_address, stop_lat, stop_lng, item_name, quantity, estimated_price, actual_price, spicy_level, extra_egg, notes, is_checked)
│   └── ratings              (id, order_id, customer_id, driver_id, store_id, driver_stars, store_stars, comment, created_at)
│
├── [4. Tabel Pembayaran QRIS (payG) & Dompet Keuangan]
│   ├── qris_transactions    (id, transaction_ref, invoice_number, order_id, wallet_topup_user_id, purpose ['ORDER_PAYMENT'/'DRIVER_TOPUP'], base_amount, unique_code, payable_amount, qr_string, qr_svg, merchant_name, status ['PENDING'/'SETTLEMENT'/'EXPIRED'/'FAILED'], raw_notification, expires_at, settled_at, created_at)
│   ├── wallets              (id, user_id, owner_type ['DRIVER'/'STORE'], balance, bank_name, bank_account_number, bank_account_holder, updated_at)
│   ├── wallet_transactions  (id, wallet_id, order_id, tx_code, category ['Pendapatan'/'Fee admin'/'Penarikan'/'Refund'/'Top Up'], service_type, title, gross_amount, admin_fee, net_amount, is_debit, balance_after, status, created_at)
│   ├── withdrawals          (id, wd_code, wallet_id, user_id, owner_type ['DRIVER'/'STORE'], amount, admin_fee, net_payout, bank_name, bank_account_number, bank_account_holder, status ['PENDING'/'APPROVED'/'REJECTED'], reviewed_by, reviewed_at, created_at)
│   └── talangan_claims      (id, claim_code, order_id, driver_id, receipt_amount, parking_amount, total_claim_amount, receipt_photo_url, donation_recipient, donation_photo_url, notes, status ['PENDING'/'APPROVED'/'REJECTED'], reviewed_by, reviewed_at, created_at)
│
├── [5. Tabel Kecerdasan Buatan (AI) & Customer Service]
│   ├── ai_providers         (id, display_name, protocol_type ['openai_compatible'/'gemini_native'], base_url, api_key_encrypted, model_name, priority, is_active, timeout_seconds, updated_at)
│   ├── ai_chat_messages     (id, session_id, user_id, sender_phone, app_source ['CUSTOMER_APP'/'DRIVER_APP'/'PAGE_TOKO'/'WHATSAPP'/'ADMIN'], role ['user'/'assistant'/'system'], message_text, provider_used, created_at)
│   └── support_tickets      (id, ticket_code, user_id, order_id, app_source, category, subject, description, status ['OPEN'/'IN_PROGRESS'/'RESOLVED'], admin_reply, replied_via_email, created_at, resolved_at)
│
└── [6. Tabel OTP & Sesi WhatsApp]
    ├── otp_verifications    (id, identifier, channel ['WHATSAPP'/'EMAIL'], otp_code_hash, purpose ['REGISTER'/'RESET_PASSWORD'/'CHANGE_CONTACT'], expires_at, verified_at, created_at)
    └── whatsapp_sessions    (key VARCHAR(191) PRIMARY KEY, value LONGTEXT, created_at, updated_at)
```

---

## Bagian 4 — Diagram Alur Data & Komunikasi End-to-End Setelah Dihubungkan

Berikut perjalanan data secara kronologis dari detik ke-0 sampai selesai pada **1 Siklus Pesanan `FlexFood` (Bayar QRIS Otomatis)**:

```text
[1] CHECKOUT & GENERATE QRIS DINAMIS
customer_app ──(HTTPS POST /v1/orders & /pay/checkout/create)──► rideon-api & payg (Golang)
   │  • payg mengambil Static QRIS Merchant dari MySQL
   │  • payg mengalokasikan kode unik 1..999 (misal Rp 25.000 ──► Rp 25.137)
   │  • payg menyuntikkan Tag 54 + hitung ulang CRC-16 + simpan PENDING di qris_transactions
customer_app ◄─(JSON: payable_amount Rp 25.137 + QRIS String/SVG)── payg (Golang)

[2] PEMBAYARAN CUSTOMER & DETEKSI OTOMATIS (LAYANAN PIHAK KETIGA)
Customer scan & bayar Rp 25.137 lewat e-wallet / m-banking mana pun
   ──► Uang masuk ke GoPay Merchant / Shopee / DANA Bisnis di HP Merchant
   ──► Notifikasi HP Merchant muncul: "Pembayaran QRIS diterima Rp 25.137"
   ──► Aplikasi MacroDroid di HP Merchant menangkap teks notifikasi tersebut
   ──► MacroDroid ──(HTTPS POST /pay/webhook/macrodroid + Header X-PayG-Secret)──► payg (Golang)
   ──► payg mem-parsing angka 25137 & mencocokkan tagihan PENDING di MySQL
   ──► payg meng-update MySQL: qris_transactions = SETTLEMENT, orders.payment_status = PAID
   ──► payg menulis ping ke Firebase RTDB (/live_orders/{id}) + menembak FCM Push ke page_toko!
   ──► Layar CheckoutView di customer_app otomatis berubah centang hijau ("Pembayaran Berhasil!")

[3] PESANAN MASUK KE WARUNG (page_toko)
HP Mitra Toko berbunyi (FCM Push) & tab "Pesanan Baru" di page_toko langsung menampilkan order
   ──► Pemilik warung klik "Terima Pesanan" (pindah ke tab "Diproses" / sedang dimasak)
   ──► page_toko ──(HTTPS POST /v1/orders/{id}/accept-store)──► rideon-api (Golang)
   ──► rideon-api meng-update MySQL (status = COOKING) + ping RTDB (/live_orders/{id})
   ──► Layar customer_app langsung berubah status: "Pesanan sedang disiapkan oleh Toko"

[4] PENCARIAN DRIVER PARALEL (BROADCAST 16 DETIK) & ANTI-REBUTAN (ATOMIC LOCK)
Saat itu juga (tanpa menunggu makanan dingin), rideon-api membaca lokasi driver online di RTDB
   ──► rideon-api mengirim tawaran 16 detik ke RTDB (/order_offers/{driverId}/{orderId})
       + menembak FCM Push ke driver online dalam radius terdekat
   ──► Pop-up 16 detik berbunyi di layar driver_app
   ──► Driver menggeser tombol "Terima Order" ──(POST /v1/orders/{id}/accept-driver)──► rideon-api
   ──► MySQL InnoDB menjalankan Atomic Conditional UPDATE (WHERE driver_id IS NULL):
       • Driver tercepat (RowsAffected = 1) memenangkan order!
       • Pop-up di HP driver lain otomatis tertutup & RTDB /order_offers dibersihkan.

[5] PENGANTARAN LIVE GPS & TELEPON SUARA ASLI (WebRTC)
Selama driver menuju warung, mengambil makanan, dan mengantar ke rumah customer:
   ──► driver_app mengirim koordinat GPS tiap 3–5 detik ──► Firebase RTDB (/driver_locations/{uid})
   ──► customer_app & Peta Aktif Web Admin membaca RTDB ──► Ikon motor bergerak mulus di Peta OSM!
   ──► Jika Customer/Driver klik tombol Telepon di ruang chat:
       • Sinyal dering dikirim lewat RTDB (/calls/{orderId}) + STUN Google
       • HP lawan ikut berdering & keduanya berbicara langsung lewat mikrofon/speaker (WebRTC VoIP)!

[6] PESANAN SELESAI, PEMBAGIAN KOMISI 5% : 5%, & TAMPIL DI WEB ADMIN
Driver tiba di tujuan & klik "Selesaikan Pesanan" ──(POST /v1/orders/{id}/complete)──► rideon-api
   ──► Transaksi SQL Atomik di MySQL (rideon_db):
       • Status order = COMPLETED
       • Saldo Dompet Toko (wallets) bertambah +95% dari subtotal makanan (dipotong komisi 5%)
       • Saldo Dompet Driver (wallets) bertambah +95% dari ongkir (dipotong komisi 5%)
       • Riwayat mutasi tercatat lengkap di tabel wallet_transactions
   ──► Customer memberikan Bintang Rating 1–5 ──► Meng-update rata-rata rating Driver & Toko di MySQL
   ──► Seluruh transaksi, mutasi QRIS, saldo, dan posisi peta langsung tampil di Web Admin (admin.rideons.app)!
```

---

## Bagian 5 — Infrastruktur Oracle Cloud (OCI), Domain `rideons.app`, & Cloudflare `Full (Strict)`

### A. Analisis VM OCI Existing (`fastcargo-prod`) & Spesifikasi VM Baru (`rideon-prod`)
- **Kondisi Akun OCI**: Kredit undangan dosen saat ini terpakai **SGD 12.46 / SGD 415.00** (tersisa **SGD 402.54**).
- **VM Existing (`fastcargo-prod`)**: Berjalan di IP `168.110.204.74` dengan shape **`VM.Standard.E5.Flex` (`1 OCPU`, `12 GB RAM`)** sejak 11 Nov 2026 (~SGD 1,55/hari).
- **Mengapa `VM.Standard.E5.Flex` Dipilih untuk VM Baru RideOn (`rideon-prod`)**:
  - Karena stok prosesor ARM gratis (`VM.Standard.A1.Flex`) di region OCI penuh (*Out of capacity*), kita langsung menggunakan **`VM.Standard.E5.Flex`** yang stoknya selalu tersedia, namun dengan ukuran RAM yang dioptimalkan khusus untuk stack Golang RideOn agar hemat kredit:
    - **Shape**: `VM.Standard.E5.Flex`
    - **OCPU**: **`1 OCPU`**
    - **Memory (RAM)**: **`4 GB` atau `6 GB RAM`** (ditambah `2 GB Swap` di OS Ubuntu)
    - **Boot Volume**: **`50 GB`**
- **Rincian Pemakaian RAM Riil di VM `rideon-prod`**:
  - `services/rideon-api` (Golang): **~20 MB**
  - `services/payg` (Golang): **~15 MB**
  - `services/ai-service` (Golang): **~20 MB**
  - `services/wa-gateway` (Node.js Baileys): **~150–220 MB**
  - `apps/admin-RideOn` (Next.js production `next start`): **~150–250 MB**
  - `MySQL 8.0`: **~400–600 MB**
  - `Nginx` + OS Ubuntu: **~200–300 MB**
  - **Total RAM keseluruhan saat semua menyala bersamaan**: hanya sekitar **`1,1 – 1,5 GB RAM`**. Dengan RAM 4–6 GB, server memiliki ruang kosong yang sangat lega dan biaya kredit hariannya hampir separuh lebih hemat daripada VM 12 GB.
- **Strategi Penghematan Kredit OCI (Kembangkan di Lokal Dulu)**:
  - Seluruh penulisan kode, pembuatan kontainer `compose.yaml`, dan pengujian integrasi 4 aplikasi dilakukan di **laptop lokal terlebih dahulu**. VM OCI `rideon-prod` baru dibuat ketika seluruh fitur sudah teruji 100% di lokal dan siap di-online-kan ke `rideons.app`.

### B. Domain Resmi `rideons.app` (Name.com) & Peringatan Namespace `.app`
- Domain **`rideons.app`** telah berhasil diklaim (\$0.00, aktif s.d. **18 Nov 2027**).
- **Aturan Wajib HTTPS (HSTS Preload List)**:  
  Seluruh domain berakhiran `.app` dikunci secara global wajib menggunakan `HTTPS`. Browser maupun aplikasi Android/Flutter akan menolak koneksi `http://` biasa ke `rideons.app`.
  - **Tidak perlu membeli SSL berbayar atau email Titan di Name.com**: Kita menggunakan kombinasi **Cloudflare Proxy (Gratis)** + **Sertifikat SSL Let's Encrypt (`Certbot`) Gratis** di Nginx VM OCI.
  - *(Catatan pengingat: Di dashboard Name.com, fitur `Automatic Renewal` tercatat aktif dengan tarif perpanjangan \$26.99 pada Nov 2027; dapat dimatikan jika tidak ingin diperpanjang otomatis setelah kuliah selesai).*

### C. Pemetaan Subdomain `rideons.app` & Alasan Teknis Cloudflare `Full (Strict)`

| Subdomain / Path | Target Container di VM OCI | Fungsi |
|---|---|---|
| `https://rideons.app` | Nginx Static / Landing Page | Halaman profil aplikasi, unduh APK, & halaman Kebijakan Privasi (*Privacy Policy*). |
| `https://admin.rideons.app` | Container `admin` (`:3001`) | **Web Admin Dashboard Next.js** (`apps/admin-RideOn`) yang berjalan satu mesin dengan MySQL (`127.0.0.1:3306`) sehingga query database berlangsung `< 1 ms` dan port `3306` tidak perlu dibuka ke publik internet. |
| `https://api.rideons.app/v1/*` | Container `rideon-api` (`:8080`) | Endpoint REST API utama untuk `customer_app`, `driver_app`, `page_toko`, dan `admin-RideOn`. |
| `https://api.rideons.app/uploads/*` | Container `rideon-api` (`:8080`) | Penyajian file gambar KTP, SIM, STNK, berkas toko, foto menu makanan, foto profil, & bukti nota/donasi. |
| `https://api.rideons.app/pay/*` | Container `payg` (`:8085`) | Endpoint pembuatan QRIS Dinamis + penerima webhook mutasi pembayaran otomatis dari **MacroDroid**. |
| `https://api.rideons.app/ai/*` | Container `ai-service` (`:8086`) | Endpoint CS AI Pintar 24/7 & asisten cerdas untuk ke-3 aplikasi mobile dan Web Admin. |
| `https://api.rideons.app/wa/*` | Container `wa-gateway` (`:3000`) | Endpoint pengiriman OTP WhatsApp, status koneksi QR WA, & penerimaan pesan chat WA masuk. |

**Kenapa Menu SSL/TLS di Cloudflare Wajib Diset ke Mode `Full (Strict)`?**
Di Cloudflare terdapat 3 mode SSL utama:
1. **Mode `Flexible` (Jangan Dipakai)**: Jalur HP/Browser → Cloudflare memakai HTTPS, tetapi jalur Cloudflare → VM OCI memakai HTTP biasa (port 80 tanpa enkripsi). Jika Nginx di VM OCI mengaktifkan redirect HTTP ke HTTPS, maka akan terjadi **`ERR_TOO_MANY_REDIRECTS` (redirect berputar tanpa henti)** yang membuat web dan API gagal dibuka, serta data sensitif tidak terenkripsi antara Cloudflare dan OCI.
2. **Mode `Full` (Biasa)**: Terenkripsi sampai ke VM OCI, tetapi Cloudflare tidak memvalidasi keaslian sertifikat SSL di VM OCI.
3. **Mode `Full (Strict)` (Yang Kita Gunakan)**:
   - **Gembok Depan** (HP/Browser → Cloudflare) memakai HTTPS Cloudflare.
   - **Gembok Belakang** (Cloudflare → Nginx VM OCI) memakai HTTPS dengan sertifikat resmi **Certbot Let's Encrypt**.
   - **Hasilnya**: Bebas 100% dari error `Too Many Redirects`, header protokol `https` selalu konsisten untuk namespace `.app`, mendapat proteksi anti-DDoS gratis Cloudflare, dan bila suatu saat awan oranye Cloudflare dimatikan sementara untuk *debugging*, sertifikat Let's Encrypt di VM OCI tetap menjaga HTTPS `rideons.app` tetap valid!

---

## Bagian 6 — Evaluasi Jujur Penggunaan Kontainer (Podman vs Docker) & Struktur Folder `services/`

### A. Jawaban Jujur: Apakah Proyek Mobile Efektif Menggunakan Container?
Informasi bahwa *"proyek mobile tidak disarankan menggunakan container"* adalah **100% BENAR apabila yang dimasukkan ke dalam container adalah aplikasi mobile Flutter-nya**, namun **berbeda dengan penggunaan container untuk Server Backend di VM OCI**:

| Bagian Proyek | Apakah Menggunakan Container? | Penjelasan Teknis Jujur |
|---|---|---|
| **3 Aplikasi Mobile Flutter** (`apps/customer_app`, `apps/driver_app`, `apps/page_toko`) | **TIDAK PAKAI CONTAINER SAMA SEKALI** (Tetap Native `flutter run` / `flutter build apk`) | Menjalankan Flutter SDK / Android SDK / Emulator di dalam container sangat tidak efektif (ukuran image >10 GB, emulator lambat, koneksi USB debugging ke HP sering terputus, dan hasil akhir Flutter adalah file `.apk` yang di-install di HP Android, bukan di server). |
| **Server Backend, Database MySQL, & Web Admin di VM OCI** (`mysql`, `rideon-api`, `payg`, `ai-service`, `wa-gateway`, `admin-RideOn`, `nginx`) | **SANGAT EFEKTIF PAKAI CONTAINER (`compose.yaml`)** | Di sisi server terdapat 7 komponen dari 3 runtime berbeda (**Golang, Node.js, dan MySQL**). Tanpa container, kita harus menginstal ketiganya secara manual di OS Ubuntu, mengatur 5 file `systemd` terpisah, dan rawan bentrok port. Dengan **1 file `compose.yaml`**, seluruh komponen server menyala dengan 1 perintah dan otomatis hidup kembali (`restart: unless-stopped`) saat VM di-reboot. |

### B. Satu File `compose.yaml` yang Kompatibel untuk Podman (Laptop Lokal) & Docker (VM OCI)
Mengikuti pola yang sudah terbukti di `FastCargo/compose.yaml` milik Anda:
- Kita membuat **1 file `compose.yaml` di root repository `/home/leon/Documents/Project/RideOn/compose.yaml`**.
- Menggunakan nama registry lengkap (`docker.io/library/mysql:8.0`, `docker.io/library/nginx:alpine`) dan label volume SELinux (`:z`, `:Z`) sehingga:
  - Di **laptop Linux Anda**, Anda dapat menjalankan **`podman compose up -d --build`** tanpa terkena masalah permission SELinux.
  - Di **VM OCI Ubuntu (`rideon-prod`)**, Anda dapat menjalankan **`docker compose up -d --build`** menggunakan file yang sama persis.

### C. Struktur 4 Service Backend Sejajar di Dalam Direktori `services/`
Seluruh microservice backend diletakkan sejajar di dalam folder `services/` agar modular, mudah di-debug satu per satu, dan jika salah satu service di-restart tidak mematikan service lainnya:

```text
RideOn/
├── compose.yaml               # Menjalankan 7 container: mysql, rideon-api, payg, ai-service, wa-gateway, admin, nginx
├── docker/
│   ├── nginx/                 # Konfigurasi reverse proxy untuk rideons.app, admin.rideons.app, api.rideons.app
│   └── mysql/init/            # File skema 01_schema.sql (21 tabel rideon_db) & 02_seed_lhokseumawe.sql
├── apps/
│   ├── customer_app/          # Flutter Customer (Native)
│   ├── driver_app/            # Flutter Mitra Driver (Native)
│   ├── page_toko/             # Flutter Mitra Toko (Native)
│   └── admin-RideOn/          # Next.js Web Admin (Containerized)
└── services/                  # 4 Microservices Sejajar
    ├── wa-gateway/            # 1. Node.js (Express + Baileys) - Port 3000
    ├── payg/                  # 2. Golang (Chi + QRIS Dynamic Injector + MacroDroid Webhook) - Port 8085
    ├── rideon-api/            # 3. Golang (Chi + MySQL + Firebase Admin + Resend/Gmail + Upload) - Port 8080
    └── ai-service/            # 4. Golang (Chi + Universal AI Adapter + MySQL Context Reader) - Port 8086
```

---

## Bagian 7 — Detail Mendalam Ke-4 Services (`payg`, `rideon-api`, `ai-service`, `wa-gateway`) & Postman

### A. `services/payg` (Golang) — Adaptasi & Penyempurnaan dari `FastCargo/services/payG`
Berdasarkan hasil audit terhadap source code `/home/leon/Documents/Tugas-Kuliah/FastCargo/services/payG` (`main.go`, `router.go`, `internal/SGpay/engine.go`, `manager.go`, `webhook_dispatcher.go`):
1. **Keunggulan `payG` yang Dipertahankan**:
   - Dibangun dengan Golang (`github.com/go-chi/chi/v5` & `rsc.io/qr`), binary Alpine sangat kecil (~15 MB RAM).
   - Memiliki alokasi kode unik `1..999` (`allocator.NewAllocator(999)`) agar `PayableAmount = BaseAmount + UniqueCode` tidak pernah kembar di antara transaksi yang masih `PENDING`.
   - Memiliki injektor EMVCo Tag 54 (`qris.StaticToDynamicQRIS`) yang mengubah string QRIS statis (GoPay Merchant / Shopee / DANA Bisnis) menjadi QRIS dinamis terkunci nominal + menghitung ulang checksum **CRC-16**, lengkap dengan generator SVG QR dan masa kedaluwarsa 15 menit (`CleanExpiredOrders`).
2. **Penyempurnaan Khusus untuk RideOn**:
   - **Terhubung Langsung ke Tabel `qris_transactions` di MySQL (`rideon_db`)**: Menggantikan penyimpanan file `payg_state.json` lokal menjadi tabel MySQL agar seluruh daftar transaksi QRIS langsung tampil real-time di menu **`Keuangan & QRIS` Web Admin Next.js**.
   - **Menambahkan Endpoint Penerima Webhook MacroDroid Langsung di `payg` (`POST /pay/webhook/macrodroid`)**:
     - Di FastCargo sebelumnya, endpoint penerima teks notifikasi MacroDroid berada di sisi Laravel. Di RideOn, endpoint ini langsung berada di dalam `services/payg` (dilindungi secret header `X-PayG-Secret`).
     - Saat MacroDroid di HP Merchant mengirim payload notifikasi (misal: `{"notification_text": "Kamu menerima pembayaran QRIS sebesar Rp25.137"}`), `services/payg` langsung mengekstrak angka `25137`, mencocokkan transaksi `PENDING` di MySQL, mengubah status menjadi `SETTLEMENT`, meng-update `orders.payment_status = 'PAID'` (untuk pembayaran pesanan Customer) **ATAU** menambah `wallets.balance` (untuk **Top-Up Saldo Deposit Driver**), serta memicu ping RTDB & FCM Push Notification!
   - **Tombol Fallback Manual di Web Admin**: Jika HP merchant penangkap notifikasi sedang kehabisan baterai atau putus sinyal, Admin tetap memiliki tombol **"Konfirmasi Lunas Manual"** pada tabel transaksi QRIS di Web Admin.

### B. Peran REST API & Postman Collection (Walaupun Tanpa Midtrans)
Meskipun tidak memakai Midtrans, seluruh komunikasi sensitif di RideOn berjalan di atas **REST API** (`services/rideon-api`, `services/payg`, `services/ai-service`, `services/wa-gateway`). Kita menyediakan file **Postman Collection JSON** lengkap di repository untuk 4 fungsi vital:
1. **Simulasi Bayar QRIS Lunas Tanpa Transfer Uang Sungguhan**: Saat menguji checkout `customer_app` atau Top-Up `driver_app`, cukup jalankan request *"Simulate MacroDroid Webhook"* di Postman dengan nominal unik yang tampil di layar HP → dalam `< 0,5 detik` layar HP langsung berubah centang hijau *"Pembayaran Berhasil!"*.
2. **Pengujian Backend Mandiri**: Menguji validasi JWT, kode error (`200`, `400`, `401`, `409 Conflict`), dan secret header sebelum dihubungkan ke UI Flutter.
3. **Kontrak API Tim (*Single Source of Truth*)**: Dokumentasi request/response JSON yang seragam bagi seluruh aplikasi.
4. **Bukti Pengujian Saat Sidang Dosen**: Mendemokan pengujian endpoint REST API secara profesional di Postman.

### C. Strategi Dual-Email di `services/rideon-api`: Resend (`noreply@rideons.app`) vs Gmail CS (2 Arah!)
Menggabungkan **Resend** dan **Gmail SMTP** dengan pembagian peran seperti perusahaan startup nyata:

| Kriteria & Fungsi | **1. Resend (`noreply@rideons.app`)** — *Primary Sistem* | **2. Gmail Resmi Admin (`smtp.gmail.com`)** — *CS 2 Arah & Fallback* |
|---|---|---|
| **Peran Utama** | **Email Sistem Otomatis (Satu Arah)**: Pengiriman **Kode OTP Email 6 Digit**, notifikasi akun Driver/Toko disetujui atau ditolak, & struk digital otomatis. | **Email Customer Service & Tiket Bantuan (Dua Arah)**: Mengirim balasan atas laporan kendala/tiket keluhan user dari Web Admin dengan nama pengirim **"Tim Bantuan RideOn"**. |
| **Interaksi Balasan User** | `noreply` (Satu arah dari mesin). | **Bisa langsung di-Reply (Balas) oleh Customer/Driver/Toko** dari HP mereka dan balasannya masuk kembali ke Inbox Gmail Admin sehingga terasa berbicara langsung dengan admin manusia! |
| **Jalur Koneksi & Keamanan di VM OCI** | Menggunakan **HTTPS REST API (`port 443`)** ke akun Resend Anda dengan verifikasi DNS `SPF`/`DKIM` domain `rideons.app` di Cloudflare (100% anti-blokir firewall cloud & memiliki dashboard *Emails Log*). | Menggunakan App Password 16 digit. Sekaligus berfungsi sebagai **Cadangan Otomatis (*Auto-Failover*)** apabila kuota harian Resend (100 email/hari) habis saat trafik pengujian sedang ramai. |

### D. `services/ai-service` (Golang) — Integrasi AI Penuh di 3 Aplikasi Mobile + Web Admin + WhatsApp
Seluruh pemrosesan AI dilakukan di `services/ai-service` (server OCI) dengan membaca konteks database **MySQL (`rideon_db`)**, sehingga ke-3 aplikasi Flutter tetap sangat ringan.

#### 1. Struktur Kode & Nama File 100% Universal (Tanpa Hardcode Nama Merek)
Tidak ada nama vendor/router tertentu yang di-hardcode di nama file maupun variabel kode Go. Sistem hanya menggunakan **2 Adapter Protokol Standar** yang dikelola secara dinamis dari tabel MySQL `ai_providers` melalui **Web Admin**:

```text
services/ai-service/
├── cmd/ai/main.go
└── internal/
    ├── gateway/
    │   ├── registry.go     # Membaca daftar provider aktif dari tabel MySQL (ai_providers)
    │   └── router.go       # Mengatur antrean Prioritas 1 (Utama) -> Prioritas 2 (Cadangan) secara otomatis
    ├── adapter/
    │   ├── adapter.go      # Interface universal: GenerateReply(ctx, prompt, tools)
    │   ├── standard_v1.go  # Standar Protokol 1: OpenAI-Compatible REST (/v1/chat/completions)
    │   └── native_gen.go   # Standar Protokol 2: Google Generative REST (Gemini API Native)
    ├── context/            # Pembaca data real-time MySQL (Order, Pembayaran QRIS, Menu, Dompet, Tiket CS)
    └── handler/            # Endpoint HTTP untuk customer_app, driver_app, page_toko, wa-gateway, & admin-RideOn
```

- **Manajemen Penuh dari Web Admin (`admin.rideons.app`)**:
  - Di halaman **`Pengaturan AI & Tarif`** Web Admin, Admin dapat klik **"+ Tambah Provider AI"**, memilih protokol (`openai_compatible` atau `gemini_native`), mengisi `Base URL`, `API Key` (disimpan terenkripsi **`AES-256-GCM`** di MySQL dan ditampilkan tersembunyi `****` di layar agar aman saat presentasi/sidang), mengetik `Model Name`, mengatur urutan prioritas (`1, 2, 3...`), dan menekan tombol **"Test Prompt"** tanpa perlu menyentuh kode Go ataupun mem-build ulang APK Flutter!

#### 2. Tabel Distribusi Fitur AI di Masing-Masing Aplikasi

| Aplikasi | 1. Fitur CS AI Pintar 24/7 (Wajib Ada di Semua Lini) | 2. Fitur AI Spesifik Sesuai Kebutuhan Aplikasi |
|---|---|---|
| **`customer_app`** (Penumpang & Pembeli) | **CS AI Customer (Di Halaman Chat/Inbox App & via WhatsApp Resmi RideOn)**:<br>AI otomatis membaca tabel `orders` & `qris_transactions` milik user di MySQL sebelum menjawab (contoh: *"Pesanan #ORD-1047 Anda di Kedai Joni sudah LUNAS via QRIS dan sedang dimasak oleh toko"*), membantu cancel order yang belum diproses, atau membuat tiket keluhan (`support_tickets`) ke Web Admin. | • **AI Food & Ride Assistant**: Customer bertanya natural (*"Cariin makanan pedas di bawah Rp 25.000 dekat Kampus Bukit Indah yang warungnya lagi buka"*) → AI mencari di tabel `stores` & `store_menus` MySQL lalu menampilkan rekomendasi menu asli yang bisa langsung dipesan.<br>• **AI Smart Quick-Reply**: Saran tombol balasan cepat di [quick_replies_bar.dart](../apps/customer_app/lib/features/chat/presentation/modules/conversation/quick_replies_bar.dart) yang menyesuaikan status perjalanan. |
| **`driver_app`** (Mitra Kurir / Ojek) | **CS AI Mitra Driver ([trip_help_bottom_sheet.dart](../apps/driver_app/lib/screens/activity/trip_help_bottom_sheet.dart))**:<br>Terhubung langsung ke tombol *"Hubungi Customer Service (CS) 24/7"* & 5 kategori kendala perjalanan (`Tarif tidak sesuai`, `Rute tidak akurat`, `Kendala penumpang`, `Barang tertinggal`, `Aplikasi/GPS bermasalah`). AI mengenali `orderId` yang sedang dibawa driver dan membuatkan tiket bantuan prioritas ke Web Admin. | • **AI Shopping & Order Summarizer**: Merapikan daftar titipan belanja pasar `FlexSend` multi-lokasi atau catatan pesanan makanan yang panjang menjadi checklist ringkas yang mudah dibaca saat berkendara, serta info area ramai pesanan dari data MySQL. |
| **`page_toko`** (Mitra Warung / Resto) | **CS AI Mitra Toko**:<br>Menjawab pertanyaan status pencairan tarik saldo (*withdraw* uang QRIS) berdasarkan tabel `withdrawals` MySQL, bantuan saat driver terlalu lama menjemput makanan, & panduan operasional toko. | • **AI Menu Copywriter**: Saat tambah menu di [toko_menu_screen.dart](../apps/page_toko/lib/screens/menu/toko_menu_screen.dart), pemilik warung cukup ketik nama makanan & harga → klik *"Buat Deskripsi dengan AI"* → otomatis dibuatkan deskripsi kuliner yang menarik.<br>• **AI Sales Insight Warung**: Merangkum menu terlaris & performa penjualan warung dari MySQL. |
| **`admin-RideOn`** (Next.js Web Admin) | **Dashboard Monitoring & Eskalasi Tiket CS AI**:<br>Menampilkan daftar tiket kendala (`support_tickets`) yang dieskalasi oleh CS AI dari customer, driver, maupun toko, lengkap dengan tombol balas langsung ke aplikasi/WA atau ke **Email Gmail CS 2 Arah**. | • **AI Executive Summary**: Kartu ringkasan operasional harian cerdas di halaman `Ringkasan` (`overview`).<br>• **Panel Manajemen Provider AI Universal**: CRUD & pengatur prioritas provider AI (`ai_providers`). |

#### 3. Batas Wewenang Keamanan CS AI (*Safe Action Boundary*)
- **Yang Boleh Dilakukan Otomatis oleh AI**: Membaca data real-time milik user yang sedang chat dari MySQL, membantu membatalkan pesanan tahap awal (selama statusnya masih `WAITING_PAYMENT` atau `SEARCHING_DRIVER`), dan membuat tiket laporan kendala (`support_tickets`) ke Web Admin.
- **Yang TIDAK Boleh Dilakukan Langsung oleh AI (Wajib Klik "Setujui" oleh Admin di Web Admin)**: Segala perubahan angka saldo dompet (`wallets`), pencairan refund uang, klaim talangan, dan persetujuan berkas SIM/STNK wajib hanya berupa tiket pengajuan yang dieksekusi setelah Admin mengklik **"Setujui"** di Web Admin (sehingga sistem keuangan 100% kebal dari manipulasi chat / *Prompt Injection*).

---

## Bagian 8 — Analisis Lengkap 13 Aturan Bisnis & Operasional Lintas-Aplikasi (Hasil Bedah UI Codebase)

Seluruh detail di bawah ini telah disepakati dari hasil pembedahan layar UI pada ke-4 aplikasi:

### 1. Sistem Login, Registrasi, & Sinkronisasi Token (`Cabang #1`)
- Menggunakan **Opsi 1 (Unified JWT dari Golang + Sinkronisasi Firebase Auth)**:
  - Tabel `users` di MySQL (`rideon_db`) memegang kredensial utama (`email`, `phone`, `password_hash`, `role`, `firebase_uid`).
  - User dapat login menggunakan **Email + Kata Sandi**, **Nomor WhatsApp + Kata Sandi**, maupun **Tombol Google Sign-In**.
  - Saat user baru mendaftar dengan Email/Google, `services/rideon-api` menyimpan akun ke MySQL sekaligus mendaftarkannya ke **Firebase Authentication Console** di belakang layar agar tetap tampil lengkap di dashboard Firebase sesuai syarat dosen Poin #1.

### 2. Aturan Verifikasi Pendaftaran Akun Baru (`Cabang #2`)
- **Customer (`customer_app`)**: Begitu selesai verifikasi OTP (WA / Email Resend) atau Login Google, status akun Customer **langsung otomatis `Aktif / Disetujui`** agar bisa langsung memesan (tetap tercatat di tabel `registrations` Web Admin dengan status `Disetujui`).
- **Driver (`driver_app`) & Mitra Toko (`page_toko`)**: Saat mendaftar dan mengunggah berkas (KTP, SIM, STNK untuk Driver; dokumen usaha untuk Toko), status awalnya adalah **`Menunggu verifikasi`**. Mereka dapat masuk melihat aplikasi, tetapi tombol *Mulai Online / Buka Toko* terkunci sampai Admin menekan tombol **"Setujui"** di menu `Pendaftaran Baru` Web Admin (`admin.rideons.app`). Saat disetujui/ditolak Admin, HP mereka otomatis menerima **FCM Push Notification + Email dari `noreply@rideons.app`**.

### 3. Pengambilan Titik Koordinat GPS / Peta untuk Toko Baru (`page_toko`)
- Pada form pendaftaran toko baru di [toko_login_screen.dart](../apps/page_toko/lib/screens/auth/toko_login_screen.dart#L40-L47) (`Lengkapi Daftar Toko`) dan edit profil toko, sistem otomatis mengambil koordinat **`latitude` & `longitude`** melalui GPS HP Toko atau pencarian alamat **OSM Nominatim**.
- Dengan adanya `latitude` & `longitude` di tabel `stores` MySQL, begitu toko disetujui Admin, pin lokasi warung **langsung muncul otomatis di `Peta Aktif` Web Admin** dan langsung bisa dihitung jarak ongkirnya ke rumah customer.

### 4. Data Awal Katalog Toko & Makanan (`Seeder MySQL Lhokseumawe & Aceh Utara` — `Cabang #3`)
- Saat database MySQL `rideon_db` pertama kali dijalankan, file seeder otomatis mengisi tabel `stores`, `store_menus`, `drivers`, dan `promotions` dengan data awal berlokasi di sekitar **Lhokseumawe & Aceh Utara** (*Kampus Bukit Indah, Blang Pulo, Reuleut, Muara Batu*) lengkap dengan aset gambar makanannya.
- Hal ini memastikan halaman **Beranda (`Pilihan Terlaris`)**, **`FlexFood`**, **`Top 20 Leaderboard`**, dan **`Peta Aktif` Web Admin** langsung tampil hidup sejak hari pertama.
- Setiap kali ada toko baru atau menu makanan baru yang ditambah/diedit dari aplikasi **`page_toko`**, data tersebut **langsung tampil secara real-time di urutan paling atas katalog `customer_app`**.

### 5. Rumus Tarif Ongkir per Km (OSM), Pencocokan Motor vs Mobil, & Komisi 5% : 5% (`Cabang #4`)
- **Perhitungan Jarak & Rute Jalan Raya 100% OSM**: Menggunakan koordinat asal & tujuan untuk menghitung jarak jalan raya dalam kilometer (via OSRM / OpenStreetMap routing).
- **Filter Jenis Kendaraan `FlexRide`**: Di `customer_app` ([vehicle_option_model.dart](../apps/customer_app/lib/features/flexride/presentation/modules/vehicle_selection/vehicle_option_model.dart)) customer memilih layanan **Motor** atau **Mobil**, dan sistem hanya mengirimkan tawaran order ke driver yang jenis kendaraannya di tabel `drivers` MySQL sesuai (**Motor → Driver Motor**, **Mobil → Driver Mobil**).
- **Angka Default Tarif di Tabel `pricing_rules` MySQL (Dapat Diubah Kapan Saja dari Web Admin)**:
  - **FlexRide Motor**: Tarif dasar `Rp 8.000` (≤ 2 km), tambah `Rp 2.500 / km`, biaya layanan aplikasi `Rp 2.000`.
  - **FlexRide Mobil**: Tarif dasar `Rp 15.000` (≤ 2 km), tambah `Rp 4.000 / km`, biaya layanan aplikasi `Rp 3.000`.
  - **FlexFood**: Ongkir dasar `Rp 6.000` (≤ 2 km), tambah `Rp 2.000 / km`, biaya layanan aplikasi `Rp 2.000`.
  - **FlexSend (Titip Belanja)**: Ongkir dasar `Rp 8.000` (≤ 2 km), tambah `Rp 2.500 / km`, tambah `Rp 3.000` per lokasi singgah tambahan, biaya layanan aplikasi `Rp 2.000`.
- **Potongan Komisi Platform (*Fee Admin*)**:
  - **Mitra Toko (Warung)**: Dipotong komisi **5%** dari subtotal makanan (Toko menerima bersih **95%** harga makanan).
  - **Mitra Driver (Kurir)**: Dipotong komisi **5%** dari tarif ongkir (Driver menerima bersih **95%** ongkir).

### 6. Aturan Saldo Deposit Awal Driver `Rp 0`, Toleransi Minus `-Rp 20.000`, & Top-Up via QRIS `payG` (`Cabang #5`)
- **Saldo Awal Driver Baru**: **`Rp 0`** (tanpa bonus saldo awal saat baru disetujui Admin).
- **Perbedaan Alur Uang Order QRIS vs Order Tunai (Cash)**:
  - **Pada Order Bayar QRIS**: 100% uang customer masuk ke rekening QRIS Merchant Platform. Saat order selesai, sistem menambahkan **+95% harga makanan ke saldo dompet Toko** dan **+95% ongkir ke saldo dompet Driver**.
  - **Pada Order Bayar Tunai (Cash)**: Uang tunai dipegang langsung oleh Driver. Maka saat order selesai, sistem memotong **komisi 5%** dari saldo deposit dompet Driver.
- **Toleransi Saldo Minus s.d. `-Rp 20.000` untuk Order Tunai**:
  - Meskipun saldo awal Driver adalah `Rp 0`, Driver **tetap diizinkan mengambil order Tunai (Cash)** dan saldonya boleh menjadi minus (hutang komisi) sampai batas maksimal **`-Rp 20.000`**.
  - Apabila saldo minus menyentuh `-Rp 20.000`, Driver wajib melakukan **Top-Up Saldo Deposit** di [wallet_screen.dart](../apps/driver_app/lib/screens/wallet/wallet_screen.dart) yang terhubung langsung ke **`services/payg` (QRIS Dinamis Otomatis)**, atau mengambil order QRIS yang pendapatannya otomatis melunasi saldo minus tersebut.

### 7. Urutan Pencarian Driver pada `FlexFood` (Toko Terima Dulu → Baru Cari Driver)
- Di [toko_orders_screen.dart](../apps/page_toko/lib/screens/orders/toko_orders_screen.dart) (`page_toko`) terdapat 4 tab: `Pesanan Baru`, `Diproses`, `Selesai`, `Batal`.
- Saat customer membuat pesanan `FlexFood` (setelah QRIS lunas jika memilih QRIS, atau langsung jika memilih Tunai), pesanan masuk ke tab **`Pesanan Baru`** di `page_toko`.
- Begitu pemilik warung menekan tombol **"Terima Pesanan"** (pindah ke tab `Diproses` / sedang dimasak), **detik itu juga `services/rideon-api` otomatis membunyikan radar `driver_app` terdekat** supaya driver berjalan menuju warung selagi makanan dimasak (dan jika warung menolak pesanan karena stok habis, driver tidak terlanjur jalan sia-sia).

### 8. Mekanisme Layar Bayar QRIS di `customer_app` (`CheckoutView`)
- Pada [checkout_view.dart](../apps/customer_app/lib/features/flexfood/presentation/modules/checkout/checkout_view.dart#L72-L88), timer simulasi 5 detik diganti menjadi pemanggilan nyata ke **`services/payg` (`POST /pay/checkout/create`)** yang menampilkan **QRIS Dinamis + Nominal Unik asli (misal `Rp 25.137`)**.
- Begitu pembayaran terdeteksi oleh MacroDroid (atau disimulasikan lewat Postman), layar `CheckoutView` otomatis berubah menjadi centang hijau *"Pembayaran Berhasil"* dan pesanan langsung diteruskan ke Toko/Driver.

### 9. Sistem Penawaran Order 16 Detik ke Driver (Broadcast Radius + Atomic Lock MySQL)
- Menggunakan **Pilihan B (Broadcast Radius Terdekat + Siapa Cepat Dia Dapat)**: Tawaran order selama 16 detik dikirimkan serentak ke driver yang sedang `Online` di radius terdekat.
- **Perhitungan Anti-Rebutan (*Race Condition* di Milidetik yang Sama)**:
  - Saat 2 driver menggeser tombol **Terima** hampir bersamaan, `services/rideon-api` mengeksekusi query **Atomic Conditional UPDATE** di MySQL InnoDB:
    ```sql
    UPDATE orders
    SET driver_id = ?,
        status = 'DRIVER_ACCEPTED',
        accepted_at = NOW()
    WHERE id = ?
      AND status = 'SEARCHING_DRIVER'
      AND driver_id IS NULL;
    ```
  - Mesin MySQL InnoDB melakukan *Row-Level Lock* dalam skala mikrodetik: request yang tiba 1 milidetik lebih dulu mendapatkan `RowsAffected = 1` (**Menang Dapat Order**), sedangkan request kedua mendapatkan `RowsAffected = 0` (**Kalah Cepat** → menerima pesan `409 Conflict` *"Maaf, pesanan ini baru saja diambil driver lain"* dan pop-up tertutup rapi).

### 10. Alur Unik `FlexSend` (Titip Belanja Multi-Lokasi, Modal Kas Driver, Nota Asli, & Klaim Talangan Donasi Panti Asuhan)
Berdasarkan [flexsend_screen.dart](../apps/customer_app/lib/features/flexsend/presentation/pages/flexsend_screen.dart) (`customer_app`) dan [radar_flex_send_screen.dart](../apps/driver_app/lib/screens/radar/radar_flex_send_screen.dart) (`driver_app`):
1. **Filter Batas Modal Kas Driver**: Driver mengatur *Batas Modal Kas* (uang talangan yang ia pegang). Sistem hanya menawarkan pesanan `FlexSend` ke driver yang `cash_capital_limit >= estimasi_belanja_customer`.
2. **Checklist Belanja Multi-Lokasi & Input Harga Nota Asli (`inputReceiptParking`)**: Setelah driver berbelanja (maksimal 3 lokasi pasar/toko), driver mencentang barang, menginput **Harga Nota Asli + Biaya Parkir**, dan mengunggah foto struk nota belanja.
3. **Pelunasan Dinamis (`FlexSendState.receipt`)**: Tagihan akhir yang dibayar customer (Tunai maupun **QRIS `payG`**) dihitung otomatis dari **`Harga Nota Asli + Biaya Parkir + Ongkir FlexSend`**.
4. **Klaim Jaminan Talangan 2 Langkah (Donasi Panti Asuhan)** ([claim_talangan_screen.dart](../apps/driver_app/lib/screens/wallet/claim_talangan_screen.dart) & [claim_donation_screen.dart](../apps/driver_app/lib/screens/wallet/claim_donation_screen.dart)): Jika customer membatalkan sepihak/kabur setelah barang dibeli driver, driver mengunggah **Step 1: Foto Nota Belanja** dan **Step 2: Foto Penyaluran Donasi Barang ke Panti Asuhan Terdekat** untuk mengklaim penggantian uang talangan (`Nota + Parkir`).

### 11. Persetujuan Tarik Saldo (*Withdraw*) & Klaim Talangan di Web Admin (`Cabang #6`)
- **Tarik Saldo (*Withdraw*) Driver & Toko**: Saat Driver ([withdraw_screen.dart](../apps/driver_app/lib/screens/wallet/withdraw_screen.dart), biaya admin penarikan `Rp 2.000`, misal ke BSI) atau Toko ([toko_finance_screen.dart](../apps/page_toko/lib/screens/finance/toko_finance_screen.dart) dengan verifikasi PIN 6 digit) mengajukan Tarik Saldo, saldo dompet langsung dipotong/ditahan (*hold*) dan masuk ke menu **`Keuangan & QRIS` di Web Admin** dengan status `Menunggu Konfirmasi Admin`. Begitu Admin klik **"Setujui"**, status berubah menjadi `Berhasil` (+ notifikasi FCM). Jika ditolak Admin, saldo otomatis dikembalikan ke dompet.
- **Klaim Talangan Donasi Panti Asuhan**: Muncul di menu **`Keuangan & QRIS` Web Admin** lengkap dengan foto nota belanja dan foto donasi panti asuhan. Begitu Admin klik **"Setujui Klaim"**, uang pengganti talangan (`Nota + Parkir`) langsung masuk menambah saldo dompet Driver (+ notifikasi FCM).

### 12. Sistem Telepon Suara Asli Dua Arah di Dalam Aplikasi (`WebRTC VoIP`)
Menghubungkan [voice_call_overlay.dart](../apps/customer_app/lib/features/chat/presentation/modules/call/voice_call_overlay.dart) (`customer_app`) dan [call_screen.dart](../apps/driver_app/lib/screens/chat/call_screen.dart) (`driver_app`) menjadi telepon suara asli lewat internet (100% gratis) menggunakan **`flutter_webrtc`**:
1. **Tahap 1 — Dering (*Signaling* via Firebase RTDB)**: Saat Customer menekan tombol Telepon, HP Customer mengirim paket sinyal panggilan (*SDP Offer*) ke **Firebase RTDB** `/calls/{orderId}` (`status: "ringing"`). HP Driver langsung memunculkan layar `CallScreen` dan berdering secara real-time.
2. **Tahap 2 — Angkat Telepon & Pertukaran Jalur (*STUN Google Gratis*)**: Saat Driver menekan tombol **Angkat**, HP Driver membalas dengan *SDP Answer* ke `/calls/{orderId}` (`status: "connected"`), dan kedua HP bertukar alamat jaringan (*ICE Candidates*) melalui server STUN publik gratis Google (`stun:stun.l.google.com:19302`).
3. **Tahap 3 — Suara Mengalir Langsung Antar 2 HP (*Peer-to-Peer Audio*)**: Suara mikrofon HP Customer mengalir langsung ke speaker HP Driver (dan sebaliknya). Tombol **Mute** dan **Speaker** di layar kedua aplikasi mengontrol mikrofon & speakerphone asli perangkat tanpa membebani MySQL maupun VM OCI.

### 13. Fitur Beranda (`Cek Promo`, `Pilihan Terlaris`, `Rekomendasi Wisata`), `Favorit`, `Rating`, Upload File, & Login Web Admin
- **Beranda `customer_app`**:
  - `Cek Promo`: Diambil dari tabel `promotions` MySQL (dapat ditambah/diatur dari Web Admin).
  - `Pilihan Terlaris` & `Top 20 Leaderboard`: Diambil otomatis dari menu `store_menus` MySQL dengan penjualan & rating tertinggi.
  - `Rekomendasi Wisata`: Klik kartu destinasi wisata langsung membuka `FlexRide` dengan koordinat tujuan wisata otomatis terisi.
- **Favorit & Rating Bintang 1–5**: Tersimpan permanen di tabel `user_favorites` & `ratings` MySQL; pemberian rating setelah order selesai otomatis memperbarui skor rata-rata bintang Driver dan Toko.
- **Penyimpanan File Upload (`/uploads/*`)**: Disimpan melalui `POST /v1/upload` di `services/rideon-api` ke folder volume persisten `/app/uploads/...` (memanfaatkan disk 50 GB VM OCI) dan disajikan lewat `https://api.rideons.app/uploads/...`.
- **Halaman Login Proteksi Web Admin (`admin.rideons.app`)**: Menambahkan halaman Login Admin (Email & Password Admin terhadap tabel `users` MySQL dengan `role = 'admin'`) sebelum dapat mengakses dashboard `apps/admin-RideOn`.

---

## Bagian 9 — Matriks Cakupan Pengerjaan Menyeluruh (9 Komponen) & 6 Tahap Eksekusi

### A. Matriks Cakupan Pengerjaan pada Seluruh 9 Komponen Ekosistem

| No | Komponen / Folder | Rincian Pekerjaan yang Akan Dilakukan |
|---|---|---|
| **1** | **Kontainer & Database (`compose.yaml`, `docker/`, MySQL `rideon_db`)** | • Membuat `compose.yaml` (kompatibel Podman & Docker) + konfigurasi Nginx.<br>• Membuat skema SQL lengkap **21 tabel MySQL (`rideon_db`)** + **Seeder Awal area Lhokseumawe & Aceh Utara**. |
| **2** | **`services/rideon-api` (Golang — Baru)** | • Autentikasi JWT RideOn (Email, Nomor WA, & Google) + sinkronisasi otomatis ke Firebase Authentication Console.<br>• Pengiriman **Email OTP via Resend (`noreply@rideons.app`)** + balasan tiket CS & fallback via **Gmail SMTP**.<br>• Seluruh API Pendaftaran Mitra, CRUD Menu Toko, Pembuatan Order (`FlexRide`, `FlexFood`, `FlexSend`), Hitung Jarak/Ongkir Rute OSM, Atomic Lock Rebutan Driver, Akuntansi Komisi 5%:5% & Toleransi Minus `-Rp 20.000`, Withdraw, Klaim Talangan Donasi, Upload Foto (`/uploads/*`), **Firebase RTDB Ping**, **FCM Push Notification**, + file **Postman Collection JSON**. |
| **3** | **`services/payg` (Golang — Adaptasi untuk RideOn)** | • Mengadaptasi kode `payG` ke `services/payg` RideOn dan menghubungkannya ke tabel `qris_transactions` MySQL (`rideon_db`).<br>• Menambahkan endpoint penerima webhook **MacroDroid** (`POST /pay/webhook/macrodroid`) untuk pelunasan otomatis Order Customer & Top-Up Saldo Deposit Driver (+ trigger RTDB & FCM). |
| **4** | **`services/ai-service` (Golang — Baru)** | • Membangun Engine AI Universal (`standard_v1.go` untuk `openai_compatible` & `native_gen.go` untuk `gemini_native`) yang membaca daftar provider terenkripsi (`AES-256-GCM`) secara dinamis dari tabel `ai_providers` MySQL.<br>• Melayani **CS AI Pintar 24/7** (In-App di 3 aplikasi & WhatsApp via `wa-gateway`) dengan *Safe Action Boundary*, **AI Rekomendasi Makanan**, **AI Pembuat Deskripsi Menu Toko**, **AI Ringkasan Belanja Driver**, dan **AI Ringkasan Admin**. |
| **5** | **`services/wa-gateway` (Node.js — Sudah Ada)** | • Merapikan `Dockerfile` & integrasi di `compose.yaml` dengan tabel `whatsapp_sessions` MySQL (`rideon_db`) serta meneruskan pesan chat WA masuk ke `services/ai-service`. |
| **6** | **`apps/admin-RideOn` (Next.js Web Admin)** | • Menambahkan **Halaman Login Admin**.<br>• Menyambungkan ke-7 menu yang sudah ada (`Ringkasan`, `Peta Aktif`, `Pendaftaran Baru`, `Pesanan`, `Driver`, `Toko`, `Customer`) dari data dummy ke API nyata **MySQL (`rideon_db`) & Firebase RTDB**.<br>• Menambahkan 2 menu baru: **`Keuangan & QRIS`** (Approve Withdraw Toko/Driver, Approve Klaim Talangan Donasi Panti Asuhan, Setting Static QRIS, Log Mutasi `payG`) dan **`Pengaturan AI & Tarif`** (Tambah/Edit/Urutkan Provider AI secara manual dari Web Admin, Edit Tarif Ongkir/Komisi, & Monitoring Tiket CS AI). |
| **7** | **`apps/page_toko` (Flutter Mitra Toko)** | • Memasang SDK Firebase (`firebase_core`, `firebase_auth`, `firebase_database`, `firebase_messaging`).<br>• Menyambungkan Login & Registrasi Toko (+ ambil koordinat GPS/OSM Nominatim & upload berkas usaha ke MySQL), CRUD Menu Makanan (+ tombol **AI Buat Deskripsi Menu**), penerimaan pesanan `FlexFood` real-time (+ FCM), Tarik Saldo Toko pakai PIN, & **CS AI Mitra Toko**. |
| **8** | **`apps/driver_app` (Flutter Mitra Driver)** | • Menyambungkan Login & Registrasi Driver (+ upload foto KTP/SIM/STNK ke MySQL untuk diverifikasi di Web Admin).<br>• Mempertahankan kirim GPS tiap 3 detik & status Online/Offline di **Firebase RTDB** (`driver_locations` & `driver_presence`).<br>• Menyambungkan pop-up terima order 16 detik (Broadcast + Atomic Lock MySQL), alur belanja multi-lokasi & input nota asli `FlexSend`, Dompet Driver (**Top-Up Deposit via QRIS `payG`**, Withdraw, Klaim Talangan Donasi Panti Asuhan), Telepon Suara Asli **WebRTC**, serta **CS AI Mitra Driver** & AI ringkasan belanja. |
| **9** | **`apps/customer_app` (Flutter Customer)** | • Menyambungkan seluruh endpoint ke backend (`https://api.rideons.app` dengan dukungan override lokal `--dart-define`), katalog `FlexFood` asli dari MySQL, hitung jarak/tarif rute OSM (`FlexRide` Motor/Mobil, `FlexFood`, `FlexSend`), Beranda (`Cek Promo`, `Pilihan Terlaris`, `Rekomendasi Wisata`), `Favorit`, `Riwayat & Rating`, Checkout **Tunai & QRIS Dinamis (`payG`)**, live tracking driver di peta OSM, Telepon Suara Asli **WebRTC**, Chat Customer↔Driver (+ AI Quick Reply), serta **CS AI Customer & AI Food Recommender**. |

---

### B. Urutan 6 Tahap Eksekusi Pengerjaan (Lokal Laptop Dulu → Baru Deploy VM OCI)

1. **Tahap 1 — Fondasi Kontainer Lokal (`compose.yaml`) & Database MySQL (`rideon_db`)**
   - Membuat `compose.yaml` (Podman & Docker ready), konfigurasi Nginx, serta skema SQL lengkap **21 tabel MySQL (`rideon_db`)** beserta **Seeder Awal area Lhokseumawe & Aceh Utara**.
2. **Tahap 2 — Pembangunan 3 Service Golang (`rideon-api`, `payg`, `ai-service`), Integrasi `wa-gateway`, & Postman Collection**
   - Membangun `services/rideon-api`, `services/payg`, dan `services/ai-service`, menyambungkan `services/wa-gateway`, serta membuat file **Postman Collection JSON** untuk menguji seluruh endpoint.
3. **Tahap 3 — Integrasi Penuh `apps/admin-RideOn` (Next.js Web Admin)**
   - Menambahkan Login Admin, menyambungkan ke-7 halaman yang ada + 2 halaman baru (`Keuangan & QRIS` dan `Pengaturan AI & Tarif`) ke MySQL & Firebase RTDB.
4. **Tahap 4 — Integrasi Penuh `apps/page_toko` (Aplikasi Mitra Toko)**
   - Memasang SDK Firebase, menyambungkan registrasi toko, manajemen menu (+ AI Copywriter), penerimaan pesanan `FlexFood` real-time, tarik saldo, & CS AI Toko.
5. **Tahap 5 — Integrasi Penuh `apps/driver_app` (Aplikasi Mitra Driver)**
   - Menyambungkan registrasi berkas driver, radar terima order 16 detik (Broadcast + Atomic Lock), alur belanja & nota asli `FlexSend`, dompet driver (Top-Up QRIS `payG`, Withdraw, Klaim Talangan Donasi Panti Asuhan), Telepon Suara WebRTC, & CS AI Driver.
6. **Tahap 6 — Integrasi Penuh `apps/customer_app` & Deployment ke VM OCI (`rideons.app`)**
   - Menyambungkan seluruh fitur `customer_app` (`FlexRide`, `FlexFood`, `FlexSend`, QRIS `payG`, Telepon WebRTC, CS AI & Rekomendasi Makanan) dan menguji siklus penuh 1 ekosistem di lokal.
   - Setelah teruji 100% di lokal, membuat VM OCI `rideon-prod` (`VM.Standard.E5.Flex` `1 OCPU / 6 GB RAM`), mengarahkan Cloudflare `rideons.app` (`Full Strict` + Certbot SSL), verifikasi DNS Resend, dan menjalankan `docker compose up -d --build`.

---

## Bagian 10 — Lampiran Konstanta Referensi Teknis Proyek

- **Identitas Firebase & Android**:
  - **Firebase Project ID**: `rideon-9eb77`
  - **Android Package Names**:
    - `customer_app`: `com.rideon.customer`
    - `driver_app`: `com.rideon.driver`
    - `page_toko`: `com.rideon.page_toko`
  - **Debug SHA-1 Fingerprint**: `46:1C:47:0F:77:A0:A5:39:70:98:CE:E3:E4:4A:15:7D:75:26:68:17`
- **Design Tokens Warna Resmi RideOn**:
  - Primary Purple: `#6B48FC` | Container Pale Purple: `#C6BCFF` | Dark Navy / Ink: `#17152B`
  - Success Green: `#16A34A` | Error Red: `#E11D48` | Warning Gold: `#FFB800` | Splash Gradient: `#6B48FC` → `#C6BCFF`
- **Referensi Konfigurasi SMTP Gmail CS & Fallback OTP**:
  - Host: `smtp.gmail.com` | Port: `587` (STARTTLS) / `465` (SSL)
  - Cara membuat *App Password* 16 digit: Buka Akun Google → *Security* → aktifkan *2-Step Verification* → *App Passwords* → buat password khusus aplikasi (`16 karakter` tanpa spasi).
