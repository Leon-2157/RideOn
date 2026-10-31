import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/sub_header_widget.dart';
import '../modules/lokasi_anda/lokasi_control_card.dart';
import '../modules/lokasi_anda/lokasi_anda_logic.dart';
import '../modules/lokasi_anda/lokasi_map_module.dart';

export '../modules/lokasi_anda/lokasi_control_card.dart';
export '../modules/lokasi_anda/lokasi_anda_logic.dart';
export '../modules/lokasi_anda/lokasi_map_module.dart';

/// Screen Pengaturan Titik Lokasi Anda (Slim Coordinator)
class LokasiAndaScreen extends StatefulWidget {
  final MapController? mapController;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final LatLng? initialCenter;

  const LokasiAndaScreen({
    super.key,
    this.mapController,
    this.auth,
    this.firestore,
    this.initialCenter,
  });

  @override
  State<LokasiAndaScreen> createState() => _LokasiAndaScreenState();
}

class _LokasiAndaScreenState extends State<LokasiAndaScreen> {
  late final MapController _mapController;
  late final LokasiAndaLogic _logic;

  late LatLng _currentPosition;
  double _currentZoom = 15.0;

  String _currentAddress =
      'Klik tombol GPS di atas untuk mengisi alamat secara otomatis.';
  bool _isLocationLocked = false;
  bool _isLoadingGps = false;
  bool _isSaving = false;
  String _selectedLabel = 'Rumah';
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _labelOptions = [
    {'label': 'Rumah', 'icon': Icons.home_rounded},
    {'label': 'Kantor', 'icon': Icons.business_rounded},
    {'label': 'Kost', 'icon': Icons.apartment_rounded},
    {'label': 'Lainnya', 'icon': Icons.location_on_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _logic = LokasiAndaLogic(auth: widget.auth, firestore: widget.firestore);
    _currentPosition =
        widget.initialCenter ?? const LatLng(5.2472, 97.0261);
    _loadExistingSavedLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSavedLocation() async {
    final saved = await _logic.loadSavedLocation();
    if (saved != null && mounted) {
      final lat = (saved['latitude'] as num?)?.toDouble();
      final lng = (saved['longitude'] as num?)?.toDouble();
      final addr = saved['address'] as String?;
      final lbl = saved['label'] as String?;
      final nt = saved['note'] as String?;

      if (lat != null && lng != null) {
        setState(() {
          _currentPosition = LatLng(lat, lng);
          if (addr != null && addr.isNotEmpty) _currentAddress = addr;
          if (lbl != null && lbl.isNotEmpty) _selectedLabel = lbl;
          if (nt != null && nt.isNotEmpty) _noteController.text = nt;
          _isLocationLocked = true;
        });
        _mapController.move(_currentPosition, _currentZoom);
      }
    }
  }

  Future<void> _getCurrentLocationGps() async {
    setState(() => _isLoadingGps = true);

    try {
      final position = await _logic.getCurrentPosition();
      final newCoord = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = newCoord;
          _currentZoom = 16.5;
        });
        _mapController.move(newCoord, 16.5);
      }

      final resolvedAddr =
          await _logic.reverseGeocode(position.latitude, position.longitude);
      if (resolvedAddr != null && mounted) {
        setState(() {
          _currentAddress = resolvedAddr;
          _isLocationLocked = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingGps = false);
      }
    }
  }

  Future<void> _saveLocationToFirebase() async {
    setState(() => _isSaving = true);

    try {
      await _logic.saveLocation(
        position: _currentPosition,
        address: _currentAddress,
        label: _selectedLabel,
        note: _noteController.text.trim(),
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC7BCFE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF17152B),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lokasi Berhasil Disimpan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17152B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Titik $_selectedLabel Anda telah diperbarui dan akan digunakan otomatis saat memesan layanan RideOn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF17152B).withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17152B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SELESAI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildSubHeader(context, 'Lokasi Anda'),
          Expanded(
            child: Stack(
              children: [
                LokasiMapModule(
                  mapController: _mapController,
                  currentPosition: _currentPosition,
                  currentZoom: _currentZoom,
                  onZoomIn: () {
                    setState(() {
                      _currentZoom = (_currentZoom + 1).clamp(3.0, 19.0);
                      _mapController.move(_currentPosition, _currentZoom);
                    });
                  },
                  onZoomOut: () {
                    setState(() {
                      _currentZoom = (_currentZoom - 1).clamp(3.0, 19.0);
                      _mapController.move(_currentPosition, _currentZoom);
                    });
                  },
                  onRecenterGps: _getCurrentLocationGps,
                  onPositionChanged: (pos, hasGesture) {
                    _currentPosition = pos.center;
                    _currentZoom = pos.zoom;
                    if (hasGesture && _isLocationLocked) {
                      setState(() => _isLocationLocked = false);
                    }
                  },
                ),
                LokasiControlCard(
                  isLoadingGps: _isLoadingGps,
                  isLocationLocked: _isLocationLocked,
                  selectedLabel: _selectedLabel,
                  labelOptions: _labelOptions,
                  currentAddress: _currentAddress,
                  noteController: _noteController,
                  isSaving: _isSaving,
                  onGetGps: _getCurrentLocationGps,
                  onSelectLabel: (lbl) =>
                      setState(() => _selectedLabel = lbl),
                  onSaveLocation: _saveLocationToFirebase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
