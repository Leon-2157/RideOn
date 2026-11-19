import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'package:rideon/core/services/osm_nominatim_service.dart';

class LocationPickerModule extends StatefulWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final Function(String address) onSelectSavedAddress;
  final VoidCallback onPickViaMap;
  final VoidCallback onProceedToVehicles;
  final OsmNominatimService? nominatimService;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  const LocationPickerModule({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.onSelectSavedAddress,
    required this.onPickViaMap,
    required this.onProceedToVehicles,
    this.nominatimService,
    this.auth,
    this.firestore,
  });

  @override
  State<LocationPickerModule> createState() => _LocationPickerModuleState();
}

class _LocationPickerModuleState extends State<LocationPickerModule> {
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  bool _isSearchingPickup = false;
  bool _isSearchingDestination = false;

  late final OsmNominatimService _nominatim =
      widget.nominatimService ?? OsmNominatimService.instance;
  Timer? _debounceTimer;
  int _searchGeneration = 0;
  bool _isLoadingOsm = false;
  bool _isLoadingGps = false;
  String _lastOsmQuery = '';
  List<OsmPlaceResult> _osmResults = const [];
  List<Map<String, dynamic>> _firestoreSavedAddresses = const [];
  LatLng? _userLatLng;

  static const List<Map<String, dynamic>> savedAddresses = [
    {
      'label': 'Rumah',
      'dist': '0 km',
      'addr': 'Jl. Brawl No. 77, Lnad of down II',
      'asset': 'assets/icons/places/ic_place_rumah.png',
      'icon': Icons.home_rounded,
    },
    {
      'label': 'Kantor',
      'dist': '8,9 km',
      'addr': 'Jl. Brawl No. 77, Lnad of down II',
      'asset': 'assets/icons/places/ic_place_kantor.png',
      'icon': Icons.business_center_rounded,
    },
    {
      'label': 'Mall Centre',
      'dist': '5,7 km',
      'addr': 'Jl. Brawl No. 77, Lnad of down II',
      'asset': 'assets/icons/places/ic_place_mall.png',
      'icon': Icons.shopping_bag_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pickupFocusNode.addListener(_onFocusChanged);
    _destinationFocusNode.addListener(_onFocusChanged);
    widget.pickupController.addListener(_onTextChanged);
    widget.destinationController.addListener(_onTextChanged);
    _loadInitialContext();
  }

  Future<void> _loadInitialContext() async {
    final pos = await OsmNominatimService.tryGetKnownUserPosition();
    final saved = await OsmNominatimService.loadSavedAddresses(
      auth: widget.auth,
      firestore: widget.firestore,
    );
    if (!mounted) return;
    setState(() {
      if (pos != null) _userLatLng = pos;
      _firestoreSavedAddresses = saved;
    });
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {
      _isSearchingPickup = _pickupFocusNode.hasFocus;
      _isSearchingDestination = _destinationFocusNode.hasFocus;
    });
    final activeQuery = _activeQuery;
    if (activeQuery.length >= 2 && activeQuery != _lastOsmQuery) {
      _scheduleOsmSearch(activeQuery);
    }
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
    final activeQuery = _activeQuery;
    if (activeQuery != _lastOsmQuery) {
      _scheduleOsmSearch(activeQuery);
    }
  }

  String get _activeQuery {
    if (_isSearchingPickup) return widget.pickupController.text.trim();
    if (_isSearchingDestination) {
      return widget.destinationController.text.trim();
    }
    return '';
  }

  void _scheduleOsmSearch(String query) {
    _debounceTimer?.cancel();
    final gen = ++_searchGeneration;

    if (query.length < 2) {
      setState(() {
        _lastOsmQuery = query;
        _isLoadingOsm = false;
        _osmResults = const [];
      });
      return;
    }

    setState(() {
      _lastOsmQuery = query;
      _isLoadingOsm = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      final results = await _nominatim.searchPlaces(
        query,
        nearLat: _userLatLng?.latitude,
        nearLng: _userLatLng?.longitude,
        limit: 6,
      );
      if (!mounted || gen != _searchGeneration) return;
      setState(() {
        _isLoadingOsm = false;
        _osmResults = results;
      });
    });
  }

