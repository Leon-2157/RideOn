import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/screens/radar/radar_screen.dart';
import 'package:driver_app/screens/account_settings/account_settings_screen.dart';
import 'package:driver_app/screens/activity/activity_list_screen.dart';
import 'package:driver_app/screens/wallet/wallet_screen.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:driver_app/services/location_service.dart';

class FakeDriverService extends DriverService {
  final List<Map<String, dynamic>> locationUpdates = [];
  final List<bool> presenceUpdates = [];

  @override
  Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
    required double heading,
    required bool isOnline,
    required String serviceType,
    String? driverId,
  }) async {
    locationUpdates.add({
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'isOnline': isOnline,
      'serviceType': serviceType,
    });
  }

  @override
  Future<void> setDriverPresence(bool isOnline, {String? driverId}) async {
    presenceUpdates.add(isOnline);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Halaman Radar FlexRide Driver Tests (Figma Spesifikasi)', () {
    testWidgets(
        'RadarScreen renders header, map, busy area, searching card, and bottom navbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            driverName: 'Joni utama',
            plateNumber: 'BK 4892 ABC',
          ),
        ),
      );

      // Verifikasi Header Profil Driver & GPS SIAP
      expect(find.text('Joni utama'), findsOneWidget);
      expect(find.text('BK 4892 ABC'), findsOneWidget);
      expect(find.text('GPS SIAP'), findsOneWidget);

      // Verifikasi Status Switch Awal Online
      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Geser tombol untuk off'), findsOneWidget);

      // Verifikasi Hotspot Area Sibuk
      expect(find.text('Area sibuk'), findsOneWidget);

      // Verifikasi Card Searching Floating Pill
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Verifikasi Bottom Navbar (4 Tabs)
      expect(find.text('Radar'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Dompet'), findsOneWidget);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('Toggling switch changes driver status between Online and Offline',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      expect(find.text('Status: Online'), findsOneWidget);

      // Toggle switch ke Offline (Pindah ke Dasboard Driver 1 sesuai Figma)
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: OFFLINE (Istirahat)'), findsOneWidget);
      expect(find.text('Geser tombol untuk mulai cari order'), findsOneWidget);
      expect(find.text('PROTEKSI TALANGAN'), findsOneWidget);
      expect(find.text('Modal Kas Belanja Hari Ini'), findsOneWidget);
      expect(find.text('Pendapatan Bersih Hari Ini'), findsOneWidget);
      expect(find.text('Buka radar maps sekarang'), findsNothing);

      // Toggle switch kembali ke Online pada Dashboard
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Geser tombol untuk off'), findsOneWidget);
      expect(find.text('Buka radar maps sekarang'), findsOneWidget);

      // Buka radar maps
      await tester.tap(find.text('Buka radar maps sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets(
        'Tapping Driver Profile Pill navigates to AccountSettingsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      // Tap profile pill
      await tester.tap(find.text('Joni utama'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountSettingsScreen), findsOneWidget);
      expect(find.text('Pengaturan Akun'), findsOneWidget);
    });

    testWidgets(
        'Simulated Incoming Order shows full details, countdown, and swipe actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
          ),
        ),
      );

      // Verifikasi komponen orderan masuk sesuai Figma orderan penumpang.png
      expect(find.text('ANTAR PENUMPANG'), findsOneWidget);
      expect(find.text('16 Detik'), findsOneWidget);
      expect(find.text('M.Topik'), findsOneWidget);
      expect(find.text('Ongkir: Rp 35.000'), findsOneWidget);
      expect(find.textContaining('Titik jemput : Jl.Seulawah no 10 PIM'), findsOneWidget);
      expect(find.textContaining('Tujuan: Suzuya Mall Lhokseumawe'), findsOneWidget);
      expect(find.text('Klik Maps'), findsNWidgets(2));
      expect(
        find.text('Jarak Jemput: 2.9km Jarak Antar: 18 km Estimasi: 25 mnt'),
        findsOneWidget,
      );

      // Verifikasi tombol geser aksi terima & tolak
      expect(find.text('Geser untuk menerima orderan ->'), findsOneWidget);
      expect(find.text('<- Geser untuk menolak orderan'), findsOneWidget);

      // Tap terima orderan
      await tester.tap(find.text('Geser untuk menerima orderan ->'));
      await tester.pumpAndSettle();

      // State berpindah ke Accepted (Figma radar driver-1.png & radar driver-2.png)
      expect(
        find.text('Pastikan penumpang sudah memakai helm standar sebelum melaju.'),
        findsOneWidget,
      );
      expect(find.text('Masuk kehalaman chat'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Tap tombol Selesai untuk memunculkan dialog penyelesaian (Figma iPhone 14 & 15 Pro - 21.png)
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Selesaikan Orderan'), findsOneWidget);
      expect(find.text('#I2E4S67'), findsOneWidget);
      expect(find.text('5 Okt 2026 13:02 WIB'), findsOneWidget);
      expect(find.text('Rp 183.000'), findsOneWidget);

      // Tekan tombol Selesai di dialog untuk kembali ke mode radar searching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Selesai').last);
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets(
        'Tapping Klik Maps opens maps for pickup and destination addresses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<String> openedMaps = [];

      await tester.pumpWidget(
        MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
            onOpenMaps: (address) async {
              openedMaps.add(address);
            },
          ),
        ),
      );

      // Verifikasi Ongkir tampil penuh tanpa terpotong di layar 360px
      expect(find.text('Ongkir: Rp 35.000'), findsOneWidget);

      // Tap tombol Klik Maps titik jemput
      await tester.tap(find.byKey(const Key('btn_maps_pickup')));
      await tester.pumpAndSettle();
      expect(openedMaps, contains('Jl.Seulawah no 10 PIM'));

      // Tap tombol Klik Maps tujuan
      await tester.tap(find.byKey(const Key('btn_maps_destination')));
      await tester.pumpAndSettle();
      expect(openedMaps, contains('Suzuya Mall Lhokseumawe'));
    });

    testWidgets('Tapping Reject order returns to searching state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
          ),
        ),
      );

      expect(find.text('<- Geser untuk menolak orderan'), findsOneWidget);

      await tester.tap(find.text('<- Geser untuk menolak orderan'));
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets('Dragging/swiping accept slider rightwards accepts the order',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
          ),
        ),
      );

      final acceptFinder = find.text('Geser untuk menerima orderan ->');
      expect(acceptFinder, findsOneWidget);

      // Drag partially (50px to the right) - should spring back and stay incoming
      await tester.drag(acceptFinder, const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(acceptFinder, findsOneWidget);

      // Drag past threshold (> 220px to the right)
      await tester.drag(acceptFinder, const Offset(250, 0));
      await tester.pumpAndSettle();

      // State moves to accepted
      expect(
        find.text('Pastikan penumpang sudah memakai helm standar sebelum melaju.'),
        findsOneWidget,
      );
    });

    testWidgets('Dragging/swiping reject slider leftwards rejects the order',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
          ),
        ),
      );

      final rejectFinder = find.text('<- Geser untuk menolak orderan');
      expect(rejectFinder, findsOneWidget);

      // Drag past threshold to the left (-250px)
      await tester.drag(rejectFinder, const Offset(-250, 0));
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets('Bottom navbar navigates to Activity and Wallet screens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      // Tap Aktivitas
      await tester.tap(find.text('Aktivitas'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityListScreen), findsOneWidget);
      expect(find.text('Pesanan Makanan'), findsOneWidget);

      // Tap Dompet
      await tester.tap(find.text('Dompet'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletScreen), findsOneWidget);
      expect(find.text('Dompet Driver'), findsOneWidget);

      // Tap Radar untuk kembali ke RadarScreen
      await tester.tap(find.text('Radar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RadarScreen), findsOneWidget);
      expect(find.text('GPS SIAP'), findsOneWidget);
    });

    testWidgets(
        'GPS Realtime presence and location updates stream when Online, and stop when Offline',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeDriverService = FakeDriverService();
      final locationService = LocationService();
      final streamController = StreamController<Position>.broadcast();
      locationService.positionStreamOverride = streamController.stream;

      await tester.pumpWidget(
        MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            enableGpsTracking: true,
            driverService: fakeDriverService,
            locationService: locationService,
          ),
        ),
      );

      // Verifikasi presence awal online terkirim
      expect(fakeDriverService.presenceUpdates, contains(true));
      expect(locationService.isTracking, isTrue);

      // Kirim event posisi baru dari GPS
      final mockPos = Position(
        latitude: 5.1804,
        longitude: 97.1408,
        timestamp: DateTime.now(),
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        accuracy: 4.0,
        heading: 45.0,
        headingAccuracy: 1.0,
        speed: 25.0,
        speedAccuracy: 1.0,
      );

      streamController.add(mockPos);
      await tester.pump();

      // Verifikasi posisi GPS terkirim ke updateDriverLocation
      expect(fakeDriverService.locationUpdates.isNotEmpty, isTrue);
      expect(
        fakeDriverService.locationUpdates.last['latitude'],
        equals(5.1804),
      );
      expect(
        fakeDriverService.locationUpdates.last['longitude'],
        equals(97.1408),
      );
      expect(fakeDriverService.locationUpdates.last['isOnline'], isTrue);

      // Matikan toggle ke Offline
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verifikasi tracking berhenti dan presence offline terkirim
      expect(locationService.isTracking, isFalse);
      expect(fakeDriverService.presenceUpdates.last, isFalse);

      await streamController.close();
      locationService.dispose();
    });

    testWidgets(
        'Pesan Makanan (FlexFood) Incoming Sheet renders matching Figma pemesanan makanan.png and uses tap buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<String> openedMaps = [];

      await tester.pumpWidget(
        MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
            initialOrderIndex: 1, // Pesan Makanan (FlexFood)
            onOpenMaps: (address) async {
              openedMaps.add(address);
            },
          ),
        ),
      );

      // Verifikasi komponen orderan Pesan Makanan
      expect(find.text('ORDERAN BARU MASUK!'), findsOneWidget);
      expect(find.text('PESAN MAKANAN'), findsOneWidget);
      expect(find.text('16 Detik'), findsOneWidget);
      expect(find.text('Pendapatan Bersih'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Non-Tunai (E-Wallet)'), findsOneWidget);
      expect(find.text('Waroeng Bamboe'), findsOneWidget);
      expect(find.text('Jl. Dumai, ARUN No. 101 (Fikri)'), findsOneWidget);
      expect(find.text('Total Jarak Tempuh: 4.2 km Estimasi: 10 menit'), findsOneWidget);

      // Verifikasi tombol Klik Maps
      await tester.tap(find.byKey(const Key('btn_maps_food_resto')));
      await tester.pumpAndSettle();
      expect(openedMaps, contains('Waroeng Bamboe, Jl. Merdeka'));

      // Verifikasi BUKAN slider swipe, melainkan dua tombol tap: SKIP>> & Terima Order Belanja
      expect(find.byKey(const Key('btn_skip_food')), findsOneWidget);
      expect(find.text('SKIP>>'), findsOneWidget);
      expect(find.byKey(const Key('btn_accept_food')), findsOneWidget);
      expect(find.text('Terima Order Belanja'), findsOneWidget);

      // Tap SKIP>> menolak orderan dan kembali mencari
      await tester.tap(find.byKey(const Key('btn_skip_food')));
      await tester.pumpAndSettle();
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets(
        'Titip Belanja (FlexSend) Incoming Sheet renders matching Figma Orderan masuk.png and uses tap buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<String> openedMaps = [];

      await tester.pumpWidget(
        MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.incoming,
            initialOrderIndex: 2, // Titip Belanja (FlexSend)
            onOpenMaps: (address) async {
              openedMaps.add(address);
            },
          ),
        ),
      );

      // Verifikasi komponen orderan Titip Belanja
      expect(find.text('ORDERAN BARU MASUK!'), findsOneWidget);
      expect(find.text('TITIP BELANJA'), findsOneWidget);
      expect(find.text('18 Detik'), findsOneWidget);
      expect(find.text('Pendapatan Bersih'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Ongkir rute + kuota item'), findsOneWidget);
      expect(find.text('Estimasi Talangan'), findsOneWidget);
      expect(find.text('Rp 180.000'), findsOneWidget);
      expect(find.text('Sesuai modal kas driver'), findsOneWidget);
      expect(find.text('Pajak batuphat (4 Item)'), findsOneWidget);
      expect(find.text('Apotek Kimia Farma (1 Item)'), findsOneWidget);
      expect(find.text('Jl. Lauser, PIM No. 88 (Gufran)'), findsOneWidget);
      expect(find.text('Total Jarak Tempuh: 4.2 km Estimasi: 10 menit'), findsOneWidget);

      // Verifikasi tombol Klik Maps titik belanja
      await tester.tap(find.byKey(const Key('btn_maps_send_stop1')));
      await tester.pumpAndSettle();
      expect(openedMaps, contains('Pajak batuphat'));

      // Verifikasi BUKAN slider swipe, melainkan dua tombol tap: SKIP>> & Terima Order Belanja
      expect(find.byKey(const Key('btn_skip_send')), findsOneWidget);
      expect(find.text('SKIP>>'), findsOneWidget);
      expect(find.byKey(const Key('btn_accept_send')), findsOneWidget);
      expect(find.text('Terima Order Belanja'), findsOneWidget);

      // Tap SKIP>> menolak orderan dan kembali mencari
      await tester.tap(find.byKey(const Key('btn_skip_send')));
      await tester.pumpAndSettle();
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets(
        'Tapping searching pill rotates orders in sequence: FlexRide -> FlexFood -> FlexSend -> FlexRide',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
            initialOrderState: RadarOrderState.searching,
            initialOrderIndex: 0,
          ),
        ),
      );

      // Awal: Mode Searching
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Simulasi Order 1: FlexRide (Antar Penumpang)
      await tester.tap(find.text('Mencari orderan terbaik...'));
      await tester.pumpAndSettle();
      expect(find.text('ANTAR PENUMPANG'), findsOneWidget);
      expect(find.text('M.Topik'), findsOneWidget);

      // Tolak order FlexRide
      await tester.tap(find.text('<- Geser untuk menolak orderan'));
      await tester.pumpAndSettle();
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Simulasi Order 2: FlexFood (Pesan Makanan)
      await tester.tap(find.text('Mencari orderan terbaik...'));
      await tester.pumpAndSettle();
      expect(find.text('PESAN MAKANAN'), findsOneWidget);
      expect(find.text('Waroeng Bamboe'), findsOneWidget);

      // Tolak order FlexFood via SKIP>>
      await tester.tap(find.byKey(const Key('btn_skip_food')));
      await tester.pumpAndSettle();
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Simulasi Order 3: FlexSend (Titip Belanja)
      await tester.tap(find.text('Mencari orderan terbaik...'));
      await tester.pumpAndSettle();
      expect(find.text('TITIP BELANJA'), findsOneWidget);
      expect(find.text('Pajak batuphat (4 Item)'), findsOneWidget);

      // Tolak order FlexSend via SKIP>>
      await tester.tap(find.byKey(const Key('btn_skip_send')));
      await tester.pumpAndSettle();
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Siklus berulang kembali ke Order 1: FlexRide (Antar Penumpang)
      await tester.tap(find.text('Mencari orderan terbaik...'));
      await tester.pumpAndSettle();
      expect(find.text('ANTAR PENUMPANG'), findsOneWidget);
      expect(find.text('M.Topik'), findsOneWidget);
    });

    testWidgets(
        'Searching card floats above bottom navbar without overlap on devices with bottom safe area',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      final searchingCardBottom =
          tester.getBottomLeft(find.text('Mencari orderan terbaik...')).dy;
      final navbarRadarTop = tester.getTopLeft(find.text('Radar')).dy;

      // Card searching harus berada di atas navbar dan tidak tertutup / kepentok
      expect(searchingCardBottom, lessThan(navbarRadarTop));
    });
  });
}
