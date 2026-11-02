import 'dart:async';
import 'package:flutter/material.dart';
import '../modules/form/add_item_sheet.dart';
import '../modules/form/place_picker_bottom_sheet.dart';
import '../modules/form/shopping_form_view.dart';
import '../modules/models/flexsend_item_model.dart';
import '../modules/receipt/shopping_receipt_view.dart';
import '../modules/searching/searching_view.dart';
import '../modules/tracking/delivering_progress_view.dart';
import '../modules/tracking/driver_arrived_view.dart';
import '../modules/tracking/driver_found_view.dart';
import '../modules/tracking/shopping_progress_view.dart';

export '../modules/models/flexsend_item_model.dart';

/// Halaman FlexSend strictly matching Figma designs in figma/HalamanFlexSend:
/// - Mendukung kondisi awal kosong (user input manual sendiri)
/// - Menambahkan lokasi singgah dengan Google Maps & form pencarian interaktif
/// - Mendukung hingga maksimal 3 lokasi singgah
class FlexSendScreen extends StatefulWidget {
  final bool initialEmpty;

  const FlexSendScreen({
    super.key,
    this.initialEmpty = true,
  });

  @override
  State<FlexSendScreen> createState() => _FlexSendScreenState();
}

enum FlexSendState {
  form, // Form input belanjaan & lokasi
  searching, // Radar mencari driver (cari driver.png)
  driverFound, // Driver ditemukan (dapat driver.png)
  shopping, // Driver belanja di pasar/toko (beli brng.png)
  delivering, // Driver dalam perjalanan mengantar (driver sampai.png)
  arrived, // Driver telah sampai di lokasi (driver sampai-1.png)
  receipt, // Rincian pelunasan belanja (flrxsend-2.png)
}

