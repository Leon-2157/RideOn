# RideOn - Dokumen Spesifikasi Desain & Revisi UI/UX: Alur Registrasi & Verifikasi OTP

**Dokumen Revisi Teknis & Desain untuk Tim UI/UX dan Mobile Frontend**  
*Status: Approved for Design & Implementation Revision*  
*Target Modul: Customer App (`apps/customer_app`)*  

---

## 1. Latar Belakang & Masalah Desain Saat Ini (Problem Statement)

Berdasarkan hasil audit alur autentikasi dan implementasi database di **RideOn Customer App**:

1. **Inkonsistensi Form Login vs Form Register**:
   - Di halaman Login (`Login.png`), terdapat input bertuliskan: **`No. WhatsApp / Email`** dan **`Kata Sandi`**.
   - Namun di halaman Pendaftaran (`daftar akun.png`), kolom **`Email`** tidak tersedia sama sekali (hanya ada Nama Lengkap dan No. WhatsApp). Akibatnya, sistem tidak bisa mencatat email pengguna untuk login alternatif maupun pemulihan akun.

2. **Celah Keamanan & Validasi Kontak (Missing OTP Step)**:
   - Di desain Figma saat ini, setelah menekan tombol **"BUAT AKUN"**, aplikasi langsung menampilkan dialog **"Akun berhasil dibuat!"** (`berhasil daftar.png`).
   - Tidak ada proses verifikasi bahwa nomor WhatsApp yang diinput benar-benar aktif dan milik pengguna tersebut. Siapa pun bisa memasukkan nomor sembarangan.
   - Layar verifikasi OTP (`verif.png`, `verif angka.png`, `verif salah.png`) di Figma saat ini **hanya dipasang pada alur Lupa Kata Sandi**, belum dihubungkan ke alur Pendaftaran Akun Baru.

---

## 2. Alur Pengguna Baru yang Direvisi (User Flow Baris-ke-Baris)

Berikut alur baru berstandar industri (selaras dengan pola Gojek, Grab, & Maxim):

```
+-----------------------------------------------------------------------------------+
|                        ALUR LENGKAP PENDAFTARAN CUSTOMER                          |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
                         [Layar 1: Form Pendaftaran Akun]
                         - Input 1: Nama Lengkap *
                         - Input 2: Alamat Email (Opsional)
                         - Input 3: No. WhatsApp Aktif (Country Picker 🇮🇩 +62) *
                         - Input 4: Kata Sandi (Min. 8 karakter) (Ikon Mata) *
                         - Input 5: Ulangi Kata Sandi (Validasi Match) *
                         - Checkbox: Setuju Syarat & Ketentuan
                                          |
                                          v
                               [Tekan Tombol 'BUAT AKUN']
                                          |
                                          v
                    [Layar 2: Verifikasi OTP Nomor WhatsApp]
                    - Aset Figma: verif otp daftar.png
                    - Pengiriman: WhatsApp Gateway (Default)
                    - Input: 6 Digit Kotak PIN
                    - Hitung Mundur Resend: 60 detik
                    - Tombol Cadangan: "Tidak menerima kode di WhatsApp? Kirim via SMS"
                                          |
                                          +-------------------------+
                                          |                         |
                               (OTP Valid) v               (OTP Salah) v
                         [Akun Aktif Dibuat]            [verif salah.png]
                         - Firestore: /users/{uid}      - Notifikasi Error
                         - Status: Phone Verified       - Tombol Coba Lagi
                         - Langsung Masuk Beranda
                                          |
                                          v
                    [Fallback Otomatis jika WA Gateway Down]
                    - Aset Figma: dialog fallback sms.png
                    - Pop-Up Dialog: "Layanan WhatsApp sedang pemeliharaan.
                      Ingin kirim kode verifikasi melalui SMS saja?"
                    - Tombol: "KIRIM KODE VIA SMS" (via Firebase Phone Auth)
                                          |
                                          v
                     [Opsional: Verifikasi Email di Profil]
                     - Letak: Halaman Pengaturan Akun / Profil
                     - Aset Figma: HalamanPengaturanAkun/alamat email.png
                     - Mengirimkan kode OTP / link verifikasi ke Email
                     - Menjamin 100% email valid & terverifikasi tanpa
                       memperlambat proses pendaftaran awal.
                                          |
                                          | [User Klik "BUAT AKUN"]
                                          v
                          (Sistem Validasi Format & Cek Unik)
                                          |
                                          v
                         [Layar 2: Verifikasi OTP WhatsApp]
                         - Pesan: "Kode verifikasi 6 digit telah dikirim ke WhatsApp +62812xxxx"
                         - 6 Kotak Input PIN OTP (Auto-focus)
                         - Countdown timer: "Kirim ulang kode dalam (00:59)"
                         - Tombol "Kirim Ulang Kode" (Aktif setelah timer 00:00)
                         - Error State: Kotak merah jika kode salah ("Kode OTP tidak sesuai")
                                          |
                                          | [User Input 6 Digit Benar]
                                          v
                      [Layar 3: Dialog Berhasil & Selesai]
                      - Tampilan: Pop-up Frosted Glass (Figma: berhasil daftar.png)
                      - Teks: "Akun Berhasil Dibuat! Silakan masuk dengan akun yang telah Anda daftarkan."
                      - Tombol: "MASUK SEKARANG" -> Mengarahkan user kembali ke Layar Login (LoginScreen)
```