  Future<void> _fillPickupFromGps() async {
    setState(() => _isLoadingGps = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan GPS perangkat belum aktif.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin akses lokasi ditolak.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _userLatLng = LatLng(position.latitude, position.longitude);

      String detectedAddress =
          'Koordinat ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.street ?? '').isNotEmpty && !p.street!.contains('+'))
              p.street!,
            if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
            if ((p.locality ?? '').isNotEmpty) p.locality!,
            if ((p.subAdministrativeArea ?? '').isNotEmpty)
              p.subAdministrativeArea!,
          ];
          if (parts.isNotEmpty) {
            detectedAddress = parts.toSet().join(', ');
          }
        }
      } catch (_) {}

      if (!mounted) return;
      widget.pickupController.text = detectedAddress;
      _pickupFocusNode.unfocus();
      setState(() => _isSearchingPickup = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membaca GPS: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  List<Map<String, dynamic>> _matchingSavedAddresses(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final source = _firestoreSavedAddresses.isNotEmpty
        ? _firestoreSavedAddresses
        : savedAddresses;

    bool matchesPrefix(String text) {
      if (text.isEmpty) return false;
      final words = text.toLowerCase().split(RegExp(r'[\s,\.-]+'));
      return words.any((w) => w.startsWith(q));
    }

    final matches = <Map<String, dynamic>>[];
    for (final item in source) {
      final label = (item['label'] as String? ?? '').trim();
      final address = (item['address'] as String? ??
              item['addr'] as String? ??
              '')
          .trim();
      if (matchesPrefix(label) || matchesPrefix(address)) {
        matches.add({
          'label': label.isNotEmpty ? label : 'Alamat Tersimpan',
          'addr': address,
          'asset': item['asset'] ?? _assetForLabel(label),
          'icon': item['icon'] ?? _iconForLabel(label),
        });
      }
    }
    return matches;
  }

  String _assetForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'kantor':
        return 'assets/icons/places/ic_place_kantor.png';
      case 'mall centre':
        return 'assets/icons/places/ic_place_mall.png';
      default:
        return 'assets/icons/places/ic_place_rumah.png';
    }
  }

  IconData _iconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'kantor':
        return Icons.business_center_rounded;
      case 'kost':
        return Icons.apartment_rounded;
      case 'mall centre':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pickupFocusNode.removeListener(_onFocusChanged);
    _destinationFocusNode.removeListener(_onFocusChanged);
    widget.pickupController.removeListener(_onTextChanged);
    widget.destinationController.removeListener(_onTextChanged);
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Character Illustration Header with Blob matching Figma node [1:2948]
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 125,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // 1. Abstrak Blob ungu muda di belakang orang
                      Positioned(
                        top: 4,
                        left: -10,
                        width: 125,
                        height: 120,
                        child: Image.asset(
                          AppAssets.abstractBlob,
                          fit: BoxFit.contain,
                          color: const Color(0xFFC6BCFF).withValues(alpha: 0.75),
                        ),
                      ),

                      // 2. Ilustrasi Orang Bingung
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Image.asset(
                          AppAssets.flexrideManHeader,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Image.asset(
                    AppAssets.flexrideSpeechBubble,
                    height: 40,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),

          // Pickup & Destination Inputs Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC7BCFE).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6B48FC).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Pickup Input + Tombol GPS Otomatis
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOKASI JEMPUT',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextField(
                              controller: widget.pickupController,
                              focusNode: _pickupFocusNode,
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Ketik lokasi penjemputanmu...',
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      key: const Key('btn_flexride_gps'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _isLoadingGps ? null : _fillPickupFromGps,
                      child: Container(
                        height: 48,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6B48FC).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: _isLoadingGps
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6B48FC),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  size: 20,
                                  color: Color(0xFF6B48FC),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Dotted Connector
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 16,
                      color: const Color(0xFF6B48FC).withValues(alpha: 0.4),
                    ),
                  ),
                ),
                // Destination Input
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B48FC),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TUJUAN PERJALANAN',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextField(
                              controller: widget.destinationController,
                              focusNode: _destinationFocusNode,
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Ketik tujuan perjalananmu...',
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isSearchingDestination) ...[
                  const SizedBox(height: 12),
                  // Dua tombol: + Pilih Lewat Peta Langsung & + Tambah Tujuan presisi Figma masuk flex ride-1.png
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onPickViaMap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '+ Pilih Lewat Peta Langsung',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '+ Tambah Tujuan',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tampilan Suggestion hanya muncul saat user mengetik (query tidak kosong)
          if ((_isSearchingPickup || _isSearchingDestination) &&
              _activeQuery.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final query = _activeQuery;
                final isPickup = _isSearchingPickup;
                final savedMatches = _matchingSavedAddresses(query);

                void applyChoice(String value) {
                  if (isPickup) {
                    widget.pickupController.text = value;
                    _pickupFocusNode.unfocus();
                    setState(() => _isSearchingPickup = false);
                  } else {
                    widget.destinationController.text = value;
                    _destinationFocusNode.unfocus();
                    setState(() => _isSearchingDestination = false);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Alamat Tersimpan yang Cocok (Prioritas #1)
                    ...savedMatches.map((saved) {
                      final title = saved['label'] as String? ?? 'Alamat';
                      final addr = saved['addr'] as String? ?? '';
                      final asset = saved['asset'] as String?;
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () =>
                                applyChoice(addr.isNotEmpty ? addr : title),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: asset != null
                                        ? Image.asset(
                                            asset,
                                            width: 20,
                                            height: 20,
                                            errorBuilder: (_, _, _) => Icon(
                                              saved['icon'] as IconData? ??
                                                  Icons.home_rounded,
                                              color: const Color(0xFF6B48FC),
                                              size: 20,
                                            ),
                                          )
                                        : Icon(
                                            saved['icon'] as IconData? ??
                                                Icons.home_rounded,
                                            color: const Color(0xFF6B48FC),
                                            size: 20,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                title,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF17152B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3EFFF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFC6BCFF),
                                                ),
                                              ),
                                              child: Text(
                                                'Alamat Tersimpan',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF6B48FC),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (addr.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            addr,
                                            style: GoogleFonts.roboto(
                                              fontSize: 11,
                                              color: const Color(0xFF6B6680),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F0F5)),
                        ],
                      );
                    }),

                    // 2. Indikator Loading & Hasil OpenStreetMap Nominatim
                    if (query.length >= 2) ...[
                      if (_isLoadingOsm)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 6.0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6B48FC)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Mencari lokasi di OpenStreetMap...',
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: const Color(0xFF6B6680),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ..._osmResults.map((place) {
                        final distLabel = place.formattedDistance;
                        return Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => applyChoice(place.formattedAddress),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: isPickup
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFF6B48FC),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  place.title,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF17152B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (distLabel != null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF0FDF4),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFF86EFAC),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    distLabel,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF16A34A),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (place.subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              place.subtitle,
                                              style: GoogleFonts.roboto(
                                                fontSize: 11,
                                                color: const Color(0xFF6B6680),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F0F5)),
                          ],
                        );
                      }),
                    ],

                    // 3. Fallback Manual (Jika pengguna ingin pakai alamat persis yg diketik)
                    if (!_isLoadingOsm &&
                        savedMatches.isEmpty &&
                        _osmResults.isEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => applyChoice(query),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 6.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_location_alt_rounded,
                                color: isPickup
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF6B48FC),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Gunakan alamat "$query"',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ] else ...[
            // Section Title
            Text(
              'Alamat Favorit & Riwayat Cepat',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 12),

            // Saved Addresses List
            ...savedAddresses.map((addr) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE1DAFE),
                      Color(0xFFE1DAFE),
                      Colors.white,
                    ],
                    stops: [0.0, 0.45, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC7BCFE),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: const Color(0xFF6B48FC).withValues(alpha: 0.12),
                    highlightColor: const Color(0xFF6B48FC).withValues(alpha: 0.08),
                    onTap: () {
                      widget.pickupController.text = addr['addr'] as String;
                      widget.onSelectSavedAddress(addr['addr'] as String);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 12.0),
                      child: Row(
                        children: [
                          // Standalone clean icon (tanpa border ungu / box latar) sesuai desain Figma
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, right: 6.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: addr['asset'] != null
                                    ? Image.asset(
                                        addr['asset'] as String,
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          addr['icon'] as IconData,
                                          size: 20,
                                          color: const Color(0xFF17152B),
                                        ),
                                      )
                                    : Icon(
                                        addr['icon'] as IconData,
                                        size: 20,
                                        color: const Color(0xFF17152B),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr['label'] as String,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  addr['addr'] as String,
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: const Color(0xFF6B6680),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            addr['dist'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),

            // Tombol Lanjut Pilih Kendaraan
            Builder(
              builder: (context) {
                final bool isReady = widget.pickupController.text.trim().isNotEmpty &&
                    widget.destinationController.text.trim().isNotEmpty;
                return Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: isReady ? widget.onProceedToVehicles : null,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: isReady
                            ? const Color(0xFF17152B)
                            : const Color(0xFFC4C2CF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isReady
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lanjut Pilih Kendaraan',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isReady ? Colors.white : const Color(0xFF7E7B8E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
