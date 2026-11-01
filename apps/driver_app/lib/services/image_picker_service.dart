import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// [ImagePickerService]
/// Layanan terpusat untuk penangkapan foto (Kamera) dan pemilihan foto (Galeri)
/// menggunakan paket resmi `image_picker`.
class ImagePickerService {
  final ImagePicker _picker;

  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Mengambil foto langsung dari Kamera perangkat
  Future<XFile?> pickImageFromCamera({
    double maxWidth = 1920,
    double maxHeight = 1920,
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );
    } catch (e) {
      debugPrint('Error ImagePickerService.pickImageFromCamera: $e');
      return null;
    }
  }

  /// Memilih foto dari Galeri / Penyimpanan perangkat
  Future<XFile?> pickImageFromGallery({
    double maxWidth = 1920,
    double maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } catch (e) {
      debugPrint('Error ImagePickerService.pickImageFromGallery: $e');
      return null;
    }
  }

  /// Membaca bytes file gambar untuk tampilan cross-platform aman (Image.memory)
  Future<Uint8List?> readBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error ImagePickerService.readBytes: $e');
      return null;
    }
  }
}
