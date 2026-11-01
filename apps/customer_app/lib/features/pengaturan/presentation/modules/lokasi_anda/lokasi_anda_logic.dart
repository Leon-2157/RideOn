import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Business logic for Lokasi Anda GPS & Saved Places
class LokasiAndaLogic {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  LokasiAndaLogic({
    this.auth,
    this.firestore,
  });

  FirebaseAuth get resolvedAuth => auth ?? FirebaseAuth.instance;
  FirebaseFirestore get resolvedFirestore => firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loadSavedLocation() async {
    try {
      final user = resolvedAuth.currentUser;
      if (user == null) return null;

      final doc = await resolvedFirestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      return data?['savedAddress'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Layanan GPS belum aktif. Silakan aktifkan lokasi perangkat Anda.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin akses lokasi ditolak oleh pengguna.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Izin akses lokasi diblokir permanen. Aktifkan lewat Pengaturan Aplikasi.';
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final geocoding = Geocoding();
      List<Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final List<String> addressParts = [];

        if (p.street != null &&
            p.street!.isNotEmpty &&
            !p.street!.contains('+')) {
          addressParts.add(p.street!);
        } else if (p.name != null && p.name!.isNotEmpty) {
          addressParts.add(p.name!);
        }

        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          addressParts.add(p.subLocality!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          addressParts.add(p.locality!);
        }
        if (p.subAdministrativeArea != null &&
            p.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(p.subAdministrativeArea!);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveLocation({
    required LatLng position,
    required String address,
    required String label,
    required String note,
  }) async {
    final user = resolvedAuth.currentUser;
    if (user != null) {
      await resolvedFirestore.collection('users').doc(user.uid).set({
        'savedAddress': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
          'label': label,
          'note': note,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }
  }
}
