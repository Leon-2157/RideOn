import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'package:rideon/core/models/customer_models.dart';
import 'package:rideon/core/services/customer_api_service.dart';
import '../header/flexfood_header.dart';

class CheckoutView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onAddMoreItems;
  final VoidCallback onPlaceOrder;
  final String restaurantName;
  final String foodTitle;
  final String deliveryLabel;
  final String deliveryAddress;
  final String deliveryNotes;
  final Function(String label, String address, String notes)? onChangeAddress;
  final int cartQuantity;
  final int subtotalPrice;
  final int spicyLevel;
  final bool extraEgg;
  final String kitchenNotes;
  final int deliveryFee;
  final int serviceFee;
  final int totalPrice;
  final String? storeId;
  final String? menuId;
  final ValueChanged<String>? onOrderCreated;

  const CheckoutView({
    super.key,
    required this.onBack,
    required this.onAddMoreItems,
    required this.onPlaceOrder,
    this.restaurantName = 'Banku City Resto & Cafe',
    this.foodTitle = 'Nasi Goreng Spesial',
    this.deliveryLabel = 'Rumah',
    this.deliveryAddress = 'Jl. Brawl No. 77',
    this.deliveryNotes = 'Pagar hitam depan pos satpam',
    this.onChangeAddress,
    required this.cartQuantity,
    required this.subtotalPrice,
    required this.spicyLevel,
    required this.extraEgg,
    required this.kitchenNotes,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalPrice,
    this.storeId,
    this.menuId,
    this.onOrderCreated,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  // 'tunai' atau 'qris' (Default: tunai)
  String _selectedPaymentMethod = 'tunai';
  bool _isQrScannedAndPaid = false;
  Timer? _qrVerificationTimer;
  Timer? _qrisPollTimer;
  StreamSubscription<DatabaseEvent>? _rtdbOrderSub;
  String? _createdOrderId;
  QrisPaymentResult? _qrisPayment;
  bool _isPreparingQris = false;
  bool _isCheckingQris = false;
  bool _isSubmittingOrder = false;
  String? _paymentError;

  @override
  void dispose() {
    _qrVerificationTimer?.cancel();
    _qrisPollTimer?.cancel();
    _rtdbOrderSub?.cancel();
    super.dispose();
  }

  void _onSelectMethod(String method) {
    if (method == 'tunai') {
      if (_isQrScannedAndPaid) return; // Terkunci jika QR sudah terbayar
      _qrVerificationTimer?.cancel();
      _qrisPollTimer?.cancel();
      _rtdbOrderSub?.cancel();
      setState(() {
        _selectedPaymentMethod = 'tunai';
        _paymentError = null;
      });
    } else if (method == 'qris') {
      _qrVerificationTimer?.cancel();
      _qrisPollTimer?.cancel();
      _rtdbOrderSub?.cancel();
      setState(() {
        _selectedPaymentMethod = 'qris';
        _isQrScannedAndPaid = false;
        _paymentError = null;
      });

      if (CustomerApiService().hasSession &&
          !CustomerApiService.enableLocalFallback) {
        _prepareLiveQrisOrder();
      } else {
        _qrVerificationTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && _selectedPaymentMethod == 'qris') {
            setState(() {
              _isQrScannedAndPaid = true;
            });
          }
        });
      }
    }
  }

  Future<CustomerOrder> _createFoodOrder(String paymentMethod) async {
    final api = CustomerApiService();
    var targetStoreId = widget.storeId ?? '';
    if (targetStoreId.isEmpty) {
      final stores = await api.getStores();
      if (stores.isNotEmpty) {
        targetStoreId = stores.first.id;
      }
    }
    final unitPrice = widget.cartQuantity > 0
        ? (widget.subtotalPrice / widget.cartQuantity).round()
        : widget.subtotalPrice;
    final notesParts = <String>[
      if (widget.spicyLevel > 0) 'Level pedas ${widget.spicyLevel}',
      if (widget.extraEgg) 'Tambah telur',
      if (widget.kitchenNotes.trim().isNotEmpty) widget.kitchenNotes.trim(),
    ];
    final order = await api.createOrder(
      serviceType: 'FLEX_FOOD',
      vehicleType: 'MOTOR',
      paymentMethod: paymentMethod,
      storeId: targetStoreId.isNotEmpty ? targetStoreId : null,
      pickupAddress: widget.restaurantName,
      dropoffAddress: widget.deliveryAddress,
      itemsSubtotal: widget.subtotalPrice,
      notes: notesParts.join(' • '),
      items: [
        CustomerOrderItem(
          menuId: widget.menuId ?? '',
          itemName: widget.foodTitle,
          unitPrice: unitPrice,
          qty: widget.cartQuantity > 0 ? widget.cartQuantity : 1,
          notes: widget.kitchenNotes,
        ),
      ],
    );
    _createdOrderId = order.id;
    widget.onOrderCreated?.call(order.id);
    return order;
  }

  Future<void> _prepareLiveQrisOrder() async {
    setState(() {
      _isPreparingQris = true;
      _paymentError = null;
    });
    try {
      final api = CustomerApiService();
      late final CustomerOrder order;
      if (_createdOrderId != null && _createdOrderId!.isNotEmpty) {
        order = await api.getOrder(_createdOrderId!);
      } else {
        order = await _createFoodOrder('QRIS');
      }
      final base = order.totalCustomerPay > 0
          ? order.totalCustomerPay
          : widget.totalPrice;
      final qris = await api.generateOrderQris(
        orderId: order.id,
        baseAmount: base,
      );
      if (!mounted) return;
      setState(() {
        _qrisPayment = qris;
        _isQrScannedAndPaid = qris.isPaid;
        _isPreparingQris = false;
      });
      _subscribeOrderPayment(order.id);
      _qrisPollTimer?.cancel();
      _qrisPollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkQrisStatus(silent: true),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreparingQris = false;
        _paymentError = e.toString().replaceFirst('CustomerApiException', '');
      });
    }
  }

  void _subscribeOrderPayment(String orderId) {
    if (Firebase.apps.isEmpty || orderId.isEmpty) return;
    _rtdbOrderSub?.cancel();
    _rtdbOrderSub = FirebaseDatabase.instance
        .ref('live_orders/$orderId')
        .onValue
        .listen((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        final payStatus = (raw['payment_status'] ?? '').toString().toUpperCase();
        if ((payStatus == 'PAID' || payStatus == 'SETTLEMENT') && mounted) {
          _qrisPollTimer?.cancel();
          setState(() {
            _isQrScannedAndPaid = true;
          });
        }
      }
    }, onError: (_) {});
  }

  Future<void> _checkQrisStatus({bool silent = false}) async {
    final refId = _qrisPayment?.referenceId ?? '';
    if (refId.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menyiapkan QRIS pembayaran...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }
    if (!silent && mounted) {
      setState(() => _isCheckingQris = true);
    }
    try {
      final updated = await CustomerApiService().getQrisStatus(refId);
      if (!mounted) return;
      setState(() {
        _qrisPayment = updated;
        _isCheckingQris = false;
        if (updated.isPaid) {
          _isQrScannedAndPaid = true;
          _qrisPollTimer?.cancel();
        }
      });
      if (!silent && !updated.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status QRIS (${updated.referenceId}): ${updated.status}. Transfer tepat Rp ${updated.payableAmount}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingQris = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memeriksa QRIS: $e')),
        );
      }
    }
  }

  Future<void> _handlePlaceOrderPressed() async {
    if (_isSubmittingOrder) return;
    if (CustomerApiService().hasSession &&
        !CustomerApiService.enableLocalFallback &&
        _selectedPaymentMethod == 'tunai' &&
        (_createdOrderId == null || _createdOrderId!.isEmpty)) {
      setState(() => _isSubmittingOrder = true);
      try {
        await _createFoodOrder('CASH');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat pesanan: $e')),
          );
          setState(() => _isSubmittingOrder = false);
        }
        return;
      }
      if (mounted) {
        setState(() => _isSubmittingOrder = false);
      }
    }
    widget.onPlaceOrder();
  }

  void _showChangeAddressSheet(BuildContext context) {
    String currentLabel = widget.deliveryLabel;
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    bool isLoadingLocation = false;

    final labels = [
      {'name': 'Rumah', 'icon': Icons.home_rounded},
      {'name': 'Kantor', 'icon': Icons.business_rounded},
      {'name': 'Kost', 'icon': Icons.apartment_rounded},
      {'name': 'Lainnya', 'icon': Icons.location_on_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isAddressFilled = addressController.text.trim().isNotEmpty;

            Future<void> getCurrentLocation() async {
              setSheetState(() => isLoadingLocation = true);
              try {
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Layanan lokasi belum diaktifkan'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                  return;
                }

                LocationPermission permission =
                    await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) return;
                }

                if (permission == LocationPermission.deniedForever) return;

                Position position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                    timeLimit: Duration(seconds: 8),
                  ),
                );

                final geocoding = Geocoding();
                List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
                  position.latitude,
                  position.longitude,
                );

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

                  final fullAddress = addressParts.toSet().join(', ');
                  setSheetState(() {
                    addressController.text = fullAddress.isNotEmpty
                        ? fullAddress
                        : 'Jl. Lokasi Saat Ini No. ${position.latitude.toStringAsFixed(3)}';
                  });
                }
              } catch (_) {
                // Fallback alamat realistis jika GPS simulator / mock timeout
                setSheetState(() {
                  addressController.text =
                      'Jl. Merdeka No. 12, Dewantara, Aceh Utara';
                });
              } finally {
                setSheetState(() => isLoadingLocation = false);
              }
            }
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2DCFE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ubah Alamat Pengantaran',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Label Alamat Chips (Scrollable horizontal agar tidak overflow di layar kecil)
                  Text(
                    'Simpan Sebagai',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: labels.map((item) {
                        final isSelected = currentLabel == item['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                currentLabel = item['name'] as String;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFF7F7FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6B48FC)
                                      : const Color(0xFFE2DCFE),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF6B48FC),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    item['name'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF17152B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alamat Lengkap (Wajib) & Tombol GPS / Maps
                  Row(
                    children: [
                      Text(
                        'Alamat Lengkap / Nama Jalan ',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      Text(
                        '(Wajib)',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE83535),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2DCFE)),
                          ),
                          child: TextField(
                            controller: addressController,
                            onChanged: (val) {
                              setSheetState(() {});
                            },
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF17152B),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Contoh: Jl. Brawl No. 77',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 12,
                                color: const Color(0xFFA6A3B3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Maps / Lokasi GPS Otomatis
                      GestureDetector(
                        onTap: isLoadingLocation ? null : getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6B48FC)),
                          ),
                          child: isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6B48FC),
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.my_location_rounded,
                                      size: 16,
                                      color: Color(0xFF6B48FC),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Maps',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B48FC),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Catatan Patokan (Opsional)
                  Row(
                    children: [
                      Text(
                        'Catatan / Patokan Lokasi ',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6680),
                        ),
                      ),
                      Text(
                        '(Opsional)',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: const Color(0xFF8E8A9E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                    ),
                    child: TextField(
                      controller: notesController,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF17152B),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Contoh: Pagar hitam depan pos satpam',
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xFFA6A3B3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Simpan Alamat (Abu-abu / Disabled jika alamat belum diisi)
                  ElevatedButton(
                    onPressed: isAddressFilled
                        ? () {
                            final newAddress = addressController.text.trim();
                            final newNotes = notesController.text.trim().isEmpty
                                ? '-'
                                : notesController.text.trim();
                            widget.onChangeAddress?.call(
                              currentLabel,
                              newAddress,
                              newNotes,
                            );
                            Navigator.of(ctx).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1832),
                      disabledBackgroundColor: const Color(0xFFE2E0EA),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF8E8A9E),
                      elevation: isAddressFilled ? 2 : 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isAddressFilled
                          ? 'Simpan Alamat Pengantaran'
                          : 'Isi Alamat Lengkap Terlebih Dahulu',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
          FlexFoodHeader(
            title: 'Konfirmasi Pesanan',
            onBack: widget.onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Diantar ke Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: Color(0xFF6B48FC),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diantar ke: ${widget.deliveryLabel} (${widget.deliveryAddress})',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Catatan: ${widget.deliveryNotes}',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  color: const Color(0xFF6B6680),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showChangeAddressSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Text(
                              'Ubah',
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: Color(0xFF6B48FC),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.restaurantName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.cartQuantity}x ${widget.foodTitle}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Rp ${widget.subtotalPrice}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Level ${widget.spicyLevel} ${widget.extraEgg ? 'Ekstra Telur, ' : ''}Catatan: ${widget.kitchenNotes}',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onAddMoreItems,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 15,
                                  color: Color(0xFF6B48FC),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Tambah menu lain dari restoran ini',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6B48FC),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metode Pembayaran Card (Default: Bayar Tunai ke Driver)
                  // Metode Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Metode Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Opsi 1: Tunai / Cash Langsung
                        Opacity(
                          opacity: _isQrScannedAndPaid ? 0.45 : 1.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _isQrScannedAndPaid
                                ? null
                                : () => _onSelectMethod('tunai'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethod == 'tunai'
                                    ? const Color(0xFFF7F7FA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'tunai'
                                      ? const Color(0xFF6B48FC)
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.payments_rounded,
                                      color: Color(0xFF10B981),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tunai / Cash Langsung',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight:
                                                _selectedPaymentMethod == 'tunai'
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                            color: const Color(0xFF17152B),
                                          ),
                                        ),
                                        Text(
                                          'Bayar langsung ke driver saat pesanan tiba',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9.5,
                                            color: const Color(0xFF8E88A8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _selectedPaymentMethod == 'tunai'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: _selectedPaymentMethod == 'tunai'
                                        ? const Color(0xFF6B48FC)
                                        : AppColors.divider,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Opsi 2: QRIS (Non-Tunai)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onSelectMethod('qris'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'qris'
                                  ? const Color(0xFFF7F7FA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'qris'
                                    ? const Color(0xFF6B48FC)
                                    : AppColors.divider,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2_rounded,
                                    color: Color(0xFF6B48FC),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QRIS (Non-Tunai)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight:
                                              _selectedPaymentMethod == 'qris'
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                          color: const Color(0xFF17152B),
                                        ),
                                      ),
                                      Text(
                                        'Scan barcode pembayaran ke driver/resto',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          color: const Color(0xFF8E88A8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _selectedPaymentMethod == 'qris'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _selectedPaymentMethod == 'qris'
                                      ? const Color(0xFF6B48FC)
                                      : AppColors.divider,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Jika QRIS dipilih: Muncul Barcode Box & Status Verifikasi Sistem
                        if (_selectedPaymentMethod == 'qris') ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F8FD),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF6B48FC)
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Scan QRIS Pembayaran',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Nominal: Rp ${_qrisPayment?.payableAmount ?? widget.totalPrice}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B48FC),
                                  ),
                                ),
                                if (_qrisPayment != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2DCFE),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Base: Rp ${_qrisPayment!.baseAmount} • Kode Unik: +${_qrisPayment!.uniqueCode}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF4B4763),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Transfer Tepat: Rp ${_qrisPayment!.payableAmount}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF6B48FC),
                                          ),
                                        ),
                                        if (_qrisPayment!.qrisPayload.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _qrisPayment!.qrisPayload,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 9.5,
                                                      color: const Color(
                                                          0xFF6B6680),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  key: const ValueKey(
                                                      'btn_copy_qris_payload'),
                                                  onTap: () {
                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text: _qrisPayment!
                                                            .qrisPayload,
                                                      ),
                                                    );
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Payload QRIS disalin!',
                                                        ),
                                                        duration: Duration(
                                                            seconds: 1),
                                                      ),
                                                    );
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(4),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.copy_rounded,
                                                          size: 13,
                                                          color:
                                                              Color(0xFF6B48FC),
                                                        ),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'Salin',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Color(
                                                                0xFF6B48FC),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_paymentError != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _paymentError!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontSize: 10.5,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),

                                // Box QR Code
                                Container(
                                  width: 130,
                                  height: 130,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _isQrScannedAndPaid
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF6B48FC),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: _isPreparingQris
                                        ? const CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6B48FC),
                                            ),
                                          )
                                        : _isQrScannedAndPaid
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF10B981),
                                                size: 44,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Saldo Masuk & Lunas',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.qr_code_scanner_rounded,
                                                color: Color(0xFF6B48FC),
                                                size: 46,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _qrisPayment != null
                                                    ? 'Ref: ${_qrisPayment!.referenceId}'
                                                    : 'Tunjukkan ke Kasir/Driver',
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      const Color(0xFF6B6680),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Status Verifikasi Otomatis Sistem
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isQrScannedAndPaid
                                        ? const Color(0xFFE8F8F0)
                                        : const Color(0xFFF0EDFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_isQrScannedAndPaid)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF6B48FC)),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF10B981),
                                          size: 14,
                                        ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _isQrScannedAndPaid
                                              ? 'Verifikasi Pembayaran Berhasil'
                                              : 'Menunggu sistem mendeteksi pembayaran...',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _isQrScannedAndPaid
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF6B48FC),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isQrScannedAndPaid) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    key: const ValueKey('btn_check_qris_status'),
                                    onPressed: _isCheckingQris
                                        ? null
                                        : () => _checkQrisStatus(silent: false),
                                    icon: _isCheckingQris
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.refresh_rounded,
                                            size: 14),
                                    label: Text(
                                      'Cek Status Pembayaran',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _onSelectMethod('tunai'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2DCFE),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Color(0xFF6B6680),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Batal / Ganti ke Tunai',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF6B6680),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rincian Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPriceRow(
                            'Subtotal Makanan', 'Rp ${widget.subtotalPrice}'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Ongkos Kirim Driver (1.2 km)', 'Rp ${widget.deliveryFee}'),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                            'Biaya Layanan Aplikasi', 'Rp ${widget.serviceFee}'),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2DCFE)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Rp ${widget.totalPrice}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sudah termasuk PPN resto & jaminan higienis',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: const Color(0xFF6B6680)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Button: Pesan Makanan Sekarang
                  Builder(
                    builder: (context) {
                      final bool canOrder = _selectedPaymentMethod == 'tunai' ||
                          (_selectedPaymentMethod == 'qris' &&
                              _isQrScannedAndPaid);

                      return ElevatedButton(
                        onPressed:
                            (canOrder && !_isSubmittingOrder)
                                ? _handlePlaceOrderPressed
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B1832),
                          disabledBackgroundColor: const Color(0xFFCCC8E0),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isSubmittingOrder
                              ? 'Membuat Pesanan...'
                              : canOrder
                                  ? 'Pesan Makanan Sekarang Rp ${widget.totalPrice}'
                                  : 'Menunggu Pembayaran QRIS Selesai...',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
                fontSize: 11.5, color: const Color(0xFF17152B)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }
}
