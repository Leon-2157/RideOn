import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/services/location_service.dart';

void main() {
  group('LocationService Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    tearDown(() {
      locationService.dispose();
    });

    test('Initial state isTracking is false', () {
      expect(locationService.isTracking, isFalse);
    });

    test('startLocationUpdates with positionStreamOverride streams locations',
        () async {
      final controller = StreamController<Position>();
      locationService.positionStreamOverride = controller.stream;

      final receivedPositions = <Position>[];

      locationService.startLocationUpdates(
        onLocationChanged: (pos) {
          receivedPositions.add(pos);
        },
      );

      expect(locationService.isTracking, isTrue);

      final mockPos1 = Position(
        latitude: 5.1801,
        longitude: 97.1405,
        timestamp: DateTime.now(),
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        accuracy: 5.0,
        heading: 90.0,
        headingAccuracy: 0.0,
        speed: 10.0,
        speedAccuracy: 0.0,
      );

      controller.add(mockPos1);
      await pumpEventQueue();

      expect(receivedPositions.length, equals(1));
      expect(receivedPositions.first.latitude, equals(5.1801));
      expect(receivedPositions.first.longitude, equals(97.1405));

      locationService.stopLocationUpdates();
      expect(locationService.isTracking, isFalse);

      await controller.close();
    });

    test('stopLocationUpdates stops receiving events and resets isTracking',
        () async {
      final controller = StreamController<Position>.broadcast();
      locationService.positionStreamOverride = controller.stream;

      int count = 0;
      locationService.startLocationUpdates(
        onLocationChanged: (_) => count++,
      );

      final mockPos = Position(
        latitude: 5.0,
        longitude: 97.0,
        timestamp: DateTime.now(),
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        accuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      controller.add(mockPos);
      await pumpEventQueue();
      expect(count, equals(1));

      locationService.stopLocationUpdates();
      expect(locationService.isTracking, isFalse);

      controller.add(mockPos);
      await pumpEventQueue();
      expect(count, equals(1)); // Should not increment

      await controller.close();
    });
  });
}
