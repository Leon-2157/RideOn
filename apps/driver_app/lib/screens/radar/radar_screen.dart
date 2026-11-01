import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/driver_service.dart';
import '../../services/location_service.dart';
import '../account_settings/account_settings_screen.dart';
import '../activity/activity_list_screen.dart';
import '../chat/chat_detail_screen.dart';
import '../chat/chat_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../wallet/widgets/dashed_border_container.dart';
import 'radar_flex_food_screen.dart';
import 'radar_flex_send_screen.dart';

/// Enum Status Layar Radar Driver
enum RadarOrderState {
  dashboard, // Figma: dasboard driver 1.png & dasboard driver.png
  searching, // Menunggu / mencari orderan
  incoming, // Ada orderan masuk (tampil bottom sheet konfirmasi)
  accepted, // Orderan diterima, menuju penjemputan & pengantaran
  completed, // Orderan selesai (dialog rincian)
}

/// Model Data Mock Orderan Masuk yang Bergiliran (FlexRide, FlexFood, FlexSend)
class RadarMockOrder {
  final String serviceBadge;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String customerName;
  final String fareText;
  final String pickupAddress;
  final String destinationAddress;
  final String tripDetails;
  final String serviceType;
  final String safetyReminder;
  final IconData customerIcon;
  final String transactionId;
  final String transactionFare;

  const RadarMockOrder({
    required this.serviceBadge,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.customerName,
    required this.fareText,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.tripDetails,
    required this.serviceType,
    required this.safetyReminder,
    required this.customerIcon,
    required this.transactionId,
    required this.transactionFare,
  });
}

/// [RadarScreen]
/// Implementasi Layar Radar & Order FlexRide Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanRadarFlexRide/radar driver.png (Mode searching & status online)
/// - Figma/HalamanRadarFlexRide/orderan penumpang.png (Modal orderan masuk)
/// - Figma/HalamanRadarFlexRide/orderan penumpang 3 d.png (Countdown penerimaan order)
/// - Figma/HalamanRadarFlexRide/radar driver-1.png & radar driver-2.png (Orderan diterima & chat)
/// - Figma/HalamanRadarFlexRide/iPhone 14 & 15 Pro - 21.png (Dialog penyelesaian orderan)
class RadarScreen extends StatefulWidget {
  final String driverName;
  final String plateNumber;
  final bool initialIsOnline;
  final RadarOrderState initialOrderState;
  final bool enableRadarAnimation;
  final ValueChanged<int>? onTabSelected;
  final DriverService? driverService;
  final LocationService? locationService;
  final bool? enableGpsTracking;
  final Future<void> Function(String address)? onOpenMaps;
  final int initialOrderIndex;
  final bool? enableAutoOrderSimulation;

