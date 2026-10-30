import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../widgets/sub_header_widget.dart';
import 'atur_posisi_foto_screen.dart';

class UbahProfilScreen extends StatefulWidget {
  final String currentName;
  final String? currentPhotoUrl;

  const UbahProfilScreen({
    super.key,
    required this.currentName,
    this.currentPhotoUrl,
  });

  @override
  State<UbahProfilScreen> createState() => _UbahProfilScreenState();
}

class _UbahProfilScreenState extends State<UbahProfilScreen> {
  late TextEditingController _nameController;
  File? _pickedImageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _currentPhotoUrl = widget.currentPhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (picked != null && mounted) {
        // Buka Layar Atur Posisi Foto (Figma node [1:8904] edit pp)
        final croppedFile = await Navigator.of(context).push<File>(
          MaterialPageRoute(
            builder: (context) => AturPosisiFotoScreen(
              imageFile: File(picked.path),
            ),
          ),
        );

        if (croppedFile != null && mounted) {
          setState(() {
            _pickedImageFile = croppedFile;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final newName = _nameController.text.trim();
    if (newName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap minimal 3 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? updatedPhotoUrl = _currentPhotoUrl;
    String? photoSizeKb;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Upload atau simpan foto jika ada foto baru yang dipilih
        if (_pickedImageFile != null) {
          // Solusi A (Tahap Development): Kompresi & Simpan Base64 di Cloud Firestore (100% Gratis & Cloud Sync)
          final imageBytes = await _pickedImageFile!.readAsBytes();
          final kb = imageBytes.lengthInBytes / 1024;
          photoSizeKb = '${kb.toStringAsFixed(1)} KB';
          final base64String = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
          updatedPhotoUrl = base64String;

          debugPrint('📸 [RideOn] Foto profil dikompresi: $photoSizeKb (Resolusi maks 512x512)');
          debugPrint('☁️ [RideOn] Menyimpan ke Cloud Firestore /users/${user.uid} field photoUrl...');

          // Simpan juga salinan file lokal sebagai cache offline instan di perangkat
          try {
            final appDir = await getApplicationDocumentsDirectory();
            await _pickedImageFile!.copy('${appDir.path}/profile_${user.uid}.jpg');
          } catch (_) {}
        }

        // 2. Update display name jika berubah
        if (newName != user.displayName) {
          await user.updateDisplayName(newName);
        }

        // 3. Simpan ke Firestore
        final Map<String, dynamic> updateData = {
          'name': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (updatedPhotoUrl != null) {
          updateData['photoUrl'] = updatedPhotoUrl;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        debugPrint('✅ [RideOn] Berhasil tersimpan ke Cloud Firestore /users/${user.uid}');
      }

      if (!mounted) return;
      final successMsg = photoSizeKb != null
          ? 'Profil tersimpan di Firebase! (Foto dikompresi: $photoSizeKb)'
          : 'Perubahan profil berhasil disimpan di Firebase!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: const Color(0xFF6B48FC),
        ),
      );

      Navigator.of(context).pop({
        'name': newName,
        'photoUrl': updatedPhotoUrl,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPilihFotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1832),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pilih Foto Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFotoSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Dari Kamera',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _buildFotoSourceOption(
                icon: Icons.image_rounded,
                title: 'Pilih Dari Galeri',
                subtitle: 'Pilih Foto Dari Perangkat',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1832),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'BATAL',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFotoSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6B48FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF1B1832)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildSubHeader(context, 'Ubah Profil'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7BCFE),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Camera Badge
                    Center(
                      child: Stack(
                        children: [
                          UserAvatar(
                            photoUrl: _currentPhotoUrl,
                            localImageFile: _pickedImageFile,
                            name: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : widget.currentName,
                            size: 110,
                            borderWidth: 3,
                            borderColor: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _isSaving ? null : _showPilihFotoSheet,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1832),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama Lengkap Label
                    Text(
                      'Nama Lengkap',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCD7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SIMPAN PERUBAHAN Button
                    GestureDetector(
                      onTap: _isSaving ? null : _saveChanges,
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.save_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SIMPAN PERUBAHAN',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

