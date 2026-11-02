import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../chat/presentation/modules/call/voice_call_overlay.dart';
import '../modules/header/flexride_header.dart';
import '../modules/location_picker/location_picker_module.dart';
import '../modules/vehicle_selection/vehicle_selection_sheet.dart';
import '../modules/driver_searching/driver_searching_view.dart';
import '../modules/driver_tracking/driver_tracking_sheet.dart';
import '../modules/map/simulated_map_view.dart';

/// Halaman FlexRide strictly based on Figma nodes [44:3505], [44:5901], [44:6446], [44:6080], [44:6232]:
/// 1. Masuk Flex Ride: Character illustration, Pickup & Destination input, Quick addresses, '+ Pilih Lewat Peta Langsung'
/// 2. Flex Motor / Mobil: Real-time map backdrop with bottom sheet vehicle selection & pickup note
/// 3. Cari Driver: Radar pulse searching state
/// 4. Dapat Driver & Driver Sampai: Driver tracking (Pikri Haykal, BG 4563 R) with direct chat & call access
class FlexRideScreen extends StatefulWidget {
  final FlexRideState initialState;
  final String? initialPickup;
  final String? initialDestination;
  final String? initialNote;
  final String? initialVehicle;
  final int? initialVehiclePrice;

  const FlexRideScreen({
    super.key,
    this.initialState = FlexRideState.inputLocation,
    this.initialPickup,
    this.initialDestination,
    this.initialNote,
    this.initialVehicle,
    this.initialVehiclePrice,
  });

  @override
  State<FlexRideScreen> createState() => _FlexRideScreenState();
}

enum FlexRideState {
  inputLocation, // masuk flex ride.png
  vehicleSelect, // flex motor.png / flex mOBIL.png
  searchingDriver, // cari driver.png
  driverFound, // driver menuju lokasi (dapat driver.png)
  driverArrived, // driver sampai.png
  tripStarted, // perjalanan dimulai (dapat driver-1.png)
}

class _FlexRideScreenState extends State<FlexRideScreen> {
  late FlexRideState _currentState;
  late String _selectedVehicle;
  late int _selectedVehiclePrice;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _pickupNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    _selectedVehicle = widget.initialVehicle ?? 'Flex Motor';
    _selectedVehiclePrice = widget.initialVehiclePrice ?? 14000;

