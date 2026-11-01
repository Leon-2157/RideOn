# RideOn — WhatsApp Gateway Service

> **Microservice:** `services/wa-gateway`  
> **Library:** `@whiskeysockets/baileys` (Multi-Device Engine) + `express`  
> **Penyimpanan Sesi:** Local Filesystem (`storage/sessions/`)  
> **Status:** Production Ready & Connected to `customer_app`

---

## 1. Menjalankan Server Gateway

Untuk menyalakan server WhatsApp Gateway:

```bash
cd services/wa-gateway
npm start
```

Server akan aktif di port **3000** (`http://localhost:3000`).

---

## 2. Memindai (Scan) QR Code WhatsApp

1. Buka browser di laptop Anda:
   ```
   http://localhost:3000/qr
   ```
2. Buka aplikasi **WhatsApp** di HP Anda (Nomor Resmi RideOn atau nomor uji coba):
   - Klik **Titik Tiga** (Android) / **Pengaturan** (iPhone).
   - Pilih **Perangkat Tertaut** (*Linked Devices*).
   - Klik **Tautkan Perangkat** (*Link a Device*).
3. Arahkan kamera HP ke layar laptop untuk memindai QR code.
4. Dalam 2-3 detik, layar akan berubah menjadi **"WhatsApp Terhubung"**. Sesi tersimpan otomatis di `storage/sessions/` sehingga tidak perlu scan ulang saat server di-restart!

---

## 3. Endpoints API

| Method | Endpoint | Deskripsi |
| :--- | :--- | :--- |
| `GET` | `/health` | Status kesehatan server |
| `GET` | `/status` | Status koneksi WhatsApp & nomor yang tertaut |
| `GET` | `/qr` | Halaman scan QR code di browser |
| `POST` | `/api/otp/send` | Generate & kirim 6-digit OTP via WhatsApp |
| `POST` | `/api/otp/verify`| Verifikasi 6-digit OTP |
| `POST` | `/send` | Kirim pesan WhatsApp umum (notifikasi driver/toko) |

---

## 4. ADB Port Forwarding untuk HP Fisik (USB Debugging)

Agar HP Android fisik yang terhubung via kabel USB bisa mengakses server laptop di `http://localhost:3000`:

```bash
adb reverse tcp:3000 tcp:3000
```

