# Panduan Arsitektur Foto Profil RideOn & Migrasi ke Oracle Cloud (Solusi C)

Dokumen ini menjelaskan strategi penyimpanan foto profil pengguna aplikasi **RideOn**:
1. **Tahap Saat Ini (Development)**: Solusi A — Kompresi & Base64 di Cloud Firestore (100% Gratis & Cloud Sync).
2. **Panduan Migrasi Masa Depan (Production)**: Solusi C — Migrasi ke Oracle Cloud Infrastructure (OCI) Object Storage / Self-Hosted Server.

---

## 1. Arsitektur Saat Ini: Solusi A (Base64 di Cloud Firestore)

### Mengapa Menggunakan Solusi A?
* **Kebijakan Firebase Terbaru**: Firebase Cloud Storage sekarang mewajibkan pendaftaran kartu kredit / Billing Account (Blaze Plan) untuk membuat Storage Bucket baru, meskipun ada kuota gratis bulanan.
* **100% Bebas Biaya ($0.00)**: Firestore Database di paket **Spark (Gratis)** memberikan kuota 1 GB storage dan 50.000 read/hari tanpa kartu kredit.
* **Tersinkronisasi Antar Perangkat**: Foto profil tersimpan langsung di dokumen Firestore `/users/{uid}`, sehingga bisa langsung dibaca oleh aplikasi Driver, Merchant, maupun perangkat lain.

### Spesifikasi Teknis
* **Kompresi**: `maxWidth: 512`, `maxHeight: 512`, `imageQuality: 75%` (format JPEG).
* **Ukuran Data**: ~20 KB – 35 KB per foto (hanya ~3% dari limit 1 dokumen Firestore yang sebesar 1 MB).
* **Format Field Firestore**:
  ```json
  {
    "uid": "pXPmNCgOksZpXqGvj2OgasFTXxp2",
    "name": "Muhammad Taufiq",
    "phoneNumber": "+6285323441080",
    "photoUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "updatedAt": "2026-10-30T02:20:00Z"
  }
  ```
* **Rendering Widget**: Komponen [`UserAvatar`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/core/widgets/user_avatar.dart) otomatis mendeteksi apakah `photoUrl` berupa Base64 (`Image.memory`), URL HTTPS (`Image.network`), atau file lokal (`Image.file`).

---

## 2. Panduan Migrasi ke Solusi C: Oracle Cloud Infrastructure (OCI)

Oracle Cloud menyediakan program **Always Free Tier** yang memberikan:
* **2 VM Compute AMD/ARM** gratis selamanya.
* **10 GB Object Storage** + **10 GB Archive Storage** gratis selamanya tanpa biaya bulanan.

Ada dua pendekatan arsitektur Solusi C yang bisa Anda pilih:

---

### Pendekatan C.1: OCI Object Storage (Direct S3-Compatible / PAR)

