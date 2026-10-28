# AGENT.md - Aturan & Panduan Pengembangan `page_toko`

Dokumen ini adalah instruksi operasional untuk AI agent dan developer yang mengerjakan proyek **page_toko**.

---

## 1. Lingkup Proyek & Peran
- **Nama Proyek:** `page_toko`
- **Fokus Tunggal:** Modul **Mitra Toko (Store/Merchant)** aplikasi RideOn.
- **Batasan Ketat:** Hanya kerjakan fitur dan file di dalam folder `page_toko/`. Jangan memodifikasi modul Customer atau Driver di luar direktori ini.
- **Sumber Desain:** Gambar & aset Figma tersimpan di `C:\Users\fikri\OneDrive\Documents\TOKO`.

---

## 2. Struktur Modul Toko (5 Tab Navigasi)
Setiap modul di bawah merujuk ke sub-folder desain di `C:\Users\fikri\OneDrive\Documents\TOKO`:
1. **Autentikasi & Pendaftaran (`halaman login`):**
   - Login Pemilik Toko & validasi error
   - Lupa Sandi, OTP WA, Sandi Baru
   - Pendaftaran Mitra Toko Step 1 & Step 2 (Upload STNK, Rekening, SKCK, Foto Tempat Usaha)
   - Dialog Syarat & Ketentuan
2. **Tab 1: Home / Beranda (`halaman home`):**
   - Toggle Status Buka / Tutup Toko
   - Ringkasan Omzet & Performa Hari Ini
   - Notifikasi & pesanan live
3. **Tab 2: Pesanan (`halaman pesanan`):**
   - Filter tab: Baru, Dimasak, Siap Diserahkan ke Kurir, Selesai/Batal
   - Rincian detail pesanan & kontak kurir
4. **Tab 3: Menu (`halaman menu`):**
   - Katalog daftar menu makanan/minuman
   - Toggle status stok (Aktif / Habis)
   - Form Tambah & Edit Menu beserta foto
5. **Tab 4: Keuangan / Uang (`halaman uang`):**
   - Tampilan saldo aktif toko
   - Riwayat detail transaksi masuk & keluar
   - Pengaturan Rekening Bank (Tambah / Hapus)
   - Form penarikan saldo dengan verifikasi PIN / sandi
6. **Tab 5: Toko / Profil Resto (`halaman toko`):**
   - Profil Resto (Foto, Nama, Deskripsi)
   - Pengaturan Jam Operasional (Buka / Tutup per hari)
   - Pengaturan Pinpoint & Alamat Lokasi Toko

---

## 3. Aturan Kode & Arsitektur
- **Framework:** Flutter (Material 3).
- **Tema Warna Resmi:**
  - Primary Purple: `#6B48FC`
  - Container Pale Purple: `#C6BCFF`
  - Dark Navy / Ink: `#17152B`
  - Success Green: `#16A34A`
  - Error Red: `#E11D48`
  - Warning Gold: `#FFB800`
- **Disiplin Kode:**
  - Bersih, responsif, zero lint warnings (`flutter analyze`).
  - Tidak ada URL gambar cloud sementara (gunakan asset/icon Flutter teruji).
  - Satukan variasi status (micro-states) ke dalam stateful widget reaktif, jangan menduplikasi file screen.
