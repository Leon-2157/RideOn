# PANDUAN TAKSONOMI & KAMUS PEMETAAN ASET FIGMA (ASSETS-2)

Dokumen ini adalah **Single Source of Truth (SSOT)** pemetaan 93 aset dari Figma (`/home/leon/Documents/assets` dan `/home/leon/Documents/RideOn`) ke folder profesional baru:
📁 **`apps/customer_app/assets-2/`**

---

## 1. Filosofi & Struktur Folder

Aset lama di `apps/customer_app/assets/` **tetap dipertahankan secara utuh** agar aplikasi dan seluruh tes pengujian tetap berjalan 100% hijau (*zero regression*). Folder baru `assets-2/` menggunakan struktur **Hierarki 2 Tingkat**:

```
apps/customer_app/assets-2/
├── icons/                    # Ikon UI vector/raster berukuran kecil
│   ├── navbar/               # 4 ikon menu bawah (status normal & aktif/selected)
│   ├── auth/                 # Ikon Google, gembok, mata, keamanan, verifikasi
│   ├── settings/             # Ikon menu pengaturan akun
│   ├── theme/
│   │   ├── dark/             # Ikon modal tema gelap
│   │   └── light/            # Ikon modal tema terang
│   ├── places/               # Ikon rumah, kantor, mall, maps, titik jemput/tujuan
│   └── actions/              # Ikon kamera, galeri, telepon, mic, speaker, chat, rating
│
└── images/                   # Gambar raster beresolusi tinggi / kartu grafis
    ├── services/             # Kartu layanan (FlexRide, FlexFood, FlexSend, FlexMobil, FlexMotor)
    ├── food/                 # Foto produk makanan FlexFood (Bakso, Kebab, Rendang, dll)
    ├── banners/              # Banner header beranda & promo diskon
    ├── illustrations/        # Ilustrasi gumpalan abstrak, pria bingung, cewek favorit
    ├── avatars/              # Foto profil resmi Figma (JPG)
    └── logo/                 # Logo utama & logo sekunder RideOn
```

---

## 2. Kamus Pemetaan 1-ke-1 (91 File Lengkap)

### A. Ikon Navigasi Bawah (`icons/navbar/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `Beranda.png` | `icons/navbar/ic_nav_beranda.png` | Menu Beranda (Inactive) |
| `BerandaDipilih.png` | `icons/navbar/ic_nav_beranda_active.png` | Menu Beranda (Active / Selected) |
| `Favorit.png` | `icons/navbar/ic_nav_favorit.png` | Menu Favorit (Inactive) |
| `FavoritDipilih.png` | `icons/navbar/ic_nav_favorit_active.png` | Menu Favorit (Active / Selected) |
| `Aktivitas.png` | `icons/navbar/ic_nav_aktivitas.png` | Menu Aktivitas (Inactive) |
| `AktivitasDipilih.png` | `icons/navbar/ic_nav_aktivitas_active.png` | Menu Aktivitas (Active / Selected) |
| `Chat.png` | `icons/navbar/ic_nav_chat.png` | Menu Chat (Inactive) |
| `ChatDipilih.png` | `icons/navbar/ic_nav_chat_active.png` | Menu Chat (Active / Selected) |

### B. Ikon Beranda & Header Bagian (`icons/home/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `PromoIcon.png` | `icons/home/ic_promo.png` | Ikon section header Promo Menarik (14x14) |
| `RekomendasiWisata.png` | `icons/home/ic_wisata.png` | Ikon section header Rekomendasi Wisata (12x12) |

### C. Ikon Autentikasi & Keamanan (`icons/auth/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `Goofle.png` | `icons/auth/ic_google.png` | Ikon Google Sign-In (Koreksi typo Figma) |
| `Back.png` | `icons/auth/ic_back.png` | Tombol panah kembali |
| `Gembok.png` | `icons/auth/ic_lock.png` | Ikon gembok terkunci |
| `GembokBuka.png` | `icons/auth/ic_lock_open.png` | Ikon gembok terbuka |
| `Kunci.png` | `icons/auth/ic_key.png` | Ikon kunci keamanan |
| `HidePassword.png` | `icons/auth/ic_hide_password.png` | Ikon mata sembunyikan sandi |
| `Security.png` | `icons/auth/ic_security.png` | Ikon perisai keamanan akun |
| `Verifikasi.png` | `icons/auth/ic_verifikasi.png` | Ikon status terverifikasi |
| `MasukSekarang.png` | `icons/auth/ic_masuk_sekarang.png` | Ikon aksi masuk |
| `TidakValid.png` | `icons/auth/ic_tidak_valid.png` | Ikon peringatan tanda silang/error |
| `Ceklis.png` | `icons/auth/ic_ceklis.png` | Ikon centang hijau / sukses |
| `Email-Dark.png` | `icons/auth/ic_email_dark.png` | Ikon email versi gelap |
| `WhatsApp-Dark.png` | `icons/auth/ic_whatsapp_dark.png` | Ikon WhatsApp versi gelap |