  const RadarScreen({
    super.key,
    this.driverName = 'Joni utama',
    this.plateNumber = 'BK 4892 ABC',
    this.initialIsOnline = true,
    this.initialOrderState = RadarOrderState.searching,
    this.enableRadarAnimation = true,
    this.onTabSelected,
    this.driverService,
    this.locationService,
    this.enableGpsTracking,
    this.onOpenMaps,
    this.initialOrderIndex = 0,
    this.enableAutoOrderSimulation,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
  late bool _isOnline;
  late RadarOrderState _orderState;
  int _currentTabIndex = 0; // Default: Tab 0 (Radar)

  late final DriverService _driverService;
  late final LocationService _locationService;
  Position? _currentPosition;

  // Radar Animation Controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Countdown timer untuk orderan masuk
  int _countdownSeconds = 16;
  Timer? _countdownTimer;

  int _currentOrderIndex = 0;
  Timer? _autoOrderTimer;

  static const List<RadarMockOrder> _mockOrders = [
    // 1. Antar Penumpang (FlexRide)
    RadarMockOrder(
      serviceBadge: 'ANTAR PENUMPANG',
      badgeBgColor: Color(0xFFC6BCFF),
      badgeTextColor: Color(0xFF4C2DF2),
      customerName: 'M.Topik',
      fareText: 'Ongkir: Rp 35.000',
      pickupAddress: 'Jl.Seulawah no 10 PIM',
      destinationAddress: 'Suzuya Mall Lhokseumawe',
      tripDetails: 'Jarak Jemput: 2.9km Jarak Antar: 18 km Estimasi: 25 mnt',
      serviceType: 'FLEXRIDE',
      safetyReminder:
          'Pastikan penumpang sudah memakai helm standar sebelum melaju.',
      customerIcon: Icons.person,
      transactionId: '#I2E4S67',
      transactionFare: 'Rp 183.000',
    ),
    // 2. Pesan Makanan (FlexFood)
    RadarMockOrder(
      serviceBadge: 'PESAN MAKANAN',
      badgeBgColor: Color(0xFFFFE0B2),
      badgeTextColor: Color(0xFFE65100),
      customerName: 'Waroeng Bamboe (Fikri)',
      fareText: 'Ongkir: Rp 15.000',
      pickupAddress: 'Waroeng Bamboe, Jl. Merdeka',
      destinationAddress: 'Jl. Dumai, ARUN No. 101 (Fikri)',
      tripDetails: 'Jarak Resto: 1.2km Jarak Antar: 3.0 km Estimasi: 12 mnt',
      serviceType: 'FLEXFOOD',
      safetyReminder:
          'Pastikan pesanan makanan tersegel rapi dan sesuai struk resto.',
      customerIcon: Icons.fastfood_rounded,
      transactionId: '#F9B2D41',
      transactionFare: 'Rp 15.000',
    ),
    // 3. Titip Belanja (FlexSend)
    RadarMockOrder(
      serviceBadge: 'TITIP BELANJA',
      badgeBgColor: Color(0xFFE0F2F1),
      badgeTextColor: Color(0xFF00897B),
      customerName: 'Gufran (Titip Belanja)',
      fareText: 'Ongkir: Rp 25.000',
      pickupAddress: 'Pasar Pagi Batuphat & Apotik',
      destinationAddress: 'Jl. Lauser No. 45 (Gufran)',
      tripDetails: 'Jarak Toko: 2.1km Jarak Antar: 3.4 km Estimasi: 20 mnt',
      serviceType: 'FLEXSEND',
      safetyReminder:
          'Periksa kembali nota belanja dan barang titipan sebelum diantar.',
      customerIcon: Icons.shopping_bag_rounded,
      transactionId: '#S8K1L90',
      transactionFare: 'Rp 25.000',
    ),
  ];

  RadarMockOrder get _currentOrder => _mockOrders[_currentOrderIndex];
  String get _passengerName => _currentOrder.customerName;
  String get _fareText => _currentOrder.fareText;
  String get _pickupAddress => _currentOrder.pickupAddress;
  String get _destinationAddress => _currentOrder.destinationAddress;
  String get _tripDetails => _currentOrder.tripDetails;

  // Modal Kas Talangan State Sesuai Figma dasboard driver 1.png & dasboard driver.png
  String _cashLimit = 'Rp 200.000';

  @override
  void initState() {
    super.initState();
    _currentOrderIndex = widget.initialOrderIndex % _mockOrders.length;
    _isOnline = widget.initialIsOnline;
    _orderState = widget.initialIsOnline
        ? widget.initialOrderState
        : RadarOrderState.dashboard;

    _driverService = widget.driverService ?? DriverService();
    _locationService = widget.locationService ?? LocationService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.enableRadarAnimation && _isOnline && _orderState != RadarOrderState.dashboard) {
      _pulseController.repeat();
    }

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    _countdownSeconds = _currentOrder.serviceType == 'FLEXSEND' ? 18 : 16;
    if (_orderState == RadarOrderState.incoming && widget.enableRadarAnimation) {
      _startCountdown();
    }

    final shouldTrack =
        widget.enableGpsTracking ?? widget.enableRadarAnimation;
    if (_isOnline && shouldTrack) {
      _driverService.setDriverPresence(true);
      _startLocationTracking();
    }

    if (_isOnline && _orderState == RadarOrderState.searching) {
      _scheduleNextAutoOrder();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _autoOrderTimer?.cancel();
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  void _scheduleNextAutoOrder() {
    _autoOrderTimer?.cancel();
    final shouldAuto = widget.enableAutoOrderSimulation ?? false;
    if (!_isOnline || !shouldAuto || _orderState != RadarOrderState.searching) {
      return;
    }

    _autoOrderTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || !_isOnline || _orderState != RadarOrderState.searching) {
        return;
      }
      _triggerSimulateIncomingOrder();
    });
  }