---

## 3. Rincian Kebutuhan Desain untuk Rekan UI/UX

Rekan tim UI/UX diharapkan memperbarui komponen berikut di Figma:

### A. Revisi Frame `daftar akun.png`
1. **Tambahkan Kolom Input Email**:
   - Letak: Di bawah kolom *Nama Lengkap* dan di atas *No. WhatsApp Aktif*.
   - Ikon Prefix: Ikon amplop/email (`Icons.mail_outline_rounded`).
   - Placeholder: `Alamat Email (Opsional)` (Contoh: `nama@email.com`).
   - Keyboard Type: `TextInputType.emailAddress`.

2. **Hierarki Input Menjadi 5 Field Lengkap**:
   - `[Field 1]` Nama Lengkap * (Wajib)
   - `[Field 2]` Alamat Email (Opsional)
   - `[Field 3]` No. WhatsApp Aktif * (Wajib) ⭐ *(Dilengkapi Country Code & Flag Picker: 🇮🇩 +62, pencegahan angka 0 di awal, dan auto-spacing format `XXX XXXX XXXX`)*
   - `[Field 4]` Kata Sandi (Min. 8 karakter) * (Wajib) (dengan toggle mata dan indikator validasi real-time)
   - `[Field 5]` Ulangi Kata Sandi * (Wajib) (dengan toggle mata dan indikator kecocokan real-time)

3. **Sistem Validasi Visual Interaktif yang Bersih (Clean UI)**:
   - **Tampilan Awal Netral (Pristine)**: Saat layar baru dibuka, seluruh form berborder netral putih transparan / frosted glass persis seperti desain Figma asli, tanpa warna merah mendadak.
   - **Aksen Border Muncul Setelah Diisi**:
     - Jika field sudah mulai diketik dan isinya valid: border berganti aksen hijau emerald halus (`#00B894`).
     - Jika field sudah mulai diketik namun belum memenuhi syarat (misal nama < 3 huruf, sandi < 8 karakter, atau ulangi sandi belum cocok): border berganti aksen merah halus (`#E83535`).
   - **Desain Bersih Tanpa Ikon Silang/Centang**: Tanda silang `(x)` dan centang `(✓)` di dalam form telah dihilangkan agar tampilan tetap bersih (*clean & uncluttered*). Ikon prefix tetap berwarna gelap asli Figma, dan hanya tombol mata (eye toggle) yang ditampilkan pada form kata sandi.
   - **Pencegahan Format Nomor Telepon**: Sistem otomatis memotong angka `0` jika user mengetik setelah kode negara (misal `0853` otomatis menjadi `853`), serta memberikan pemisah spasi otomatis (contoh: `853 2344 1080`).
   - **State Tombol "BUAT AKUN" Dinamis**: Tombol dalam keadaan disabled (abu-abu nonaktif) dan tidak dapat ditekan selama ada field yang belum valid atau checkbox Syarat & Ketentuan belum dicentang. Tombol aktif otomatis berwarna biru gelap (`#17152B`) saat seluruh form telah terisi benar.

---

### B. Hubungkan Template Layar OTP ke Alur Pendaftaran
Rekan desainer **tidak perlu menggambar layar baru dari nol**. Cukup memanfaatkan dan mengadaptasi frame yang sudah ada di Figma:

1. **Frame Basis**: Gunakan layout dari `verif.png` & `verif angka.png`.
2. **Teks Judul**: `"Verifikasi Nomor WhatsApp"`.
3. **Sub-judul**: `"Masukkan 6 digit kode yang kami kirimkan ke nomor WhatsApp Anda +62 812-XXXX-XXXX"`.
4. **Input Komponen**: 6 kotak input rounded frosted glass (sesuai `verif angka.png`).
5. **State Error**: Tampilan border merah dan teks error sesuai `verif salah.png` jika kode salah.
6. **State Resend**: Timer 60 detik dengan tombol teks interaktif *"Kirim Ulang via WhatsApp / SMS"*.

---

## 4. Alasan Teknis & Keuntungan Bisnis

| Aspek | Alur Lama (Sebelum Revisi) | Alur Baru (Setelah Revisi) |
| :--- | :--- | :--- |
| **Keamanan Akun** | Rentan akun bot/spam karena nomor HP tidak diverifikasi. | 100% nomor WhatsApp terverifikasi aktif sebelum akun dibuat. |
| **Konektivitas Driver** | Driver kesulitan menghubungi nomor customer jika nomor palsu. | Driver pasti bisa menghubungi via WhatsApp/telepon saat pesanan dibuat. |
| **Login Fleksibel** | User bingung login via email karena tidak pernah input email saat daftar. | User bisa login bebas memilih: via Email ATAU via Nomor WhatsApp. |
| **Pemulihan Password** | Jika nomor WA hilang, akun hilang selamanya. | Pengguna bisa mereset password via Email resmi yang terdaftar. |

---

## 5. Status Implementasi di Kode Saat Ini

- **Model Data Firestore**: Koleksi `/users/{uid}` sudah siap menampung field `email` dan `phoneNumber` secara bersamaan.
- **Backend Service**: `AuthService.dart` sudah memiliki normalisasi format nomor Indonesia (`+62...`) dan smart detector.
- **Frontend Code**: Logika transisi OTP di `forgot_password_screen.dart` sudah teruji dan siap diadaptasi ke alur pendaftaran segera setelah desain disepakati.