### C. Ikon Menu Pengaturan (`icons/settings/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `UbahProfil.png` | `icons/settings/ic_ubah_profil.png` | Baris Ubah Profil |
| `UbahTema.png` | `icons/settings/ic_ubah_tema.png` | Baris Ubah Tema |
| `NomorWhatsApp.png` | `icons/settings/ic_nomor_whatsapp.png` | Baris Nomor WhatsApp |
| `AlamatEmail.png` | `icons/settings/ic_alamat_email.png` | Baris Alamat Email |
| `KeamananAkun.png` | `icons/settings/ic_keamanan_akun.png` | Baris Keamanan Akun |
| `LokasiAnda.png` | `icons/settings/ic_lokasi_anda.png` | Baris Lokasi Anda |
| `PrivasiDanSyarat.png` | `icons/settings/ic_privasi_dan_syarat.png` | Baris Kebijakan Privasi |
| `KeluarAkun.png` | `icons/settings/ic_keluar_akun.png` | Baris Tombol Keluar Akun |

### D. Ikon Pemilih Tema Gelap (`icons/theme/dark/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `DarkMode-Close.png` | `icons/theme/dark/ic_dark_close.png` | Tombol silang tutup modal |
| `DarkMode-ModeGelap.png` | `icons/theme/dark/ic_dark_mode_gelap.png` | Opsi Mode Gelap |
| `DarkMode-ModeTerang.png` | `icons/theme/dark/ic_dark_mode_terang.png` | Opsi Mode Terang |
| `DarkMode-OpsiTerpilih.png` | `icons/theme/dark/ic_dark_opsi_terpilih.png` | Radio button aktif |
| `DarkMode-OpsiTidakTerilih.png` | `icons/theme/dark/ic_dark_opsi_tidak_terpilih.png` | Radio button tidak aktif |
| `DarkMode-PilihTema.png` | `icons/theme/dark/ic_dark_pilih_tema.png` | Header ikon tema |
| `DarkMode-Vector.png` | `icons/theme/dark/ic_dark_vector.png` | Aksen grafis tema |

### E. Ikon Pemilih Tema Terang (`icons/theme/light/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `LightMode-Close.png` | `icons/theme/light/ic_light_close.png` | Tombol silang tutup modal |
| `LightMode-IkutiSistem.png` | `icons/theme/light/ic_light_ikuti_sistem.png` | Opsi Ikuti Sistem |
| `LightMode-ModeGelap.png` | `icons/theme/light/ic_light_mode_gelap.png` | Opsi Mode Gelap |
| `LightMode-ModeTerang.png` | `icons/theme/light/ic_light_mode_terang.png` | Opsi Mode Terang |
| `LightMode-OpsiPilih.png` | `icons/theme/light/ic_light_opsi_pilih.png` | Radio button terpilih |
| `LightMode-OpsiTidakTerpilih.png` | `icons/theme/light/ic_light_opsi_tidak_terpilih.png` | Radio button tidak terpilih |
| `LightMode-PilihTema.png` | `icons/theme/light/ic_light_pilih_tema.png` | Header modal tema |

### F. Ikon Tempat & Peta (`icons/places/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `Rumah.png` | `icons/places/ic_place_rumah.png` | Label alamat Rumah |
| `Kantor.png` | `icons/places/ic_place_kantor.png` | Label alamat Kantor |
| `Mall.png` | `icons/places/ic_place_mall.png` | Label alamat Mall / Pusat Belanja |
| `Maps.png` | `icons/places/ic_maps.png` | Ikon peta navigasi |
| `LokasiJemput.png` | `icons/places/ic_lokasi_jemput.png` | Pin titik penjemputan |
| `TujuanPerjalanan.png` | `icons/places/ic_tujuan_perjalanan.png` | Pin titik tujuan |
| `AlamatJemput.png` | `icons/places/ic_alamat_jemput.png` | Baris input alamat jemput |
| `DetailAlamatJemput.png` | `icons/places/ic_detail_alamat_jemput.png` | Rincian alamat jemput |
| `DetailAlamatKirim.png` | `icons/places/ic_detail_alamat_kirim.png` | Rincian alamat kirim barang |
| `PatokanJemput.png` | `icons/places/ic_patokan_jemput.png` | Ikon catatan patokan |
| `LokasidriverMaps.png` | `icons/places/ic_lokasi_driver_maps.png` | Marker motor driver di peta |