#### 1. Persiapan di Oracle Cloud Console
1. Buka [Oracle Cloud Console](https://cloud.oracle.com/) &rarr; Menu **Storage** &rarr; **Buckets**.
2. Klik **Create Bucket**:
   * Bucket Name: `rideon-storage`
   * Default Storage Tier: `Standard`
   * Visibility: `Public` (atau gunakan Pre-Authenticated Requests / PAR agar lebih aman).
3. Buat **Customer Secret Keys** (S3 Credentials):
   * Buka **Profile** &rarr; **User Settings** &rarr; **Customer Secret Keys** &rarr; **Generate Secret Key**.
   * Simpan *Access Key* dan *Secret Key*.

#### 2. Endpoint Object Storage OCI
Format URL publik file di Oracle Cloud:
```text
https://objectstorage.{region}.oraclecloud.com/n/{namespace}/b/rideon-storage/o/profiles/{uid}.jpg
```

---

### Pendekatan C.2: Upload Melalui Backend RideOn (Express Node.js di Oracle VM)

Ini adalah cara paling sederhana karena RideOn sudah memiliki service backend (`services/wa-gateway`) yang bisa dipasang di VM Oracle Cloud gratis Anda.

#### 1. Tambahkan Endpoint Upload di `server.js` (`services/wa-gateway`)
```javascript
import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Konfigurasi direktori penyimpanan publik
const uploadDir = path.join(process.cwd(), 'public/uploads/profiles');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => {
        const uid = req.body.uid || 'user';
        cb(null, `profile_${uid}_${Date.now()}.jpg`);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 2 * 1024 * 1024 } // maks 2 MB
});

// Endpoint Upload Foto Profil
app.post('/api/upload/profile', upload.single('photo'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, error: 'File tidak ditemukan' });
    }
    
    // Ganti host dengan domain atau IP Oracle Cloud Anda
    const serverUrl = process.env.BASE_SERVER_URL || 'http://192.168.100.225:3000';
    const publicUrl = `${serverUrl}/uploads/profiles/${req.file.filename}`;
    
    return res.json({
        success: true,
        photoUrl: publicUrl
    });
});

// Sajikan file statis
app.use('/uploads', express.static(path.join(process.cwd(), 'public/uploads')));
```

---

### 3. Perubahan Kode di Flutter Customer App Saat Pindah ke Solusi C

Buka file [`pengaturan_akun_screen.dart`](file:///home/leon/Documents/Project/RideOn/apps/customer_app/lib/features/pengaturan/presentation/pages/pengaturan_akun_screen.dart) pada fungsi `_saveChanges()`:

Ganti blok Base64 dengan HTTP Multipart Upload:

```dart
// -------------------------------------------------------------
// SEBELUM (Solusi A - Base64):
// -------------------------------------------------------------
final imageBytes = await _pickedImageFile!.readAsBytes();
final base64String = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
updatedPhotoUrl = base64String;

// -------------------------------------------------------------
// SESUDAH (Solusi C - Upload ke Oracle Cloud / Backend Server):
// -------------------------------------------------------------
final uri = Uri.parse('https://api.rideon.id/api/upload/profile');
final request = http.MultipartRequest('POST', uri);
request.fields['uid'] = user.uid;
request.files.add(await http.MultipartFile.fromPath('photo', _pickedImageFile!.path));

final streamedResponse = await request.send();
final response = await http.Response.fromStream(streamedResponse);

if (response.statusCode == 200) {
  final resData = jsonDecode(response.body);
  updatedPhotoUrl = resData['photoUrl']; // Berupa URL https://...
}
```

> [!NOTE]
> Widget `UserAvatar` yang sudah kita buat **tidak perlu diubah sama sekali**, karena `UserAvatar` secara cerdas otomatis mendukung URL HTTPS (`Image.network`), Base64 (`Image.memory`), maupun file lokal (`Image.file`).

---

## 4. Skrip Migrasi Otomatis Data Lama (Opsional)
Jika di masa depan Anda ingin memindahkan user yang sudah terlanjur menyimpan Base64 di Firestore ke Oracle Cloud Object Storage, gunakan skrip Node.js sederhana:

```javascript
// scripts/migrate-photos-to-oci.js
import admin from 'firebase-admin';
import fs from 'fs';

// 1. Ambil semua user dari Firestore
const snapshot = await admin.firestore().collection('users').get();

for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.photoUrl && data.photoUrl.startsWith('data:image')) {
        // 2. Decode base64 menjadi buffer biner
        const base64Data = data.photoUrl.split(',')[1];
        const buffer = Buffer.from(base64Data, 'base64');
        
        // 3. Simpan ke storage Oracle Cloud
        const fileName = `profile_${doc.id}.jpg`;
        // uploadToOCI(buffer, fileName);
        
        // 4. Update Firestore dengan URL baru
        const newUrl = `https://storage.rideon.id/profiles/${fileName}`;
        await doc.ref.update({ photoUrl: newUrl });
        console.log(`Migrated user: ${doc.id}`);
    }
}
```

---
*Dokumen ini dibuat otomatis sebagai bagian dari arsitektur penyimpanan profil RideOn.*