class _FlexSendScreenState extends State<FlexSendScreen>
    with SingleTickerProviderStateMixin {
  FlexSendState _currentState = FlexSendState.form;

  // Daftar lokasi belanja dinamis (Maksimal 3 lokasi)
  final List<FlexSendLocation> _locations = [];

  late AnimationController _radarController;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Jika tidak kosong, isi dengan mock data awal
    if (!widget.initialEmpty) {
      _locations.add(
        FlexSendLocation(
          name: 'Pasar Pagi Batuphat',
          address: 'Jl. Medan - Banda Aceh, Batuphat',
          items: [
            FlexSendItem(
              name: 'Daging Sapi (1 kg)',
              qty: 1,
              price: 120000,
              notes: 'Potong rendang',
            ),
            FlexSendItem(
              name: 'Cabai Merah (1/2 kg)',
              qty: 1,
              price: 20000,
              notes: 'Pilih yang segar',
            ),
            FlexSendItem(
              name: 'Bawang Merah (1/4 kg)',
              qty: 1,
              price: 10000,
            ),
            FlexSendItem(
              name: 'Santan Instan (2 bks)',
              qty: 2,
              price: 6000,
            ),
          ],
        ),
      );
      _locations.add(
        FlexSendLocation(
          name: 'Apotek Kimia Farma',
          address: 'Jl. Perdagangan No. 8',
          items: [
            FlexSendItem(
              name: 'Minyak Kayu Putih 120ml (1 btl)',
              qty: 1,
              price: 25000,
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  int get _totalTalangan =>
      _locations.fold(0, (sum, loc) => sum + loc.subtotal);

  int get _baseOngkir => _locations.isEmpty ? 0 : 12000;

  // Lokasi ke-2 +Rp 2.000, Lokasi ke-3 +Rp 2.000
  int get _extraStopFee =>
      _locations.length > 1 ? (_locations.length - 1) * 2000 : 0;

  int get _totalItemsCount =>
      _locations.fold(0, (sum, loc) => sum + loc.items.length);

  int get _itemQuotaFee => _totalItemsCount >= 4 ? 1000 : 0;

  int get _totalOngkir => _baseOngkir + _extraStopFee + _itemQuotaFee;

  int get _totalBayar => _totalTalangan + _totalOngkir;

  void _startSearching() {
    setState(() {
      _currentState = FlexSendState.searching;
      _radarController.repeat();
    });

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _currentState == FlexSendState.searching) {
        _radarController.stop();
        setState(() {
          _currentState = FlexSendState.driverFound;
        });
      }
    });
  }

  void _cancelSearching() {
    _searchTimer?.cancel();
    _radarController.stop();
    setState(() {
      _currentState = FlexSendState.form;
    });
  }

  void _openPlacePicker() {
    if (_locations.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi singgah belanja maksimal 3 tempat'),
          backgroundColor: Color(0xFF6B48FC),
        ),
      );
      return;
    }

    final int nextLocationIndex = _locations.length + 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PlacePickerBottomSheet(
          locationIndex: nextLocationIndex,
          onPlaceSelected: (name, address) {
            setState(() {
              _locations.add(
                FlexSendLocation(
                  name: name,
                  address: address,
                ),
              );
            });
          },
        );
      },
    );
  }

  void _openAddItemSheet(int locationIndex) {
    if (locationIndex < 0 || locationIndex >= _locations.length) return;

    showAddItemSheet(
      context: context,
      locationIndex: locationIndex + 1,
      onSaveItem: (newItem) {
        setState(() {
          _locations[locationIndex].items.add(newItem);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case FlexSendState.form:
        return ShoppingFormView(
          onBack: () => Navigator.of(context).maybePop(),
          locations: _locations,
          onAddLocation: _openPlacePicker,
          onDeleteLocation: (index) {
            setState(() {
              _locations.removeAt(index);
            });
          },
          onAddItem: _openAddItemSheet,
          onStartSearching: _startSearching,
          baseOngkir: _baseOngkir,
          extraStopFee: _extraStopFee,
          itemQuotaFee: _itemQuotaFee,
          totalOngkir: _totalOngkir,
          totalTalangan: _totalTalangan,
          totalBayar: _totalBayar,
        );

      case FlexSendState.searching:
        return FlexSendSearchingView(
          radarController: _radarController,
          locations: _locations,
          totalBayar: _totalBayar,
          onCancel: _cancelSearching,
          onDriverFound: () {
            _searchTimer?.cancel();
            _radarController.stop();
            setState(() => _currentState = FlexSendState.driverFound);
          },
        );

      case FlexSendState.driverFound:
        return DriverFoundView(
          onBack: () {
            _searchTimer?.cancel();
            _radarController.stop();
            setState(() => _currentState = FlexSendState.form);
          },
          onProceed: () {
            setState(() {
              _currentState = FlexSendState.shopping;
            });
          },
        );

      case FlexSendState.shopping:
        return ShoppingProgressView(
          locations: _locations,
          onBack: () {
            _searchTimer?.cancel();
            _radarController.stop();
            setState(() => _currentState = FlexSendState.form);
          },
          onAdvanceToDelivering: () {
            setState(() => _currentState = FlexSendState.delivering);
          },
        );

      case FlexSendState.delivering:
        return DeliveringProgressView(
          locations: _locations,
          onBack: () {
            _searchTimer?.cancel();
            _radarController.stop();
            setState(() => _currentState = FlexSendState.form);
          },
          onAdvanceToArrived: () {
            setState(() => _currentState = FlexSendState.arrived);
          },
        );

      case FlexSendState.arrived:
        return DriverArrivedView(
          locations: _locations,
          onBack: () {
            setState(() => _currentState = FlexSendState.delivering);
          },
          onSeeReceipt: () {
            setState(() => _currentState = FlexSendState.receipt);
          },
        );

      case FlexSendState.receipt:
        return ShoppingReceiptView(
          locations: _locations,
          baseOngkir: _baseOngkir,
          extraStopFee: _extraStopFee,
          itemQuotaFee: _itemQuotaFee,
          totalOngkir: _totalOngkir,
          totalTalangan: _totalTalangan,
          totalBayar: _totalBayar,
          onFinish: () => Navigator.of(context).maybePop(),
        );
    }
  }
}
