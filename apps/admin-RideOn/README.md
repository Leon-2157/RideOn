# RideOn Admin

Frontend dashboard admin RideOn, dibangun menggunakan Next.js, React, dan TypeScript.

## Menjalankan lokal

Pastikan Node.js sudah terpasang, lalu buka PowerShell di folder project:

```powershell
cd C:\Coding\admin-RideOn
npm install
npm run dev
```

Buka `http://localhost:3000`. Biarkan terminal tetap berjalan selama dashboard digunakan. Untuk menghentikan server, tekan `Ctrl+C` di terminal.

## Tahap saat ini

Project ini berisi frontend/pratinjau. Halaman Ringkasan, Peta Aktif, Pendaftaran Baru, Pesanan, Driver, Toko, dan Customer memakai data demo yang ditandai di antarmuka. Peta memperlihatkan area simulasi untuk driver Taufiq, Fikri, Ghufron, serta Toko Luthfi dan Toko Joni. Marker dapat dipilih dan kategori Driver/Toko dapat difilter. Lokasi belum berasal dari GPS dan tidak tersambung ke Firebase. Pendaftaran Baru memperagakan peninjauan akun customer, driver, dan toko; keputusan setujui/tolak hanya tersimpan sementara di state browser dan akan kembali ke data awal setelah halaman dimuat ulang. Peta menggunakan tile standar OpenStreetMap dengan atribusi terlihat; server tile publik bersifat best-effort dan harus digunakan sesuai kebijakan OSM.

Integrasi backend direncanakan setelah skema data aplikasi mobile RideOn lebih stabil. Dashboard nantinya akan menggunakan project Firebase RideOn yang sama setelah struktur koleksi, field, dan aturan akses admin disepakati bersama tim mobile.