    if (widget.initialPickup != null) {
      _pickupController.text = widget.initialPickup!;
    }
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
    if (widget.initialNote != null) {
      _pickupNoteController.text = widget.initialNote!;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupNoteController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _currentState = FlexRideState.searchingDriver;
    });

    // Auto-advance matching Figma prototype
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentState == FlexRideState.searchingDriver) {
        setState(() {
          _currentState = FlexRideState.driverFound;
        });

        // Simulate driver arrived after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _currentState == FlexRideState.driverFound) {
            setState(() {
              _currentState = FlexRideState.driverArrived;
            });
          }
        });
      }
    });
  }

  void _openChatWithDriver() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          showBackButton: true,
          initialShowDetail: true,
        ),
      ),
    );
  }

  void _openCallWithDriver() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VoiceCall',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const VoiceCallOverlay();
      },
    );
  }

  void _showCompletionDialog() {
    int givenRating = 0;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SelesaikanOrderan',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool hasRated = givenRating > 0;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                      // Green check circle
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F9EE),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6CE19B),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Color(0xFF27AE60),
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'Selesaikan Orderan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F8FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE8E5F5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDetailRow('Driver', 'Fikri Haikal'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Jenis Kendaraan', _selectedVehicle),
                            const SizedBox(height: 8),
                            _buildDetailRow('Nomor Kendaraan', 'BG 4563 R'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Nama Customer', 'Muhammad Taufiq'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFECEAF5),
                              ),
                            ),
                            // Nomor Orderan (teks diperbesar & dibuat bold)
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Nomor Orderan',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF6B6680),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ORD-982184-FLX',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Biaya Orderan',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF6B6680),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rp ${_selectedVehiclePrice == 14000 ? '14.000' : '30.000'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF6B48FC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bintang Penilaian Driver
                      Text(
                        'Beri Nilai Driver',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final isFilled = starIndex <= givenRating;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                givenRating = starIndex;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 32,
                                color: isFilled
                                    ? const Color(0xFFF1C40F)
                                    : const Color(0xFFC7BCFE),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Button Selesai (hanya aktif jika user sudah memberikan bintang)
                      GestureDetector(
                        onTap: hasRated
                            ? () {
                                Navigator.of(dialogContext).pop();
                                // Kembali ke Home customer_app (Beranda)
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 46,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: hasRated
                                ? const Color(0xFF17152B)
                                : const Color(0xFFC4C2CF),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: hasRated
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Selesai',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: hasRated
                                    ? Colors.white
                                    : const Color(0xFF7E7B8E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: const Color(0xFF6B6680),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  void _handleBack() {
    if (_currentState != FlexRideState.inputLocation) {
      setState(() {
        _currentState = FlexRideState.inputLocation;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          FlexRideHeader(onBack: _handleBack),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentState) {
      case FlexRideState.inputLocation:
        return LocationPickerModule(
          pickupController: _pickupController,
          destinationController: _destinationController,
          onSelectSavedAddress: (addr) {
            setState(() {
              _pickupController.text = addr;
            });
          },
          onPickViaMap: () {
            setState(() {
              _currentState = FlexRideState.vehicleSelect;
            });
          },
          onProceedToVehicles: () {
            setState(() {
              _currentState = FlexRideState.vehicleSelect;
            });
          },
        );

      case FlexRideState.vehicleSelect:
        final pickupText = _pickupController.text.isNotEmpty
            ? _pickupController.text
            : 'Titik Jemput Kamu (Jl. Merdeka No. 45)';
        final destText = _destinationController.text.isNotEmpty
            ? _destinationController.text
            : 'Kota Krukuh (2.9 Km • 12 mnt)';
        return Stack(
          children: [
            const SimulatedMapView(showRoute: true),
            VehicleSelectionSheet(
              pickupText: pickupText,
              destinationText: destText,
              selectedVehicle: _selectedVehicle,
              selectedVehiclePrice: _selectedVehiclePrice,
              pickupNoteController: _pickupNoteController,
              onSelectVehicle: (vehicle, price) {
                setState(() {
                  _selectedVehicle = vehicle;
                  _selectedVehiclePrice = price;
                });
              },
              onOrder: _startSearch,
            ),
          ],
        );

      case FlexRideState.searchingDriver:
        return Stack(
          children: [
            const SimulatedMapView(showRoute: true),
            DriverSearchingView(
              vehicleName: _selectedVehicle,
              vehiclePrice: _selectedVehiclePrice,
              destination: 'Pasar Krukuh',
              onCancel: () {
                setState(() {
                  _currentState = FlexRideState.vehicleSelect;
                });
              },
            ),
          ],
        );

      case FlexRideState.driverFound:
      case FlexRideState.driverArrived:
      case FlexRideState.tripStarted:
        final bool isArrived = _currentState == FlexRideState.driverArrived;
        final bool isTripStarted = _currentState == FlexRideState.tripStarted;

        return Stack(
          children: [
            SimulatedMapView(
              showRoute: true,
              showDriver: true,
              isArrived: isArrived,
            ),
            DriverTrackingSheet(
              isArrived: isArrived,
              isTripStarted: isTripStarted,
              onChatWithDriver: _openChatWithDriver,
              onCallWithDriver: _openCallWithDriver,
              onMetDriver: () {
                // Saat user menekan 'Saya sudah Bertemu Driver', masuk ke status dalam perjalanan
                setState(() {
                  _currentState = FlexRideState.tripStarted;
                });
              },
              onCompleteOrder: _showCompletionDialog,
            ),
          ],
        );
    }
  }
}
