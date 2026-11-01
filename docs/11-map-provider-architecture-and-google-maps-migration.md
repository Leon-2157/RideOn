# 11 - Panduan Arsitektur Peta RideOn & SOP Migrasi ke Google Maps Platform

> **Status:** Active & Implemented  
> **Modul:** Peta & Lokasi Customer App (`apps/customer_app`)  
> **Penyedia Peta Aktif:** OpenStreetMap (`flutter_map`) — 100% Zero-Cost & Ready-to-Use  
> **Target Migrasi:** Google Maps Platform (`google_maps_flutter`)  
> **Terakhir Diperbarui:** 30 Oktober 2026

---

## 📌 1. Ringkasan Eksekutif & Keputusan Arsitektur

Berdasarkan kesepakatan desain, subsistem pemetaan RideOn mengadopsi pendekatan dua lapis (*two-tier architecture*):

1. **Fase 1 (Saat Ini — Aktif): OpenStreetMap & Native Geolocation**
   * Menggunakan kombinasi `flutter_map`, `latlong2`, `geolocator`, dan `geocoding`.
   * **100% Gratis selamanya**, tidak memerlukan kartu kredit/debit saat ini, tanpa biaya per request, dan langsung aktif dapat dicoba di perangkat fisik pengembang.
   * Mengimplementasikan fitur **"Lokasi Anda"** (`LokasiAndaScreen`) sesuai desain Figma `atur lokadi.png` dan `lokasi berhasil.png`:
     * Peta interaktif dengan *Center Pin Marker* (geser peta untuk mengunci titik presisi).
     * Tombol *"Gunakan Titik GPS Saat Ini"* yang mengakses sensor satelit perangkat secara langsung.
     * *Auto Reverse Geocoding* yang menerjemahkan titik koordinat ke alamat jalan, kelurahan, kota di Indonesia.
     * *Multi-Label Saved Places* (🏠 **Rumah**, 🏢 **Kantor**, 🏢 **Kost**, 📍 **Lainnya**) + Catatan Patokan.
     * Sinkronisasi data ke Cloud Firestore path `/users/{uid}` field `savedAddress`.

2. **Fase 2 (Rencana Masa Depan): Migrasi ke Google Maps Platform**
   * Menggunakan `google_maps_flutter` ketika pengembang siap mengaktifkan penagihan Google Cloud dengan kartu Visa Bank Jago.
   * Memanfaatkan kuota gratis Google Cloud sebesar **\$200 USD per bulan** (~28.000 panggilan peta dinamis gratis setiap bulan).
   * Menghadirkan akurasi nomor 1 untuk jalan gang sempit di Indonesia serta garis rute belokan tajam (*turn-by-turn navigation*).

---

## 🏗️ 2. Arsitektur Komponen yang Telah Diimplementasikan

```
apps/customer_app/
│
├── lib/features/pengaturan/presentation/pages/
│   ├── pengaturan_akun_screen.dart    ← Menu utama 'Lokasi Anda (Atur lokasi)'
│   └── lokasi_anda_screen.dart         ← Screen Peta Interaktif & Multi-Label
│
└── android/app/src/main/
    └── AndroidManifest.xml             ← Izin ACCESS_FINE_LOCATION & ACCESS_COARSE_LOCATION
```

### A. Fitur Layar `LokasiAndaScreen`
* **Interaktivitas Peta:** Menggunakan OpenStreetMap raster tiles resolusi tinggi dengan kontrol Zoom In (`+`), Zoom Out (`-`), dan tombol *Quick Recenter GPS*.
* **Floating Center Pin:** Label *"Geser peta untuk atur titik"* memandu pengguna mengarahkan jarum pin tepat di atas atap rumah atau titik jemput yang diinginkan.
* **Geocoding Otomatis:** Saat peta selesai digeser (`MapEventMoveEnd`), sistem otomatis mengambil nama jalan terbaru tanpa perlu menekan tombol apapun.
* **Penyimpanan Multi-Label di Cloud Firestore:**
  ```json
  {
    "savedAddress": {
      "latitude": 5.2472,
      "longitude": 97.0261,
      "address": "Keudekruenggeukueh, Dewantara, Aceh Utara, Aceh, 24354, Indonesia",
      "label": "Rumah",
      "note": "Pagar hitam nomor 12 samping musholla",
      "updatedAt": "Timestamp"
    }
  }
  ```

---

## 💳 3. Panduan Lengkap SOP Migrasi ke Google Maps Platform

Ketika Anda sudah siap mendaftarkan kartu Visa Bank Jago ke Google Cloud, ikuti panduan langkah-demi-langkah berikut:

### Langkah A: Aktivasi Google Cloud Billing dengan Visa Bank Jago
1. Buka browser dan kunjungi: **[https://console.cloud.google.com/billing](https://console.cloud.google.com/billing)**.
2. Masuk menggunakan akun Google yang sama dengan pemilik project Firebase RideOn (`rideon-9eb77`).
3. Pada dropdown project di bilah navigasi atas, pastikan project yang dipilih adalah **`RideOn`** (atau `rideon-9eb77`).
4. Klik tombol **Manage Billing Accounts** $\rightarrow$ **Add Billing Account** (atau **Link a Billing Account**).
5. Pilih Negara: **Indonesia**.
6. Pada jenis akun, pilih **Individual** (atau Bisnis jika berbadan hukum).
7. Masukkan detail kartu pembayaran Visa Bank Jago Anda:
   * **Nomor Kartu:** 16 digit nomor kartu Visa Bank Jago (dapat dilihat di aplikasi Jago menu *Kartu/Cards*).
   * **Masa Berlaku (Exp):** Bulan / Tahun (MM/YY).
   * **Kode Keamanan (CVV):** 3 digit di belakang kartu atau di aplikasi Jago.
   * **Nama Pemilik:** Nama lengkap Anda sesuai akun Bank Jago.
   * **Alamat Penagihan:** Alamat domisili Anda di Indonesia.
8. **PENTING — Saldo Minimal:** Pastikan kantong utama Bank Jago Anda memiliki saldo aktif minimal **Rp 20.000**. Google akan melakukan tes debet otorisasi sementara sekitar \$1 USD (Rp 16.000) untuk memvalidasi kartu. Dana ini akan **otomatis dikembalikan/di-refund** dalam hitungan menit.
9. Klik **Start My Free Trial** atau **Submit and Enable Billing**.

> [!TIP]
> **Mengapa Aman?** Google Maps memberikan saldo kredit gratis **\$200 USD setiap bulan** secara otomatis. Selama pemakaian peta untuk pengembangan dan uji coba tim tidak melebihi ~28.000 kali muat peta per bulan, saldo Bank Jago Anda **tidak akan pernah terpotong sepeser pun**.

---

### Langkah B: Mengaktifkan Google Maps API di Library
Setelah akun penagihan aktif:
1. Masuk ke menu **APIs & Services** $\rightarrow$ **Library** (atau [klik tautan ini](https://console.cloud.google.com/apis/library)).
2. Di kotak pencarian, cari dan klik tombol **ENABLE** pada 3 API penting berikut:
   1. **`Maps SDK for Android`** *(Wajib: untuk menampilkan peta Google di HP Android)*.
   2. **`Geocoding API`** *(Wajib: untuk menerjemahkan koordinat lat/long ke alamat jalan)*.
   3. **`Directions API`** *(Opsional sekarang / Wajib nanti: untuk menggambar garis rute navigasi ojek/mobil driver)*.

---

### Langkah C: Membuat & Mengamankan Google Maps API Key
1. Masuk ke menu **APIs & Services** $\rightarrow$ **Credentials** (atau [klik tautan ini](https://console.cloud.google.com/apis/credentials)).
2. Di bagian atas, klik **+ CREATE CREDENTIALS** $\rightarrow$ pilih **API key**.
3. Sebuah pop-up akan menampilkan API Key baru Anda (contoh: `AIzaSyBxxxxxxxxx-xxxxxxxxx`). Salin (*copy*) kode ini.
4. Klik **Edit API Key** untuk memasang pengaman anti-pencurian kuota (*Key Restrictions*):
   * **Set application restrictions:** Pilih **Android apps**.
   * Klik **+ Add package name and fingerprint**:
     * **Package name:** `com.rideon.customer`
     * **SHA-1 certificate fingerprint:** `46:1C:47:0F:77:A0:A5:39:70:98:CE:E3:E4:4A:15:7D:75:26:68:17` *(SHA-1 laptop pengembang)*
   * **API restrictions:** Pilih **Restrict key** $\rightarrow$ Centang *Maps SDK for Android*, *Geocoding API*, dan *Directions API*.
   * Klik **Save**.

---

### Langkah D: Memasang API Key ke Kode Aplikasi RideOn
Setelah Anda mendapatkan API Key, Anda cukup:
1. Membuka file [`apps/customer_app/android/app/src/main/AndroidManifest.xml`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/android/app/src/main/AndroidManifest.xml).
2. Di dalam tag `<application>`, tambahkan baris berikut:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="PASTE_KODE_API_KEY_ANDA_DI_SINI" />
   ```
3. Di file `apps/customer_app/pubspec.yaml`, tambahkan paket resmi:
   ```yaml
   google_maps_flutter: ^2.10.0
   ```
4. Ganti widget `FlutterMap` dengan `GoogleMap` pada `lokasi_anda_screen.dart`.

---

## 📊 4. Tabel Perbandingan Peta: OpenStreetMap vs Google Maps Platform

| Parameter | OpenStreetMap (Aktif Saat Ini) | Google Maps Platform (Target Migrasi) |
| :--- | :--- | :--- |
| **Biaya** | 100% Gratis Tanpa Batas Waktu | Gratis \$200/bulan (~28.000 dynamic loads/bln) |
| **Kartu Kredit/Debit** | **Tidak Perlu Sama Sekali** | Perlu (Visa Bank Jago / Mastercard) |
| **Akurasi Jalan Utama** | Sangat Baik (95%) | Sangat Baik (100%) |
| **Akurasi Gang & Perumahan** | Baik (Tergantung kontributor daerah) | Luar Biasa Akurat (Nomor 1 di Indonesia) |
| **Nama Tempat / POI Bisnis** | Standar | Lengkap (Warung, toko, ruko, gang kecil) |
| **Kesiapan Uji Coba Tim** | **Langsung Siap Pakai Detik Ini** | Menunggu pembuatan API Key |

---

## 🏁 5. Kesimpulan
Dengan arsitektur ini:
* Anda **bisa langsung menguji coba dan menggunakan fitur peta di aplikasi sekarang juga** tanpa terhalang urusan registrasi bank.
* Kapan pun Anda selesai mendaftarkan kartu Bank Jago di Google Cloud Console, transisi ke Google Maps dapat dilakukan dengan cepat dan mulus.

