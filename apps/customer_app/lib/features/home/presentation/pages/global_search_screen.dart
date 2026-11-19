import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideon/core/services/customer_api_service.dart';
import 'package:rideon/core/services/osm_nominatim_service.dart';
import 'package:rideon/features/flexfood/data/flexfood_catalog.dart';
import 'package:rideon/features/flexfood/presentation/pages/flexfood_screen.dart';
import 'package:rideon/features/flexride/presentation/pages/flexride_screen.dart';
import 'package:rideon/features/flexsend/presentation/pages/flexsend_screen.dart';
import 'package:rideon/features/home/presentation/modules/cek_promo/promo_item_model.dart';
import 'package:rideon/features/home/presentation/modules/cek_promo/promo_logic.dart';
import 'package:rideon/features/home/presentation/modules/rekomendasi_wisata/wisata_item_model.dart';
import 'package:rideon/features/home/presentation/modules/rekomendasi_wisata/wisata_section_logic.dart';
import 'package:rideon/features/home/presentation/modules/services_header/service_item_model.dart';
import 'package:rideon/features/home/presentation/modules/services_header/services_header_logic.dart';

/// Kategori filter hasil pencarian global di Beranda.
enum SearchFilterTab {
  semua('Semua'),
  makanan('Makanan'),
  restoran('Restoran'),
  tujuan('Tujuan'),
  layanan('Layanan'),
  promo('Promo');

  final String label;
  const SearchFilterTab(this.label);
}

/// Halaman Pencarian Global Customer App (`Cari makanan, tujuan, layanan...`).
///
/// Mencakup: Layanan, Makanan, Restoran, Tujuan/Wisata (termasuk OpenStreetMap
/// Nominatim & alamat tersimpan user), dan Promo.
class GlobalSearchScreen extends StatefulWidget {
  final OsmNominatimService? nominatimService;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final String initialQuery;
  final bool autofocus;

