import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/core/services/osm_nominatim_service.dart';
import 'package:rideon/features/flexfood/data/flexfood_catalog.dart';
import 'package:rideon/features/flexfood/presentation/modules/food_grid/food_grid_view.dart';
import 'package:rideon/features/flexride/presentation/modules/location_picker/location_picker_module.dart';
import 'package:rideon/features/flexride/presentation/pages/flexride_screen.dart';
import 'package:rideon/features/flexsend/presentation/modules/form/place_picker_bottom_sheet.dart';
import 'package:rideon/features/home/presentation/modules/header_banner/header_banner_view.dart';
import 'package:rideon/features/home/presentation/pages/global_search_screen.dart';

void main() {
  final sampleNominatimResponse = jsonEncode([
    {
      'place_id': 1001,
      'name': 'Masjid Agung Islamic Center',
      'display_name':
          'Masjid Agung Islamic Center, Jalan Merdeka, Simpang Empat, Banda Sakti, Lhokseumawe, Aceh, Indonesia',
      'lat': '5.1801',
      'lon': '97.1432',
      'type': 'place_of_worship',
      'address': {
        'amenity': 'Masjid Agung Islamic Center',
        'road': 'Jalan Merdeka',
        'suburb': 'Simpang Empat',
        'city_district': 'Banda Sakti',
        'city': 'Lhokseumawe',
        'state': 'Aceh',
      },
    },
    {
      'place_id': 1002,
      'name': 'Kampus Unimal Bukit Indah',
      'display_name':
          'Kampus Unimal Bukit Indah, Blang Pulo, Muara Satu, Lhokseumawe, Aceh, Indonesia',
      'lat': '5.2015',
      'lon': '97.0642',
      'type': 'university',
      'address': {
        'amenity': 'Kampus Unimal Bukit Indah',
        'village': 'Blang Pulo',
        'city_district': 'Muara Satu',
        'city': 'Lhokseumawe',
      },
    },
  ]);

  group('OsmNominatimService Unit Tests', () {
    test('parses results, passes Indonesia params, computes distance, and caches repeat queries', () async {
      int callCount = 0;
      Uri? lastUri;

      final service = OsmNominatimService(
        httpGetOverride: (uri) async {
          callCount++;
          lastUri = uri;
          return sampleNominatimResponse;
        },
      );

      final first = await service.searchPlaces(
        'masjid',
        nearLat: 5.2472,
        nearLng: 97.0261,
      );

      expect(callCount, 1);
      expect(lastUri?.queryParameters['countrycodes'], 'id');
      expect(lastUri?.queryParameters['format'], 'jsonv2');
      expect(lastUri?.queryParameters['q'], 'masjid');
      expect(first.length, 2);
      expect(first.first.title, 'Masjid Agung Islamic Center');
      expect(first.first.distanceKm, isNotNull);
      expect(first.first.distanceKm!, greaterThan(5.0));

      // Repeat same query -> should hit cache without another HTTP call
      final second = await service.searchPlaces(
        'Masjid',
        nearLat: 5.2472,
        nearLng: 97.0261,
      );
      expect(callCount, 1);
      expect(second.length, 2);
    });

    test('returns empty list safely on network error or short query', () async {
      final service = OsmNominatimService(
        httpGetOverride: (_) async => throw Exception('offline'),
      );

      expect(await service.searchPlaces('a'), isEmpty);
      expect(await service.searchPlaces('jakarta'), isEmpty);
    });
  });

  group('Beranda HomeSearchBar & GlobalSearchScreen Tests', () {
    testWidgets('Tapping HomeSearchBar opens GlobalSearchScreen cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => HeaderBannerView(
                onSearchTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GlobalSearchScreen(autofocus: false),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('home_search_bar')));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchScreen), findsOneWidget);
      expect(find.text('Pencarian Populer'), findsOneWidget);
    });

    testWidgets(
      'GlobalSearchScreen searches Layanan, Makanan, Restoran, Promo, Wisata, OSM Nominatim and routes Destination to FlexRide',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockNominatim = OsmNominatimService(
          httpGetOverride: (_) async => sampleNominatimResponse,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: GlobalSearchScreen(
              nominatimService: mockNominatim,
              autofocus: false,
            ),
          ),
        );

        final searchField = find.byKey(const Key('input_global_search'));

        // 1. Cari sinonim layanan ("ojek" -> FlexRide)
        await tester.enterText(searchField, 'ojek');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();
        expect(find.text('FlexRide'), findsOneWidget);

        // 2. Cari makanan ("pempek")
        await tester.enterText(searchField, 'pempek');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();
        expect(find.text('Pempek Palembang'), findsOneWidget);

        // 3. Cari promo ("diskon")
        await tester.enterText(searchField, 'diskon');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();
        expect(find.text('Diskon FlexFood s/d 50%'), findsOneWidget);

        // 4. Cari lokasi Nominatim ("masjid") & klik -> buka FlexRideScreen dengan tujuan terisi
        await tester.enterText(searchField, 'masjid');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pumpAndSettle();

        expect(find.text('Masjid Agung Islamic Center'), findsOneWidget);
        await tester.tap(find.text('Masjid Agung Islamic Center'));
        await tester.pumpAndSettle();

        expect(find.byType(FlexRideScreen), findsOneWidget);
        final destField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Ketik tujuan perjalananmu...'),
        );
        expect(
          destField.controller?.text,
          contains('Masjid Agung Islamic Center'),
        );
      },
    );
  });

  group('FlexFood Catalog & FoodGridView Live Search Tests', () {
    test('FlexFoodCatalog filters foods and restaurants by query and category', () {
      final allFoods = FlexFoodCatalog.createAllFoodItems();
      final pempek = FlexFoodCatalog.filterFoods(allFoods, query: 'pempek');
      expect(pempek.length, 1);
      expect(pempek.first['title'], 'Pempek Palembang');

      final baksoMie = FlexFoodCatalog.filterFoods(allFoods, category: 'Bakso & Mie');
      expect(baksoMie.length, 3);
      expect(
        baksoMie.every((e) => e['category'] == 'Bakso & Mie'),
        isTrue,
      );

      final terdekat = FlexFoodCatalog.filterRestaurants(
        FlexFoodCatalog.popularRestaurants,
        category: 'Terdekat',
      );
      expect(terdekat.isNotEmpty, isTrue);
      expect(terdekat.first['distance'], '0.8 km');
    });

    testWidgets('FoodGridView Restoran tab filters live and handles empty search reset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: FoodGridView(
            initialTabIndex: 2,
            onSelectFood: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warung Padang Si Ujang'), findsOneWidget);
      expect(find.text('Banku City Resto & Cafe'), findsOneWidget);

      // Test kategori filter Restoran ('Terdekat' -> <= 1.5 km: hanya Banku City & Bakso Urat Pak De)
      await tester.tap(find.byKey(const Key('food_cat_Terdekat')));
      await tester.pumpAndSettle();
      expect(find.text('Banku City Resto & Cafe'), findsOneWidget);
      expect(find.text('Warung Padang Si Ujang'), findsNothing);

      // Kembalikan ke 'Semua Resto' lalu uji live search text
      await tester.tap(find.byKey(const Key('food_cat_Semua Resto')));
      await tester.pumpAndSettle();

      final searchField =
          find.widgetWithText(TextField, 'Mau makan apa hari ini?...');
      await tester.enterText(searchField, 'padang');
      await tester.pumpAndSettle();

      expect(find.text('Warung Padang Si Ujang'), findsOneWidget);
      expect(find.text('Banku City Resto & Cafe'), findsNothing);

      // Query yang tidak ada -> empty state + reset
      await tester.enterText(searchField, 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.text('Menu atau restoran tidak ditemukan'), findsOneWidget);

      await tester.tap(find.text('Reset Pencarian & Filter'));
      await tester.pumpAndSettle();
      expect(find.text('Warung Padang Si Ujang'), findsOneWidget);
    });
  });

  group('FlexRide & FlexSend OpenStreetMap Nominatim Integration Tests', () {
    testWidgets('FlexRide LocationPickerModule queries Nominatim only when typing and fills field',
        (WidgetTester tester) async {
      final pickupCtrl = TextEditingController();
      final destCtrl = TextEditingController();
      final mockNominatim = OsmNominatimService(
        httpGetOverride: (_) async => sampleNominatimResponse,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LocationPickerModule(
                pickupController: pickupCtrl,
                destinationController: destCtrl,
                nominatimService: mockNominatim,
                onSelectSavedAddress: (_) {},
                onPickViaMap: () {},
                onProceedToVehicles: () {},
              ),
            ),
          ),
        ),
      );

      // Tap pickup field without typing -> keeps Riwayat Cepat (no fake popup list)
      final pickupField =
          find.widgetWithText(TextField, 'Ketik lokasi penjemputanmu...');
      await tester.tap(pickupField);
      await tester.pumpAndSettle();
      expect(find.text('Alamat Favorit & Riwayat Cepat'), findsOneWidget);

      // Ketik "kampus" -> panggil Nominatim & tampilkan hasil
      await tester.enterText(pickupField, 'kampus');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pumpAndSettle();

      expect(find.text('Kampus Unimal Bukit Indah'), findsOneWidget);
      await tester.tap(find.text('Kampus Unimal Bukit Indah'));
      await tester.pumpAndSettle();

      expect(pickupCtrl.text, contains('Kampus Unimal Bukit Indah'));
    });

    testWidgets('FlexSend PlacePickerBottomSheet shows local + Nominatim results and selects OSM place',
        (WidgetTester tester) async {
      String? chosenName;
      String? chosenAddress;
      final mockNominatim = OsmNominatimService(
        httpGetOverride: (_) async => sampleNominatimResponse,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlacePickerBottomSheet(
              locationIndex: 1,
              nominatimService: mockNominatim,
              onPlaceSelected: (name, addr) {
                chosenName = name;
                chosenAddress = addr;
              },
            ),
          ),
        ),
      );

      final searchField =
          find.widgetWithText(TextField, 'Ketik nama toko, pasar, jalan...');
      await tester.enterText(searchField, 'islamic');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pumpAndSettle();

      expect(find.text('Hasil Peta OpenStreetMap'), findsOneWidget);
      expect(find.text('Masjid Agung Islamic Center'), findsOneWidget);

      await tester.tap(find.text('Masjid Agung Islamic Center'));
      await tester.pumpAndSettle();

      expect(chosenName, 'Masjid Agung Islamic Center');
      expect(chosenAddress, contains('Masjid Agung Islamic Center'));
    });
  });
}
