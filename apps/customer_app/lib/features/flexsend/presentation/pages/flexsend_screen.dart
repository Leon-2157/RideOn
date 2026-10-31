import 'dart:async';
import 'package:flutter/material.dart';
import '../modules/form/add_item_sheet.dart';
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
/// - flrxsend.png / flrxsend-4.png / flrxsend-5.png / flrxsend-6.png / flrxsend-7.png
/// - cari driver.png (radar pulse searching)
/// - dapat driver.png (driver found + "Lanjut dengan driver ini?")
/// - beli brng.png (driver shopping in store)
/// - driver sampai.png (driver on route to delivery)
/// - driver sampai-1.png (driver arrived + "Selesai dan Lihat Rincian Belanja")
/// - flrxsend-2.png (receipt / pelunasan tunai breakdown + "SELESAI")
class FlexSendScreen extends StatefulWidget {
  const FlexSendScreen({super.key});

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

  // Shopping items in Location 1 (Pasar Pagi Batuphat)
  final List<FlexSendItem> _location1Items = [
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
  ];

  // Shopping items in Location 2 (Apotek Kimia Farma / Lokasi Tambahan)
  bool _isLocation2Active = true;
  final List<FlexSendItem> _location2Items = [
    FlexSendItem(
      name: 'Minyak Kayu Putih 120ml (1 btl)',
      qty: 1,
      price: 25000,
    ),
  ];

  late AnimationController _radarController;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  int get _location1Subtotal =>
      _location1Items.fold(0, (sum, item) => sum + (item.price * item.qty));

  int get _location2Subtotal => _isLocation2Active
      ? _location2Items.fold(0, (sum, item) => sum + (item.price * item.qty))
      : 0;

  int get _totalTalangan => _location1Subtotal + _location2Subtotal;
  int get _baseOngkir => 12000;
  int get _extraStopFee => _isLocation2Active ? 2000 : 0;
  int get _itemQuotaFee => ((_location1Items.length +
              (_isLocation2Active ? _location2Items.length : 0)) >=
          4)
      ? 1000
      : 0;
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

  void _openAddItemSheet(int locationIndex) {
    showAddItemSheet(
      context: context,
      locationIndex: locationIndex,
      onSaveItem: (newItem) {
        setState(() {
          if (locationIndex == 1) {
            _location1Items.add(newItem);
          } else {
            _location2Items.add(newItem);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case FlexSendState.form:
        return ShoppingFormView(
          location1Items: _location1Items,
          location2Items: _location2Items,
          isLocation2Active: _isLocation2Active,
          onAddLocation: () {
            if (!_isLocation2Active) {
              setState(() {
                _isLocation2Active = true;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Lokasi singgah maksimal 2 tempat')),
              );
            }
          },
          onDeleteLocation2: () {
            setState(() {
              _isLocation2Active = false;
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
          onBack: () {
            _searchTimer?.cancel();
            _radarController.stop();
            setState(() => _currentState = FlexSendState.form);
          },
          onSeeReceipt: () {
            setState(() {
              _currentState = FlexSendState.receipt;
            });
          },
        );

      case FlexSendState.receipt:
        return ShoppingReceiptView(
          onFinish: () {
            setState(() {
              _currentState = FlexSendState.form;
            });
            Navigator.of(context).pop();
          },
        );
    }
  }
}