  const GlobalSearchScreen({
    super.key,
    this.nominatimService,
    this.auth,
    this.firestore,
    this.initialQuery = '',
    this.autofocus = true,
  });

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.initialQuery,
  );
  late final OsmNominatimService _nominatim =
      widget.nominatimService ?? OsmNominatimService.instance;

  SearchFilterTab _selectedTab = SearchFilterTab.semua;
  Timer? _debounceTimer;
  int _searchGeneration = 0;
  bool _isLoadingOsm = false;
  List<OsmPlaceResult> _osmResults = const [];
  List<Map<String, dynamic>> _savedAddresses = const [];
  LatLng? _userLatLng;

  List<Map<String, dynamic>> _allFoods = FlexFoodCatalog.createAllFoodItems();

  static const List<String> _popularKeywords = [
    'Bakso',
    'Nasi Goreng',
    'Kebab',
    'FlexRide',
    'Gratis Ongkir',
    'Rinjani',
    'Pasar',
    'Masjid',
  ];

  static const Map<String, List<String>> _serviceKeywords = {
    'flexride': [
      'flexride',
      'ride',
      'ojek',
      'motor',
      'mobil',
      'antar',
      'jemput',
      'perjalanan',
      'transportasi',
    ],
    'flexfood': [
      'flexfood',
      'food',
      'makan',
      'makanan',
      'minuman',
      'resto',
      'restoran',
      'kuliner',
      'lapar',
    ],
    'flexsend': [
      'flexsend',
      'send',
      'titip',
      'belanja',
      'kirim',
      'paket',
      'kurir',
      'toko',
      'pasar',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadContextData();
    if (widget.initialQuery.trim().length >= 2) {
      _scheduleOsmSearch(widget.initialQuery.trim());
    }
  }

  Future<void> _loadContextData() async {
    if (CustomerApiService().hasSession) {
      try {
        final api = CustomerApiService();
        final menus = await api.getPublicMenus();
        if (mounted && menus.isNotEmpty) {
          final defaults = FlexFoodCatalog.createAllFoodItems();
          setState(() {
            _allFoods = [
              ...List.generate(menus.length, (i) {
                final m = menus[i];
                final formatted = m.price.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+$)'), (x) => '${x[1]}.');
                return {
                  'menuId': m.id,
                  'storeId': m.storeId,
                  'title': m.name,
                  'desc': m.description,
                  'price': 'Rp $formatted',
                  'priceInt': m.price,
                  'rating': m.ratingAvg.toStringAsFixed(1),
                  'image': m.photoUrl.isNotEmpty
                      ? api.resolveUrl(m.photoUrl)
                      : defaults[i % defaults.length]['image'],
                  'resto': m.storeName,
                  'distance': '1.2 km',
                  'fav': false,
                  'category': m.category,
                  'isTrending': i < 4,
                  'isPromo': true,
                };
              }),
            ];
          });
        }
      } catch (_) {}
    }

    final pos = await OsmNominatimService.tryGetKnownUserPosition();
    final saved = await OsmNominatimService.loadSavedAddresses(
      auth: widget.auth,
      firestore: widget.firestore,
    );
    if (!mounted) return;
    setState(() {
      if (pos != null) _userLatLng = pos;
      _savedAddresses = saved;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    setState(() {});
    _scheduleOsmSearch(raw.trim());
  }

  void _applyKeyword(String keyword) {
    _searchController.text = keyword;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _onQueryChanged(keyword);
  }

  void _scheduleOsmSearch(String query) {
    _debounceTimer?.cancel();
    final gen = ++_searchGeneration;

    if (query.length < 2) {
      setState(() {
        _isLoadingOsm = false;
        _osmResults = const [];
      });
      return;
    }

    setState(() {
      _isLoadingOsm = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      final results = await _nominatim.searchPlaces(
        query,
        nearLat: _userLatLng?.latitude,
        nearLng: _userLatLng?.longitude,
        limit: 8,
      );
      if (!mounted || gen != _searchGeneration) return;
      setState(() {
        _isLoadingOsm = false;
        _osmResults = results;
      });
    });
  }

  bool _matchesQuery(String text, String q) {
    if (q.isEmpty) return false;
    return text.toLowerCase().contains(q);
  }

  bool _isPrefixMatch(String text, String q) {
    final words = text.toLowerCase().split(RegExp(r'[\s,\.-]+'));
    return words.any((w) => w.startsWith(q));
  }

  List<ServiceItemModel> _searchServices(String q) {
    if (q.isEmpty) return const [];
    final matches = ServicesHeaderLogic.defaultServices.where((service) {
      final titleMatch = service.title.toLowerCase().contains(q);
      final aliases = _serviceKeywords[service.routeKey] ?? const [];
      final aliasMatch = aliases.any((k) => k.contains(q) || q.contains(k));
      return titleMatch || aliasMatch;
    }).toList();

    matches.sort((a, b) {
      final aPref = _isPrefixMatch(a.title, q) ? 0 : 1;
      final bPref = _isPrefixMatch(b.title, q) ? 0 : 1;
      return aPref.compareTo(bPref);
    });
    return matches;
  }

  List<Map<String, dynamic>> _searchFoods(String q) {
    final items = FlexFoodCatalog.filterFoods(_allFoods, query: q);
    items.sort((a, b) {
      final aPref = _isPrefixMatch(a['title'] as String? ?? '', q) ? 0 : 1;
      final bPref = _isPrefixMatch(b['title'] as String? ?? '', q) ? 0 : 1;
      return aPref.compareTo(bPref);
    });
    return items;
  }

  List<Map<String, dynamic>> _searchRestaurants(String q) {
    final restos = FlexFoodCatalog.filterRestaurants(
      FlexFoodCatalog.popularRestaurants,
      query: q,
    );
    restos.sort((a, b) {
      final aPref = _isPrefixMatch(a['name'] as String? ?? '', q) ? 0 : 1;
      final bPref = _isPrefixMatch(b['name'] as String? ?? '', q) ? 0 : 1;
      return aPref.compareTo(bPref);
    });
    return restos;
  }

  List<WisataItemModel> _searchWisata(String q) {
    if (q.isEmpty) return const [];
    return WisataSectionLogic.defaultWisata.where((w) {
      return _matchesQuery(w.title, q) ||
          _matchesQuery(w.description, q) ||
          'wisata'.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _searchSavedAddresses(String q) {
    if (q.isEmpty) return const [];
    return _savedAddresses.where((addr) {
      final label = addr['label'] as String? ?? '';
      final address = addr['address'] as String? ?? '';
      return _matchesQuery(label, q) || _matchesQuery(address, q);
    }).toList();
  }

  List<PromoItemModel> _searchPromos(String q) {
    if (q.isEmpty) return const [];
    final bool genericPromoQuery =
        'promo'.contains(q) || 'diskon'.contains(q) || 'voucher'.contains(q);
    return PromoLogic.defaultPromos.where((p) {
      if (genericPromoQuery) return true;
      final title = p.title ?? '';
      final code = p.voucherCode ?? '';
      return _matchesQuery(title, q) || _matchesQuery(code, q);
    }).toList();
  }

  void _openServiceByKey(String routeKey) {
    Widget target;
    switch (routeKey) {
      case 'flexride':
        target = const FlexRideScreen();
        break;
      case 'flexfood':
        target = const FlexFoodScreen();
        break;
      case 'flexsend':
      default:
        target = const FlexSendScreen();
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
  }

  void _openFood(Map<String, dynamic> food) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlexFoodScreen(
          initialState: FlexFoodState.grid,
          initialFood: food,
        ),
      ),
    );
  }

  void _openRestaurant(Map<String, dynamic> resto) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlexFoodScreen(
          initialState: FlexFoodState.restaurant,
          initialRestaurantName: resto['name'] as String?,
        ),
      ),
    );
  }

  void _openDestinationInFlexRide(String destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlexRideScreen(
          initialDestination: destination,
        ),
      ),
    );
  }

  void _showPromoActionSheet(PromoItemModel promo) {
    final code = promo.voucherCode ?? 'RIDEONHEMAT';
    final title = promo.title ?? 'Promo RideOn';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CEFE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Color(0xFF6B48FC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        Text(
                          'Kode Voucher: $code',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B48FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kode voucher $code disalin!'),
                            backgroundColor: const Color(0xFF17152B),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Kode'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B48FC),
                        side: const BorderSide(color: Color(0xFF6B48FC)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final lower = code.toLowerCase();
                        if (lower.contains('food')) {
                          _openServiceByKey('flexfood');
                        } else if (lower.contains('send')) {
                          _openServiceByKey('flexsend');
                        } else {
                          _openServiceByKey('flexride');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B48FC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Pakai Promo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final bool isEmptyQuery = query.isEmpty;

    final matchedServices = _searchServices(query);
    final matchedFoods = _searchFoods(query);
    final matchedRestaurants = _searchRestaurants(query);
    final matchedSaved = _searchSavedAddresses(query);
    final matchedWisata = _searchWisata(query);
    final matchedPromos = _searchPromos(query);

    final bool showServices = !isEmptyQuery &&
        (_selectedTab == SearchFilterTab.semua ||
            _selectedTab == SearchFilterTab.layanan) &&
        matchedServices.isNotEmpty;
    final bool showFoods = !isEmptyQuery &&
        (_selectedTab == SearchFilterTab.semua ||
            _selectedTab == SearchFilterTab.makanan) &&
        matchedFoods.isNotEmpty;
    final bool showRestos = !isEmptyQuery &&
        (_selectedTab == SearchFilterTab.semua ||
            _selectedTab == SearchFilterTab.restoran) &&
        matchedRestaurants.isNotEmpty;
    final bool showDestinationSection = !isEmptyQuery &&
        (_selectedTab == SearchFilterTab.semua ||
            _selectedTab == SearchFilterTab.tujuan) &&
        (matchedSaved.isNotEmpty ||
            matchedWisata.isNotEmpty ||
            _osmResults.isNotEmpty ||
            (_isLoadingOsm && query.length >= 2));
    final bool showPromos = !isEmptyQuery &&
        (_selectedTab == SearchFilterTab.semua ||
            _selectedTab == SearchFilterTab.promo) &&
        matchedPromos.isNotEmpty;

    final bool hasAnyResult = showServices ||
        showFoods ||
        showRestos ||
        showDestinationSection ||
        showPromos;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      body: Column(
        children: [
          // Header dengan Search Input Aktif
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9F88FD),
                  Color(0xFFBAA7FD),
                  Color(0xFFEFEAFF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.45, 0.85, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          key: const Key('btn_back_global_search'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF17152B),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF17152B)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF6B48FC),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    key: const Key('input_global_search'),
                                    controller: _searchController,
                                    autofocus: widget.autofocus,
                                    onChanged: _onQueryChanged,
                                    textInputAction: TextInputAction.search,
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF17152B),
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText:
                                          'Cari makanan, tujuan, layanan...',
                                      hintStyle: GoogleFonts.roboto(
                                        fontSize: 12.5,
                                        color: const Color(0xFF9E9AA8),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    key: const Key('btn_clear_global_search'),
                                    onTap: () {
                                      _searchController.clear();
                                      _onQueryChanged('');
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF8E88A8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isEmptyQuery) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: SearchFilterTab.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final tab = SearchFilterTab.values[index];
                            final selected = _selectedTab == tab;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTab = tab),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF17152B)
                                      : Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF17152B)
                                        : const Color(0xFFDAD2FE),
                                  ),
                                ),
                                child: Text(
                                  tab.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF17152B),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Body: Discovery (saat kosong) atau Hasil Pencarian (saat mengetik)
          Expanded(
            child: isEmptyQuery
                ? _buildEmptyDiscovery()
                : (!hasAnyResult
                    ? _buildNoResults(query)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        children: [
                          if (showServices) ...[
                            _buildSectionTitle(
                              'Layanan RideOn',
                              Icons.apps_rounded,
                            ),
                            const SizedBox(height: 8),
                            ...matchedServices.map(_buildServiceTile),
                            const SizedBox(height: 16),
                          ],
                          if (showFoods) ...[
                            _buildSectionTitle(
                              'Menu Makanan & Minuman',
                              Icons.lunch_dining_rounded,
                            ),
                            const SizedBox(height: 8),
                            ...matchedFoods.map(_buildFoodTile),
                            const SizedBox(height: 16),
                          ],
                          if (showRestos) ...[
                            _buildSectionTitle(
                              'Restoran Mitra',
                              Icons.storefront_rounded,
                            ),
                            const SizedBox(height: 8),
                            ...matchedRestaurants.map(_buildRestaurantTile),
                            const SizedBox(height: 16),
                          ],
                          if (showDestinationSection) ...[
                            _buildDestinationHeader(),
                            const SizedBox(height: 8),
                            ...matchedSaved.map(_buildSavedAddressTile),
                            ...matchedWisata.map(_buildWisataTile),
                            ..._osmResults.map(_buildOsmTile),
                            const SizedBox(height: 16),
                          ],
                          if (showPromos) ...[
                            _buildSectionTitle(
                              'Promo & Voucher',
                              Icons.local_offer_rounded,
                            ),
                            const SizedBox(height: 8),
                            ...matchedPromos.map(_buildPromoTile),
                          ],
                        ],
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDiscovery() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildSectionTitle('Pencarian Populer', Icons.trending_up_rounded),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularKeywords.map((kw) {
            return GestureDetector(
              onTap: () => _applyKeyword(kw),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2DCFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 14,
                      color: Color(0xFF6B48FC),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      kw,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('Akses Cepat Layanan', Icons.bolt_rounded),
        const SizedBox(height: 10),
        ...ServicesHeaderLogic.defaultServices.map(_buildServiceTile),
        if (_savedAddresses.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionTitle(
            'Tujuan Cepat dari Alamat Tersimpan',
            Icons.bookmark_rounded,
          ),
          const SizedBox(height: 8),
          ..._savedAddresses.map(_buildSavedAddressTile),
        ],
      ],
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: Color(0xFF6B48FC),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak ditemukan hasil untuk "$query"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba ketik nama makanan (Bakso, Nasi Goreng), nama jalan/tempat tujuan, layanan (FlexRide), atau Promo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF6B6680),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openDestinationInFlexRide(_searchController.text.trim()),
              icon: const Icon(Icons.two_wheeler_rounded, size: 18),
              label: Text(
                'Cari Rute FlexRide ke "${_searchController.text.trim()}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B48FC),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B48FC)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationHeader() {
    return Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          size: 16,
          color: Color(0xFF16A34A),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Tujuan & Lokasi (OpenStreetMap)',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF17152B),
            ),
          ),
        ),
        if (_isLoadingOsm) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B48FC)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceTile(ServiceItemModel service) {
    String subtitle;
    switch (service.routeKey) {
      case 'flexride':
        subtitle = 'Antar jemput motor & mobil cepat';
        break;
      case 'flexfood':
        subtitle = 'Pesan antar makanan & minuman favorit';
        break;
      default:
        subtitle = 'Titip belanja & kirim barang kilat';
        break;
    }

    return _buildCardTile(
      leading: Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          service.iconAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.apps_rounded,
            color: Color(0xFF6B48FC),
          ),
        ),
      ),
      title: service.title,
      subtitle: subtitle,
      badge: 'Layanan',
      onTap: () => _openServiceByKey(service.routeKey),
    );
  }

  Widget _buildFoodTile(Map<String, dynamic> food) {
    return _buildCardTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          food['image'] as String,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ),
      title: food['title'] as String,
      subtitle: '${food['resto']} • ${food['price']}',
      badge: 'FlexFood',
      onTap: () => _openFood(food),
    );
  }

  Widget _buildRestaurantTile(Map<String, dynamic> resto) {
    return _buildCardTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          resto['image'] as String,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ),
      title: resto['name'] as String,
      subtitle: '${resto['category']} • ${resto['distance']}',
      badge: 'Restoran',
      onTap: () => _openRestaurant(resto),
    );
  }

  Widget _buildSavedAddressTile(Map<String, dynamic> addr) {
    final label = addr['label'] as String? ?? 'Alamat Tersimpan';
    final address = addr['address'] as String? ?? '';
    return _buildCardTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.home_rounded,
          color: Color(0xFF6B48FC),
          size: 22,
        ),
      ),
      title: label,
      subtitle: address,
      badge: 'Tersimpan',
      onTap: () =>
          _openDestinationInFlexRide(address.isNotEmpty ? address : label),
    );
  }

  Widget _buildWisataTile(WisataItemModel wisata) {
    return _buildCardTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          wisata.imageAsset,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      ),
      title: wisata.title,
      subtitle: wisata.description,
      badge: 'Wisata',
      onTap: () => _openDestinationInFlexRide(wisata.title),
    );
  }

  Widget _buildOsmTile(OsmPlaceResult place) {
    final dist = place.formattedDistance;
    final sub = place.subtitle.isNotEmpty
        ? (dist != null ? '${place.subtitle} • $dist' : place.subtitle)
        : (dist ?? 'OpenStreetMap');
    return _buildCardTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F9EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.location_on_rounded,
          color: Color(0xFF16A34A),
          size: 22,
        ),
      ),
      title: place.title,
      subtitle: sub,
      badge: 'Peta OSM',
      badgeColor: const Color(0xFF16A34A),
      badgeBg: const Color(0xFFE8F9EE),
      onTap: () => _openDestinationInFlexRide(place.formattedAddress),
    );
  }

  Widget _buildPromoTile(PromoItemModel promo) {
    return _buildCardTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.confirmation_number_rounded,
          color: Color(0xFFEF6C00),
          size: 22,
        ),
      ),
      title: promo.title ?? 'Promo RideOn',
      subtitle: 'Kode: ${promo.voucherCode ?? '-'}',
      badge: 'Promo',
      badgeColor: const Color(0xFFEF6C00),
      badgeBg: const Color(0xFFFFF3E0),
      onTap: () => _showPromoActionSheet(promo),
    );
  }

  Widget _buildCardTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
    Color badgeColor = const Color(0xFF6B48FC),
    Color badgeBg = const Color(0xFFEDE8FF),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE7FC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: const Color(0xFF6B6680),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC6BCFF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