  void _startLocationTracking() {
    _locationService.startLocationUpdates(
      onLocationChanged: (Position position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
        });
        _driverService.updateDriverLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          isOnline: _isOnline,
          serviceType: _currentOrder.serviceType,
        );
      },
    );
  }

  void _stopLocationTracking() {
    _locationService.stopLocationUpdates();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = _currentOrder.serviceType == 'FLEXSEND' ? 18 : 16;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        _rejectOrder();
      }
    });
  }

  void _toggleOnlineStatus(bool value) {
    setState(() {
      _isOnline = value;
      if (!_isOnline) {
        _orderState = RadarOrderState.dashboard;
        _pulseController.stop();
        _countdownTimer?.cancel();
        _autoOrderTimer?.cancel();
        _stopLocationTracking();
        _driverService.setDriverPresence(false);
        _driverService.updateDriverLocation(
          latitude: _currentPosition?.latitude ?? 0.0,
          longitude: _currentPosition?.longitude ?? 0.0,
          heading: _currentPosition?.heading ?? 0.0,
          isOnline: false,
          serviceType: _currentOrder.serviceType,
        );
      } else {
        _driverService.setDriverPresence(true);
        if (widget.enableRadarAnimation &&
            _orderState != RadarOrderState.dashboard) {
          _pulseController.repeat();
        }
        final shouldTrack =
            widget.enableGpsTracking ?? widget.enableRadarAnimation;
        if (shouldTrack) {
          _startLocationTracking();
        }
        if (_orderState == RadarOrderState.searching) {
          _scheduleNextAutoOrder();
        }
      }
    });
  }

  void _acceptOrder() {
    _countdownTimer?.cancel();
    _autoOrderTimer?.cancel();

    if (_currentOrder.serviceType == 'FLEXFOOD') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RadarFlexFoodScreen(
            initialOrderState: FlexFoodOrderState.pickupPin,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _orderState = RadarOrderState.searching;
            _currentOrderIndex = (_currentOrderIndex + 1) % _mockOrders.length;
          });
          _scheduleNextAutoOrder();
        }
      });
      return;
    }

    if (_currentOrder.serviceType == 'FLEXSEND') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RadarFlexSendScreen(
            initialOrderState: FlexSendOrderState.shoppingChecklist,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _orderState = RadarOrderState.searching;
            _currentOrderIndex = (_currentOrderIndex + 1) % _mockOrders.length;
          });
          _scheduleNextAutoOrder();
        }
      });
      return;
    }

    setState(() {
      _orderState = RadarOrderState.accepted;
    });
  }

  void _rejectOrder() {
    _countdownTimer?.cancel();
    _autoOrderTimer?.cancel();
    setState(() {
      _orderState = RadarOrderState.searching;
      _currentOrderIndex = (_currentOrderIndex + 1) % _mockOrders.length;
    });
    _scheduleNextAutoOrder();
  }

  void _triggerSimulateIncomingOrder() {
    if (!_isOnline) return;
    _autoOrderTimer?.cancel();
    setState(() {
      _orderState = RadarOrderState.incoming;
      _countdownSeconds = _currentOrder.serviceType == 'FLEXSEND' ? 18 : 16;
    });
    _startCountdown();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: AppColors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Centang Hijau
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF81C784),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF2E7D32),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Judul
                const Text(
                  'Selesaikan Orderan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Barang telah diantarkan dengan selamat, tekan tombol selesai untuk kembali keradar dan mencari orderan baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E6A8A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Kotak Rincian Transaksi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F6FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E5FB)),
                  ),
                  child: Column(
                    children: [
                      _buildDialogRow('ID Transaksi', _currentOrder.transactionId),
                      const SizedBox(height: 8),
                      _buildDialogRow('Tanggal & Jam', '5 Okt 2026 13:02 WIB'),
                      const SizedBox(height: 8),
                      _buildDialogRow('Biaya', _currentOrder.transactionFare, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol Selesai
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _orderState = RadarOrderState.searching;
                        _currentOrderIndex =
                            (_currentOrderIndex + 1) % _mockOrders.length;
                      });
                      _scheduleNextAutoOrder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

  Widget _buildDialogRow(String title, String val, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6A8A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            val,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isBold ? 15 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentTabIndex) return;

    setState(() {
      _currentTabIndex = index;
    });

    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacement(
        _createNavBarRoute(const ActivityListScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        _createNavBarRoute(const WalletScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        _createNavBarRoute(const ChatHistoryScreen()),
      );
    }
  }

  PageRouteBuilder<dynamic> _createNavBarRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      body: Stack(
        children: [
          // Background Gradient Soft Purple untuk Dashboard (Figma: dasboard driver 1.png)
          if (_orderState == RadarOrderState.dashboard)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE5DEFF),
                      Color(0xFFF7F6FE),
                      Colors.white,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

          // 1. Layer Peta Satelit / Background Radar (Hanya saat bukan mode dashboard)
          if (_orderState != RadarOrderState.dashboard)
            Positioned.fill(
              child: _buildMapBackground(),
            ),

          // 2. Lingkaran Animasi Gelombang Radar (Pulsing Circle)
          if (_isOnline && _orderState != RadarOrderState.dashboard)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: _buildRadarPulseAnimation(),
                ),
              ),
            ),

          // 3. Hotspot Badge "Area sibuk" di Peta
          if (_isOnline && _orderState == RadarOrderState.searching)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.48,
              child: Center(
                child: _buildBusyAreaBadge(),
              ),
            ),

          // Konten Dashboard Utama (Figma: dasboard driver 1.png & dasboard driver.png)
          if (_orderState == RadarOrderState.dashboard)
            Positioned.fill(
              bottom: 60.0 + MediaQuery.of(context).padding.bottom,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    children: [
                      _buildTopHeaderRow(),
                      const SizedBox(height: 12),
                      _buildOnlineStatusCard(),
                      const SizedBox(height: 16),
                      _buildProteksiTalanganCard(),
                      const SizedBox(height: 16),
                      _buildDailyIncomeCard(),
                      const SizedBox(height: 24),
                      if (_isOnline) _buildOpenRadarButton(),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Header Top Cards pada Mode Map / Radar
          if (_orderState != RadarOrderState.dashboard)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopHeaderRow(),
                      const SizedBox(height: 12),
                      _buildOnlineStatusCard(),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Floating Bottom Searching Pill atau Order Sheet (hanya saat mode map / radar)
          if (_orderState != RadarOrderState.dashboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70.0 + MediaQuery.of(context).padding.bottom, // Di atas Bottom Navigation Bar dengan margin pas
              child: _buildBottomOrderContent(),
            ),

          // 6. Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  /// 1. Tampilan Background Peta
  Widget _buildMapBackground() {
    return Image.asset(
      'assets/images/radar_driver_map.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF2C392D),
          child: const Center(
            child: Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.white24,
            ),
          ),
        );
      },
    );
  }

  /// 2. Gelombang Animasi Radar
  Widget _buildRadarPulseAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Gelombang Luar
            Container(
              width: 260 * _pulseAnimation.value,
              height: 260 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B68FC).withValues(
                    alpha: 1.0 - _pulseAnimation.value,
                  ),
                  width: 2,
                ),
              ),
            ),
            // Gelombang Tengah Hijau
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.6),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            // Lingkaran Ungu Dalam
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFB4A1FF),
                  width: 1.5,
                ),
              ),
            ),
            // Pin Lokasi Driver (Titik Hijau Menyala)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF66),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF66).withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 3. Badge "Area sibuk"
  Widget _buildBusyAreaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Signal Kuning Oranye
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD54F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFFE65100),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Area sibuk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Top Header Row: Profile Pill & GPS SIAP Pill
  Widget _buildTopHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pill Driver Profile (Klik untuk buka Pengaturan Akun)
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9E84FD), Color(0xFFBCA6FF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Driver
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/driver_avatar.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: const Color(0xFF6B48FC),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            widget.plateNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF352B58),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Pill GPS SIAP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9E84FD), Color(0xFFBCA6FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GPS SIAP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.location_on,
                color: Color(0xFF6B48FC),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Status Online / Offline Switch Card
  Widget _buildOnlineStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline
              ? [const Color(0xFFA58BFF), const Color(0xFFBCA6FF)]
              : [const Color(0xFFD6CEFE), const Color(0xFFE5DEFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indikator Status & Teks
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isOnline
                          ? AppColors.onlineGreen.withValues(alpha: 0.35)
                          : const Color(0xFF9E9E9E),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppColors.onlineGreen
                            : const Color(0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOnline
                            ? 'Status: Online'
                            : 'Status: OFFLINE (Istirahat)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _isOnline
                              ? AppColors.onlineGreenDark
                              : const Color(0xFF17152B),
                        ),
                      ),
                      Text(
                        _isOnline
                            ? 'Geser tombol untuk off'
                            : 'Geser tombol untuk mulai cari order',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3E3660),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Switch Tombol On / Off
          Switch(
            value: _isOnline,
            onChanged: _toggleOnlineStatus,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.onlineGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  /// Card Proteksi Talangan (Figma: dasboard driver 1.png & dasboard driver.png)
  Widget _buildProteksiTalanganCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC6BCFF).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Pill Putih: PROTEKSI TALANGAN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'PROTEKSI TALANGAN',
              style: TextStyle(
                color: Color(0xFF6B48FC),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Modal Kas Belanja Hari Ini',
            style: TextStyle(
              color: Color(0xFF17152B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Nominal Besar
          Text(
            _cashLimit,
            style: const TextStyle(
              color: Color(0xFF17152B),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),

          const Text(
            'Sistem hanya akan memberi order titip belanja dengan total nota kas belanja anda. Tidak dipaksa menalangi lebih.',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Garis Putus-putus: Atur Batas Modal Kas Belanja ->
          InkWell(
            onTap: _showAturModalKasSheet,
            borderRadius: BorderRadius.circular(16),
            child: DashedBorderContainer(
              borderRadius: 16,
              strokeColor: const Color(0xFF6B48FC),
              strokeWidth: 1.5,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Center(
                child: Text(
                  'Atur Batas Modal Kas Belanja ->',
                  style: TextStyle(
                    color: Color(0xFF6B48FC),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Pendapatan Bersih Hari Ini (Figma: dasboard driver 1.png & dasboard driver.png)
  Widget _buildDailyIncomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pendapatan Bersih Hari Ini',
                  style: TextStyle(
                    color: Color(0xFF6B48FC),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '5 Okt 2026',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Rp 0',
            style: TextStyle(
              color: Color(0xFF17152B),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),

          const Text(
            'Belum ada trip hari ini',
            style: TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),

          const Text(
            'Trip Selesai: 0 Order',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol Buka Radar Maps Sekarang (Figma: dasboard driver.png)
  Widget _buildOpenRadarButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _orderState = RadarOrderState.searching;
          if (widget.enableRadarAnimation) {
            _pulseController.repeat();
          }
        });
        _scheduleNextAutoOrder();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: Color(0xFF6B48FC),
              size: 20,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Buka radar maps sekarang',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF17152B),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal Bottom Sheet Atur Modal Kas Belanja (Figma: atur batas modal kas.png)
  void _showAturModalKasSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedAmount = _cashLimit;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF533EC4),
                    Color(0xFF7A64E8),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    const Text(
                      'ATUR MODAL KAS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Berapa uang tunai yang Anda bawa di saku hari ini untuk membelanjakan titipan customer ?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Input Box Display Nominal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        selectedAmount,
                        style: const TextStyle(
                          color: Color(0xFF17152B),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan Cepat Nominal (Rp 200.000 & Rp 300.000 Maks)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedAmount = 'Rp 200.000';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAmount == 'Rp 200.000'
                                      ? const Color(0xFF6B48FC)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Rp 200.000',
                                  style: TextStyle(
                                    color: Color(0xFF6B48FC),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedAmount = 'Rp 300.000';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAmount == 'Rp 300.000'
                                      ? const Color(0xFF6B48FC)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Rp 300.000 (Maks)',
                                  style: TextStyle(
                                    color: Color(0xFF6B48FC),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tombol Input Manual
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Input Manual',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan Perubahan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cashLimit = selectedAmount;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17152B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 5. Konten Bawah (Searching Pill / Incoming Order Sheet / Accepted Sheet)
  Widget _buildBottomOrderContent() {
    if (!_isOnline) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Anda sedang Offline. Aktifkan status untuk bekerja.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6E6A8A),
              ),
            ),
          ),
        ),
      );
    }

    switch (_orderState) {
      case RadarOrderState.dashboard:
        return const SizedBox.shrink();
      case RadarOrderState.searching:
        return _buildSearchingCard();
      case RadarOrderState.incoming:
        return _buildIncomingOrderSheet();
      case RadarOrderState.accepted:
        return _buildAcceptedOrderSheet();
      case RadarOrderState.completed:
        return const SizedBox.shrink();
    }
  }

  /// Floating White Card: "Mencari orderan terbaik..."
  Widget _buildSearchingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _triggerSimulateIncomingOrder, // Memudahkan simulasi order masuk
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: widget.enableRadarAnimation
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6B48FC)),
                      )
                    : const CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6B48FC)),
                      ),
              ),
              const SizedBox(width: 14),
              const Flexible(
                child: Text(
                  'Mencari orderan terbaik...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modal / Bottom Sheet Orderan Masuk (Sesuai masing-masing layanan di Figma)
  Widget _buildIncomingOrderSheet() {
    switch (_currentOrder.serviceType) {
      case 'FLEXFOOD':
        return _buildFlexFoodIncomingSheet();
      case 'FLEXSEND':
        return _buildFlexSendIncomingSheet();
      case 'FLEXRIDE':
      default:
        return _buildFlexRideIncomingSheet();
    }
  }

  /// 1. Modal Orderan Antar Penumpang (FlexRide)
  /// Sesuai Figma/HalamanRadarFlexRide/orderan penumpang.png & orderan penumpang 3 d.png
  /// Menerima dan menolak pesanan menggunakan DUA SLIDER GESER (Swipe Action) berlawanan arah.
  Widget _buildFlexRideIncomingSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF635698).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar Putih
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Badge & Countdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _currentOrder.badgeBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentOrder.serviceBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _currentOrder.badgeTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_countdownSeconds Detik',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _countdownSeconds <= 3
                          ? const Color(0xFFFF3B30)
                          : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Kartu Putih Rincian Penumpang
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil & Ongkir
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6B48FC),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Icon(
                            _currentOrder.customerIcon,
                            color: const Color(0xFF6B48FC),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _passengerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B68FC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _fareText,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00FF66),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Titik Jemput
                  _buildLocationRow(
                    icon: Icons.radio_button_checked,
                    iconColor: const Color(0xFF00C853),
                    title: 'Titik jemput : $_pickupAddress',
                    mapsKey: const Key('btn_maps_pickup'),
                    onMapsTap: () => _openMaps(_pickupAddress),
                  ),
                  const SizedBox(height: 8),

                  // Titik Tujuan
                  _buildLocationRow(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFF6B48FC),
                    title: 'Tujuan: $_destinationAddress',
                    mapsKey: const Key('btn_maps_destination'),
                    onMapsTap: () => _openMaps(_destinationAddress),
                  ),
                  const SizedBox(height: 10),

                  // Info Jarak & Estimasi
                  Text(
                    _tripDetails,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E6A8A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Geser / Aksi Menerima Orderan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSwipeActionButton(
              text: 'Geser untuk menerima orderan ->',
              isAccept: true,
              onAction: _acceptOrder,
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Geser / Aksi Menolak Orderan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSwipeActionButton(
              text: '<- Geser untuk menolak orderan',
              isAccept: false,
              onAction: _rejectOrder,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  /// 2. Modal Orderan Pesan Makanan (FlexFood)
  /// Sesuai Figma/HalamanRadarFlexFood/pemesanan makanan.png
  /// Menerima dan menolak pesanan menggunakan DUA TOMBOL TAP BERDAMPINGAN (SKIP>> & Terima Order Belanja).
  Widget _buildFlexFoodIncomingSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF635698).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar Putih
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Pill Hitam Atas: ORDERAN BARU MASUK!
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF17152B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ORDERAN BARU MASUK!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Header Kategori & Waktu (PESAN MAKANAN - 16 Detik)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PESAN MAKANAN',
                    style: TextStyle(
                      color: Color(0xFF6B48FC),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$_countdownSeconds Detik',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Kartu Putih 1: Pendapatan Bersih & Non-Tunai
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pendapatan Bersih',
                          style: TextStyle(
                            color: Color(0xFF00A859),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rp 15.000',
                          style: TextStyle(
                            color: Color(0xFF00A859),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F8EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00C853)),
                    ),
                    child: const Text(
                      'Non-Tunai (E-Wallet)',
                      style: TextStyle(
                        color: Color(0xFF008940),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Kartu Putih 2: Rute Resto & Lokasi Antar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titik Resto
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF00C853),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Waroeng Bamboe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF17152B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _buildMapsBadge(
                        key: const Key('btn_maps_food_resto'),
                        onTap: () => _openMaps('Waroeng Bamboe, Jl. Merdeka'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Titik Antar
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF6B48FC),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Jl. Dumai, ARUN No. 101 (Fikri)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _buildMapsBadge(
                        key: const Key('btn_maps_food_dest'),
                        onTap: () =>
                            _openMaps('Jl. Dumai, ARUN No. 101 (Fikri)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 4),

                  // Total Jarak Tempuh
                  const Text(
                    'Total Jarak Tempuh: 4.2 km Estimasi: 10 menit',
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Action Buttons: SKIP>> & Terima Order Belanja
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // SKIP>> Button (Tolak Order Makanan)
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('btn_skip_food'),
                      onTap: _rejectOrder,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'SKIP>>',
                            style: TextStyle(
                              color: Color(0xFF6B48FC),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Terima Order Belanja Button (Terima Order Makanan)
                Expanded(
                  flex: 3,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('btn_accept_food'),
                      onTap: _acceptOrder,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Terima Order Belanja',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  /// 3. Modal Orderan Titip Belanja (FlexSend)
  /// Sesuai Figma/HalamanRadarFlexSend/Orderan masuk.png & Orderan masuk (waktu hampir habis).png
  /// Menerima dan menolak pesanan menggunakan DUA TOMBOL TAP BERDAMPINGAN (SKIP>> & Terima Order Belanja)
  /// serta menampilkan banner peringatan saat waktu hampir habis (<= 10 detik).
  Widget _buildFlexSendIncomingSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF635698).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar Putih
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Banner Waktu Kritis jika <= 10 detik, atau Pill ORDERAN BARU MASUK!
          if (_countdownSeconds <= 10)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDADA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Waktu hampir habis! Orderan akan otomatis dialihkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8A1F1D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF17152B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ORDERAN BARU MASUK!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Header Kategori & Waktu (TITIP BELANJA - 18 Detik)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.shopping_bag_rounded,
                        color: Color(0xFF6B48FC),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'TITIP BELANJA',
                        style: TextStyle(
                          color: Color(0xFF6B48FC),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _countdownSeconds <= 10
                        ? const Color(0xFFFFDADA)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_countdownSeconds Detik',
                    style: TextStyle(
                      color: _countdownSeconds <= 10
                          ? const Color(0xFF8A1F1D)
                          : const Color(0xFF17152B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Dua Kartu Berdampingan (Pendapatan Bersih & Estimasi Talangan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pendapatan Bersih',
                          style: TextStyle(
                            color: Color(0xFF00A859),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rp 15.000',
                          style: TextStyle(
                            color: Color(0xFF00A859),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ongkir rute + kuota item',
                          style: TextStyle(
                            color: Color(0xFF00A859),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Estimasi Talangan',
                          style: TextStyle(
                            color: Color(0xFF6B48FC),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rp 180.000',
                          style: TextStyle(
                            color: Color(0xFF6B48FC),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sesuai modal kas driver',
                          style: TextStyle(
                            color: Color(0xFF00A859),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Kartu Rute Multi-Toko & Antar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Pajak batuphat (4 Item)',
                          style: TextStyle(
                            color: Color(0xFF17152B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildMapsBadge(
                        key: const Key('btn_maps_send_stop1'),
                        onTap: () => _openMaps('Pajak batuphat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Apotek Kimia Farma (1 Item)',
                          style: TextStyle(
                            color: Color(0xFF17152B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildMapsBadge(
                        key: const Key('btn_maps_send_stop2'),
                        onTap: () => _openMaps('Apotek Kimia Farma'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Jl. Lauser, PIM No. 88 (Gufran)',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildMapsBadge(
                        key: const Key('btn_maps_send_dest'),
                        onTap: () =>
                            _openMaps('Jl. Lauser, PIM No. 88 (Gufran)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 4),
                  const Text(
                    'Total Jarak Tempuh: 4.2 km Estimasi: 10 menit',
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Aksi: SKIP>> & Terima Order Belanja
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('btn_skip_send'),
                      onTap: _rejectOrder,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF6B48FC)),
                        ),
                        child: const Center(
                          child: Text(
                            'SKIP>>',
                            style: TextStyle(
                              color: Color(0xFF6B48FC),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('btn_accept_send'),
                      onTap: _acceptOrder,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Terima Order Belanja',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  /// Helper Badge "Klik Maps" Ringkas
  Widget _buildMapsBadge({required Key key, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F8EE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Klik Maps',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00B14F),
            ),
          ),
        ),
      ),
    );
  }

  /// Buka aplikasi Google Maps atau peta eksternal langsung menuju alamat target
  Future<void> _openMaps(String address) async {
    if (widget.onOpenMaps != null) {
      await widget.onOpenMaps!(address);
      return;
    }

    final encoded = Uri.encodeComponent(address);
    final geoUri = Uri.parse('geo:0,0?q=$encoded');
    final googleMapsAppUri = Uri.parse('google.navigation:q=$encoded');
    final googleMapsWebUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

    try {
      // 1. Coba navigasi intent langsung ke aplikasi Google Maps
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(googleMapsAppUri, mode: LaunchMode.externalApplication);
        return;
      }
      // 2. Coba geo URI viewer
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      // 3. Fallback web URL Google Maps
      if (await canLaunchUrl(googleMapsWebUri)) {
        await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(googleMapsWebUri);
    } catch (e) {
      debugPrint('Tidak dapat membuka Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka Google Maps untuk: $address'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : 'RO';
  }

  /// Baris Titik Lokasi dengan Tombol "Klik Maps"
  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onMapsTap,
    Key? mapsKey,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMapsTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: mapsKey,
                  onTap: onMapsTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F8EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Klik Maps',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00B14F),
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
  }

  /// Slider / Button Geser Orderan
  Widget _buildSwipeActionButton({
    required String text,
    required bool isAccept,
    required VoidCallback onAction,
  }) {
    return SwipeActionButton(
      text: text,
      isAccept: isAccept,
      onAction: onAction,
    );
  }

  /// Sheet Setelah Orderan Diterima (Sesuai Figma radar driver-1.png & radar driver-2.png)
  Widget _buildAcceptedOrderSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF635698).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar Putih
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _currentOrder.badgeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _currentOrder.serviceBadge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _currentOrder.badgeTextColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Kartu Putih Rincian Penumpang
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil & Ongkir
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6B48FC),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Icon(
                            _currentOrder.customerIcon,
                            color: const Color(0xFF6B48FC),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _passengerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B68FC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _fareText,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00FF66),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Titik Jemput
                  _buildLocationRow(
                    icon: Icons.radio_button_checked,
                    iconColor: const Color(0xFF00C853),
                    title: 'Titik jemput : $_pickupAddress',
                    mapsKey: const Key('btn_maps_pickup'),
                    onMapsTap: () => _openMaps(_pickupAddress),
                  ),
                  const SizedBox(height: 8),

                  // Titik Tujuan
                  _buildLocationRow(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFF6B48FC),
                    title: 'Tujuan: $_destinationAddress',
                    mapsKey: const Key('btn_maps_destination'),
                    onMapsTap: () => _openMaps(_destinationAddress),
                  ),
                  const SizedBox(height: 10),

                  // Info Jarak
                  Text(
                    _tripDetails,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E6A8A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Banner Pengingat Sesuai Layanan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _currentOrder.safetyReminder,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B48FC),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Chat & Tombol Selesaikan Pengantaran
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              customerName: _currentOrder.customerName,
                              avatarInitials: _getInitials(_currentOrder.customerName),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_rounded,
                              color: Color(0xFFC6BCFF),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Masuk kehalaman chat',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Selesaikan Pengantaran
                ElevatedButton(
                  onPressed: _showCompletionDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  /// 6. Bottom Navigation Bar Sesuai Desain Figma
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Radar (Active)
              _buildNavItem(
                index: 0,
                icon: Icons.radar,
                label: 'Radar',
              ),
              // 2. Aktivitas
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Aktivitas',
              ),
              // 3. Dompet
              _buildNavItem(
                index: 2,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Dompet',
              ),
              // 4. Chat
              _buildNavItem(
                index: 3,
                icon: Icons.chat_bubble_rounded,
                label: 'chat',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _currentTabIndex == index;
    final Color itemColor =
        isActive ? const Color(0xFFC6BCFF) : AppColors.white.withValues(alpha: 0.6);

    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: itemColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [SwipeActionButton]
/// Komponen Tombol Geser Interaktif (Swipe to Action)
/// Mendukung gesture drag horizontal real-time dengan animasi translasi knob,
/// visual track highlight saat digeser, spring-back animation saat dilepas sebelum tuntas,
/// haptic feedback, serta trigger aksi saat knob digeser tuntas (>= 60%) atau ditap.
class SwipeActionButton extends StatefulWidget {
  final String text;
  final bool isAccept;
  final VoidCallback onAction;

  const SwipeActionButton({
    super.key,
    required this.text,
    required this.isAccept,
    required this.onAction,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Animation<double>? _slideAnimation;

  double _dragOffset = 0.0;
  bool _isCompleted = false;

  static const double _knobSize = 36.0;
  static const double _horizontalPadding = 10.0;
  static const double _buttonHeight = 52.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animController.addListener(() {
      if (_slideAnimation != null) {
        setState(() {
          _dragOffset = _slideAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_isCompleted) return;
    if (_animController.isAnimating) {
      _animController.stop();
    }
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDistance) {
    if (_isCompleted || maxDistance <= 0) return;
    setState(() {
      if (widget.isAccept) {
        // Geser ke kanan (drag ke kanan menambah offset)
        _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, maxDistance);
      } else {
        // Geser ke kiri (drag ke kiri delta negatif, offset bertambah)
        _dragOffset = (_dragOffset - details.primaryDelta!).clamp(0.0, maxDistance);
      }
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDistance) {
    if (_isCompleted || maxDistance <= 0) return;
    final progress = _dragOffset / maxDistance;
    final velocity = details.primaryVelocity ?? 0.0;

    final bool swipedFast = widget.isAccept
        ? (velocity > 250 && progress > 0.15)
        : (velocity < -250 && progress > 0.15);

    if (progress >= 0.60 || swipedFast) {
      HapticFeedback.mediumImpact();
      _completeAction(maxDistance);
    } else {
      _animateBack();
    }
  }

  void _completeAction(double maxDistance) {
    _isCompleted = true;
    _slideAnimation = Tween<double>(begin: _dragOffset, end: maxDistance).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        widget.onAction();
      }
    });
  }

  void _animateBack() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0.0);
  }

  void _onTap(double maxDistance) {
    if (_isCompleted || maxDistance <= 0) return;
    HapticFeedback.lightImpact();
    _completeAction(maxDistance);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDistance = (totalWidth - _knobSize - (_horizontalPadding * 2)).clamp(0.0, double.infinity);
        final progress = maxDistance > 0 ? (_dragOffset / maxDistance).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTap(maxDistance),
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDistance),
          onHorizontalDragEnd: (details) => _onDragEnd(details, maxDistance),
          onHorizontalDragCancel: _animateBack,
          child: Container(
            height: _buttonHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF17152B),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Highlight track saat digeser
                if (widget.isAccept && _dragOffset > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _horizontalPadding + _dragOffset + (_knobSize / 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B48FC).withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                if (!widget.isAccept && _dragOffset > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: _horizontalPadding + _dragOffset + (_knobSize / 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B48FC).withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),

                // Label Teks Aksi Geser
                Center(
                  child: Text(
                    (progress >= 0.7 || _isCompleted)
                        ? (widget.isAccept
                            ? 'Menerima orderan'
                            : 'Menolak orderan')
                        : widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),

                // Knob Lingkaran Ungu '>>' atau '<<'
                Positioned(
                  left: widget.isAccept ? (_horizontalPadding + _dragOffset) : null,
                  right: !widget.isAccept ? (_horizontalPadding + _dragOffset) : null,
                  top: (_buttonHeight - _knobSize) / 2,
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B48FC),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B48FC).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.isAccept ? '>>' : '<<',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
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
}
