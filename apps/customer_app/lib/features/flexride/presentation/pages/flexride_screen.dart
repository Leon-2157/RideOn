import 'dart:async';
import 'package:flutter/material.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
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
  const FlexRideScreen({super.key});

  @override
  State<FlexRideScreen> createState() => _FlexRideScreenState();
}

enum FlexRideState {
  inputLocation, // masuk flex ride.png
  vehicleSelect, // flex motor.png / flex mOBIL.png
  searchingDriver, // cari driver.png
  driverFound, // dapat driver.png
  driverArrived, // driver sampai.png
}

class _FlexRideScreenState extends State<FlexRideScreen> {
  FlexRideState _currentState = FlexRideState.inputLocation;
  String _selectedVehicle = 'Flex Motor';
  int _selectedVehiclePrice = 14000;

  final TextEditingController _pickupController = TextEditingController(
    text: 'Jl. Brawl No. 77, Lnad of down II',
  );
  final TextEditingController _destinationController = TextEditingController(
    text: 'Jl. Ranked No. 133, Land of down IV',
  );
  final TextEditingController _pickupNoteController = TextEditingController(
    text: 'Didepan Mesjid Al-Munawarah',
  );

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          showBackButton: true,
          initialShowDetail: true,
        ),
      ),
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
              _destinationController.text = addr;
              _currentState = FlexRideState.vehicleSelect;
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
        return Stack(
          children: [
            const SimulatedMapView(showRoute: true),
            VehicleSelectionSheet(
              destinationText:
                  'Jl.Ranked No. 133, Land of down IV (2.9 Km 12mnt)',
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
        return const Stack(
          children: [
            SimulatedMapView(showRoute: true),
            DriverSearchingView(),
          ],
        );

      case FlexRideState.driverFound:
      case FlexRideState.driverArrived:
        final isArrived = _currentState == FlexRideState.driverArrived;
        return Stack(
          children: [
            SimulatedMapView(
              showRoute: true,
              showDriver: true,
              isArrived: isArrived,
            ),
            DriverTrackingSheet(
              isArrived: isArrived,
              onChatWithDriver: _openChatWithDriver,
              onCallWithDriver: _openCallWithDriver,
              onMetDriver: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Selamat menikmati perjalanan bersama RideOn!'),
                    backgroundColor: Color(0xFF27AE60),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
    }
  }
}
