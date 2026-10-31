import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/sub_header_widget.dart';
import 'atur_posisi_foto_screen.dart';
import '../modules/ubah_profil/pilih_foto_bottom_sheet.dart';
import '../modules/ubah_profil/ubah_profil_form_card.dart';

export '../modules/ubah_profil/pilih_foto_bottom_sheet.dart';
export '../modules/ubah_profil/ubah_profil_form_card.dart';

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

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (_pickedImageFile != null) {
        try {
          final bytes = await _pickedImageFile!.readAsBytes();
          final base64String = base64Encode(bytes);
          final dataUri = 'data:image/jpeg;base64,$base64String';

          final appDir = await getApplicationDocumentsDirectory();
          final localSavedImage =
              File('${appDir.path}/profile_avatar_${user?.uid ?? "local"}.jpg');
          await localSavedImage.writeAsBytes(bytes);

          updatedPhotoUrl = dataUri;
        } catch (_) {
          updatedPhotoUrl = _pickedImageFile!.path;
        }
      }

      if (user != null) {
        if (newName != user.displayName || updatedPhotoUrl != user.photoURL) {
          await user.updateDisplayName(newName);
          if (updatedPhotoUrl != null && updatedPhotoUrl.length < 2000) {
            await user.updatePhotoURL(updatedPhotoUrl);
          }
        }

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
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Color(0xFF6B48FC),
        ),
      );

      Navigator.of(context).pop({
        'name': newName,
        'photoUrl': updatedPhotoUrl,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showPilihFotoSheet() {
    PilihFotoBottomSheet.show(
      context,
      onPickCamera: () => _pickImage(ImageSource.camera),
      onPickGallery: () => _pickImage(ImageSource.gallery),
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
              child: UbahProfilFormCard(
                photoUrl: _currentPhotoUrl,
                pickedImageFile: _pickedImageFile,
                nameController: _nameController,
                fallbackName: widget.currentName,
                isSaving: _isSaving,
                onTapCamera: _showPilihFotoSheet,
                onSave: _saveChanges,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
