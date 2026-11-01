import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service untuk menangani izin lokasi perangkat dan streaming GPS Realtime
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  Stream<Position>? positionStreamOverride;

  /// Cek ketersediaan GPS Service dan Request Permission Runtime
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS Service tidak aktif.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Izin lokasi ditolak.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '[LocationService] Izin lokasi ditolak permanen (perlu buka pengaturan).');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('[LocationService] Gagal memeriksa izin lokasi: $e');
      return false;
    }
  }

  /// Dapatkan posisi GPS saat ini (Single fetch)
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] Gagal mendapatkan posisi: $e');
      return null;
    }
  }

  /// Mulai streaming koordinat GPS berkala untuk Radar & Realtime Tracking
  StreamSubscription<Position>? startLocationUpdates({
    required void Function(Position position) onLocationChanged,
    int distanceFilter = 5,
    int intervalSeconds = 5,
    void Function(dynamic error)? onError,
  }) {
    stopLocationUpdates();

    if (positionStreamOverride != null) {
      _positionSubscription = positionStreamOverride!.listen(
        onLocationChanged,
        onError: onError,
      );
      return _positionSubscription;
    }

    try {
      final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          forceLocationManager: false,
          intervalDuration: Duration(seconds: intervalSeconds),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: 'RideOn Driver sedang memantau lokasi GPS Anda',
            notificationTitle: 'Layanan Tracking Aktif',
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: distanceFilter,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          onLocationChanged(position);
        },
        onError: (e) {
          debugPrint('[LocationService] Error pada position stream: $e');
          if (onError != null) onError(e);
        },
      );
    } catch (e) {
      debugPrint('[LocationService] Gagal mengaktifkan stream lokasi: $e');
      if (onError != null) onError(e);
    }

    return _positionSubscription;
  }

  /// Hentikan streaming lokasi
  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  bool get isTracking => _positionSubscription != null;

  void dispose() {
    stopLocationUpdates();
  }
}