### G. Ikon Aksi, Panggilan & Chat (`icons/actions/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `BukaKamera.png` | `icons/actions/ic_action_buka_kamera.png` | Tombol ambil foto kamera |
| `Galeri.png` | `icons/actions/ic_action_galeri.png` | Tombol pilih dari galeri |
| `PilihFotoProfil.png` | `icons/actions/ic_action_pilih_foto.png` | Ikon aksi ganti avatar |
| `SimpanPerubahan.png` | `icons/actions/ic_action_simpan.png` | Tombol simpan perubahan |
| `Call.png` | `icons/actions/ic_action_call.png` | Tombol telepon driver |
| `akhiriPanggilan.png` | `icons/actions/ic_action_akhiri_call.png` | Tombol merah tutup telepon |
| `BisukanCall.png` | `icons/actions/ic_action_bisukan_call.png` | Tombol mute mikrofon |
| `PengerasSuara.png` | `icons/actions/ic_action_speaker.png` | Tombol loudspeaker |
| `KirimPesan.png` | `icons/actions/ic_action_kirim_pesan.png` | Tombol kirim pesan chat |
| `Massege.png` | `icons/actions/ic_action_message.png` | Ikon bubble pesan |
| `Star.png` | `icons/actions/ic_star_filled.png` | Bintang rating kuning |
| `StarKosong.png` | `icons/actions/ic_star_empty.png` | Bintang rating kosong |

### H. Gambar Layanan (`images/services/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `FlexRide.png` | `images/services/img_service_flex_ride.png` | Card Layanan FlexRide |
| `FlexFood.png` | `images/services/img_service_flex_food.png` | Card Layanan FlexFood |
| `FlexSend.png` | `images/services/img_service_flex_send.png` | Card Layanan FlexSend |
| `FlexMobil.png` | `images/services/img_service_flex_mobil.png` | Ikon armada Mobil |
| `FlexMotor.png` | `images/services/img_service_flex_motor.png` | Ikon armada Motor |

### I. Foto Produk Makanan (`images/food/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `BaksoBakar.png` | `images/food/img_food_bakso_bakar.png` | Menu Bakso Bakar |
| `BaksoUrat.png` | `images/food/img_food_bakso_urat.png` | Menu Bakso Urat |
| `KebabTurki.png` | `images/food/img_food_kebab_turki.png` | Menu Kebab Turki |
| `NasiAyamBakar.png` | `images/food/img_food_nasi_ayam_bakar.png` | Menu Nasi Ayam Bakar |
| `NasiGoreng.png` | `images/food/img_food_nasi_goreng.png` | Menu Nasi Goreng |
| `RendangSiUjang.png` | `images/food/img_food_rendang_si_ujang.png` | Menu Rendang Si Ujang |
| `SpandukBankuCity.png` | `images/food/img_food_spanduk_banku_city.png` | Banner Toko Banku City |

### J. Banner Promosi (`images/banners/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `Banner.png` | `images/banners/img_banner_header.png` | Banner promo utama beranda |
| `promo1.jpg` | `images/banners/img_promo_1.jpg` | Promo card 1 |
| `promo2.jpg` | `images/banners/img_promo_2.jpg` | Promo card 2 |
| `promo3.jpg` | `images/banners/img_promo_3.jpg` | Promo card 3 |

### K. Ilustrasi Grafis (`images/illustrations/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `Abstrakloob.png` | `images/illustrations/il_abstrak_blob.png` | Gumpalan ungu abstrak |
| `BingungPilihAlamat.png` | `images/illustrations/il_bingung_pilih_alamat.png` | Ilustrasi pria bingung |
| `OrangFavorit.png` | `images/illustrations/il_orang_favorit.png` | Ilustrasi wanita favorit |
| `MenghubungkanDriver.png` | `images/illustrations/il_menghubungkan_driver.png` | Animasi pencarian driver |
| `DriverTalangi.png` | `images/illustrations/il_driver_talangi.png` | Banner fitur driver talangi |

### L. Avatar Pengguna (`images/avatars/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `FotoProfilFigma` | `images/avatars/img_avatar_figma_1.jpg` | Foto avatar Peter Figma 1 (ditambah ekstensi JPG) |
| `ProfilFigma2` | `images/avatars/img_avatar_figma_2.jpg` | Foto avatar Peter Figma 2 (ditambah ekstensi JPG) |

### M. Logo Brand (`images/logo/`)
| File Asli Figma | Path Baru di `assets-2/` | Keterangan |
| :--- | :--- | :--- |
| `Logo.png` | `images/logo/img_logo_primary.png` | Logo primer RideOn |
| `logo2.png` | `images/logo/img_logo_secondary.png` | Logo sekunder RideOn |

---

## 3. Cara Penggunaan di Kode Flutter

Gunakan class helper terpusat:
```dart
import 'package:rideon/core/constants/app_assets_v2.dart';

// Contoh memanggil icon navbar
Image.asset(AppAssetsV2.navBeranda);

// Contoh memanggil makanan
Image.asset(AppAssetsV2.imgFoodBaksoUrat);

// Contoh memanggil ilustrasi
Image.asset(AppAssetsV2.ilBingungPilihAlamat);
```

