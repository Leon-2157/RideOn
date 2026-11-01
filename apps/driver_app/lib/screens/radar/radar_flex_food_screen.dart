import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../account_settings/account_settings_screen.dart';
import '../activity/activity_list_screen.dart';
import '../chat/call_screen.dart';
import '../chat/chat_detail_screen.dart';
import '../chat/chat_history_screen.dart';
import '../wallet/wallet_screen.dart';

/// Enum Status Alur Pemesanan FlexFood Sesuai Figma
enum FlexFoodOrderState {
  searching, // Figma: radar driver.png (Pencarian order)
  incoming, // Figma: pemesanan makanan.png (Order baru masuk & countdown)
  pickupPin, // Figma: konfirmasi kode toko.png (Verifikasi PIN 4092 di resto)
  delivering, // Figma: pengataran.png (Menuju lokasi antar pelanggan)
  completed, // Figma: iPhone 14 & 15 Pro - 20.png (Dialog selesaikan orderan)
}

/// [RadarFlexFoodScreen]
/// Implementasi Layar Radar & Pemesanan FlexFood Driver sesuai desain Figma:
/// - Figma/HalamanRadarFlexFood/radar driver.png
/// - Figma/HalamanRadarFlexFood/pemesanan makanan.png
/// - Figma/HalamanRadarFlexFood/konfirmasi kode toko.png
/// - Figma/HalamanRadarFlexFood/pengataran.png
/// - Figma/HalamanRadarFlexFood/iPhone 14 & 15 Pro - 20.png
class RadarFlexFoodScreen extends StatefulWidget {
  final String driverName;
  final String plateNumber;
  final bool initialIsOnline;
  final FlexFoodOrderState initialOrderState;
  final bool enableRadarAnimation;
  final ValueChanged<int>? onTabSelected;

  const RadarFlexFoodScreen({
    super.key,
    this.driverName = 'Joni utama',
    this.plateNumber = 'BK 4892 ABC',
    this.initialIsOnline = true,
    this.initialOrderState = FlexFoodOrderState.searching,
    this.enableRadarAnimation = true,
    this.onTabSelected,
  });

  @override
  State<RadarFlexFoodScreen> createState() => _RadarFlexFoodScreenState();
}

class _RadarFlexFoodScreenState extends State<RadarFlexFoodScreen>
    with SingleTickerProviderStateMixin {
  late bool _isOnline;
  late FlexFoodOrderState _orderState;
  int _currentTabIndex = 0; // Default: Tab 0 (Radar)

  // Radar Animation Controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Countdown timer untuk orderan masuk
  int _countdownSeconds = 16;
  Timer? _countdownTimer;

  // Data Mock Resto & Pengantaran Sesuai Figma
  final String _storeName = 'Waroeng Bamboe';
  final String _customerAddress = 'Jl. Dumai, ARUN No. 101 (Fikri)';
  final String _earningText = 'Rp 15.000';
  final String _tripDetails = 'Total Jarak Tempuh: 4.2 km Estimasi: 10 menit';
  final String _pinCode = '4 0 9 2';
  final String _orderId = 'ID : I2E4S68';

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialIsOnline;
    _orderState = widget.initialOrderState;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.enableRadarAnimation) {
      _pulseController.repeat();
    }

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    if (_orderState == FlexFoodOrderState.incoming &&
        widget.enableRadarAnimation) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 16;
    if (!widget.enableRadarAnimation) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
        } else {
          timer.cancel();
          _orderState = FlexFoodOrderState.searching;
        }
      });
    });
  }

  void _toggleOnlineStatus(bool value) {
    setState(() {
      _isOnline = value;
      if (!_isOnline) {
        _orderState = FlexFoodOrderState.searching;
        _countdownTimer?.cancel();
        _pulseController.stop();
      } else if (widget.enableRadarAnimation) {
        _pulseController.repeat();
      }
    });
  }

  void _acceptOrder() {
    _countdownTimer?.cancel();
    setState(() {
      _orderState = FlexFoodOrderState.pickupPin;
    });
  }

  void _rejectOrder() {
    _countdownTimer?.cancel();
    setState(() {
      _orderState = FlexFoodOrderState.searching;
    });
  }

  void _verifyPinAndPickup() {
    setState(() {
      _orderState = FlexFoodOrderState.delivering;
    });
  }

  void _completeOrder() {
    setState(() {
      _orderState = FlexFoodOrderState.completed;
    });
  }

  void _dismissCompletedOrder() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _orderState = FlexFoodOrderState.searching;
    });
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
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 1. Layer Peta Satelit / Background Radar
          Positioned.fill(
            child: _buildMapBackground(),
          ),

          // 2. Lingkaran Animasi Gelombang Radar (Pulsing Circle)
          if (_isOnline)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: _buildRadarPulseAnimation(),
                ),
              ),
            ),

          // 3. Hotspot Badge "Area sibuk" di Peta
          if (_isOnline)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.47,
              child: Center(
                child: _buildBusyAreaBadge(),
              ),
            ),

          // 4. Header Top Cards (Driver Profile & GPS SIAP)
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

          // 5. Floating Bottom Content sesuai State
          Positioned(
            left: 0,
            right: 0,
            bottom: 70.0 + MediaQuery.of(context).padding.bottom, // Di atas Bottom Navigation Bar
            child: _buildBottomOrderContent(),
          ),

          // 6. Dialog Penyelesaian Orderan (Figma: iPhone 14 & 15 Pro - 20.png)
          if (_orderState == FlexFoodOrderState.completed)
            Positioned.fill(
              child: _buildCompletionDialog(),
            ),

          // 7. Bottom Navigation Bar
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

  /// 1. Tampilan Background Peta dengan POI Resto Sesuai Figma
  Widget _buildMapBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/radar_driver_map.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF2C3E50),
              child: const Center(
                child: Text(
                  'Map Satelit Aktif',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          },
        ),

        // Pin Titik Pengemudi (Pusat Radar)
        Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF66),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),

        // POI Marker 1: Waroeng Bamboe
        if (_orderState == FlexFoodOrderState.searching)
          Positioned(
            left: 24,
            bottom: 230,
            child: _buildPoiMarker(
              title: 'Waroeng Bamboe',
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFFF9800),
            ),
          ),

        // POI Marker 2: Warung Kopi / Cek Dewan
        if (_orderState == FlexFoodOrderState.searching)
          Positioned(
            right: 20,
            bottom: 210,
            child: _buildPoiMarker(
              title: 'Warung m... cek dewan\nBaru dilihat',
              icon: Icons.coffee_rounded,
              color: const Color(0xFFFF9800),
            ),
          ),
      ],
    );
  }

  /// Marker POI Khusus Resto/Cafe di Peta
  Widget _buildPoiMarker({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Animasi Gelombang Radar Konsentris
  Widget _buildRadarPulseAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final progress = _pulseAnimation.value;
        return SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring 1 (Terdalam)
              Container(
                width: 110 + (progress * 40),
                height: 110 + (progress * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6B48FC).withValues(
                      alpha: (1.0 - progress) * 0.7,
                    ),
                    width: 2.5,
                  ),
                ),
              ),
              // Ring 2 (Tengah)
              Container(
                width: 170 + (progress * 50),
                height: 170 + (progress * 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF66).withValues(
                      alpha: (1.0 - progress) * 0.6,
                    ),
                    width: 2.0,
                  ),
                ),
              ),
              // Ring 3 (Terluar)
              Container(
                width: 230 + (progress * 60),
                height: 230 + (progress * 60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6B48FC).withValues(
                      alpha: (1.0 - progress) * 0.45,
                    ),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 3. Hotspot Badge "Area sibuk"
  Widget _buildBusyAreaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF17152B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.signal_cellular_alt_rounded,
              color: Color(0xFF17152B),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Area sibuk',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Top Header Row: Profile Pill & GPS SIAP
  Widget _buildTopHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Driver Profile Pill (Bisa ditap ke Account Settings)
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountSettingsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FC).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/driver_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.driverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.plateNumber,
                      style: const TextStyle(
                        color: Color(0xFFC6BCFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        // GPS SIAP Indicator Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFBCA6FF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GPS SIAP',
                style: TextStyle(
                  color: Color(0xFF17152B),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.location_on_rounded,
                color: Color(0xFF6B48FC),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Kartu Status Online / Offline
  Widget _buildOnlineStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA58BFF),
            Color(0xFFBCA6FF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B48FC).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isOnline
                    ? AppColors.onlineGreen.withValues(alpha: 0.35)
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isOnline
                    ? AppColors.onlineGreen
                    : const Color(0xFF888888),
                shape: BoxShape.circle,
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
                  _isOnline ? 'Status: Online' : 'Status: Offline',
                  style: TextStyle(
                    color: _isOnline
                        ? AppColors.onlineGreenDark
                        : const Color(0xFF17152B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isOnline ? 'Geser tombol untuk off' : 'Geser tombol untuk on',
                  style: const TextStyle(
                    color: Color(0xFF33296B),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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

  /// 5. Bottom Order Content Sesuai State
  Widget _buildBottomOrderContent() {
    if (!_isOnline) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF17152B).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new_rounded,
                  color: Color(0xFFC6BCFF), size: 18),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Anda sedang Offline. Aktifkan status untuk bekerja.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (_orderState) {
      case FlexFoodOrderState.searching:
        return _buildSearchingFloatingPill();
      case FlexFoodOrderState.incoming:
        return _buildIncomingFoodOrderModal();
      case FlexFoodOrderState.pickupPin:
        return _buildStorePinModal();
      case FlexFoodOrderState.delivering:
        return _buildDeliveringCard();
      case FlexFoodOrderState.completed:
        return const SizedBox.shrink();
    }
  }

  /// State Searching: Floating Pill "Mencari orderan terbaik..."
  Widget _buildSearchingFloatingPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          // Akses mudah untuk simulasi order masuk
          setState(() {
            _orderState = FlexFoodOrderState.incoming;
            _startCountdown();
          });
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: widget.enableRadarAnimation
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6B48FC)),
                      )
                    : const Icon(
                        Icons.radar,
                        size: 18,
                        color: Color(0xFF6B48FC),
                      ),
              ),
              const SizedBox(width: 14),
              const Flexible(
                child: Text(
                  'Mencari orderan terbaik...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF17152B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// State Incoming: Modal Orderan Makanan Masuk (pemesanan makanan.png)
  Widget _buildIncomingFoodOrderModal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B48FC),
            Color(0xFF8B6EF8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Badge "ORDERAN BARU MASUK!"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row: PESAN MAKANAN & Countdown Detik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PESAN MAKANAN',
                  style: TextStyle(
                    color: Color(0xFF6B48FC),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
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
          const SizedBox(height: 10),

          // Card 1: Pendapatan Bersih
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pendapatan Bersih',
                        style: TextStyle(
                          color: Color(0xFF00A859),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _earningText,
                        style: const TextStyle(
                          color: Color(0xFF00A859),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00A859).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Non-Tunai (E-Wallet)',
                    style: TextStyle(
                      color: Color(0xFF00A859),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Card 2: Lokasi Resto & Antar Customer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titik Resto
                Row(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      color: Color(0xFF00A859),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _storeName,
                        style: const TextStyle(
                          color: Color(0xFF17152B),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildKlikMapsButton(),
                  ],
                ),
                const SizedBox(height: 10),

                // Titik Antar
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF6B48FC),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _customerAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildKlikMapsButton(),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 4),

                // Total Jarak & Estimasi
                Text(
                  _tripDetails,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Action Buttons: SKIP>> & Terima Order Belanja
          Row(
            children: [
              // SKIP Button
              Expanded(
                flex: 2,
                child: InkWell(
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
              const SizedBox(width: 10),

              // Terima Order Belanja Button
              Expanded(
                flex: 3,
                child: InkWell(
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
            ],
          ),
        ],
      ),
    );
  }

  /// Tombol Hijau "Klik Maps" Sesuai Desain Figma
  Widget _buildKlikMapsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD5F5E3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Klik Maps',
        style: TextStyle(
          color: Color(0xFF008744),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// State Pickup PIN: Modal Konfirmasi Kode Toko PIN 4092 (konfirmasi kode toko.png)
  Widget _buildStorePinModal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B48FC),
            Color(0xFF8B6EF8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Spinner Indikator Loading
          SizedBox(
            width: 32,
            height: 32,
            child: widget.enableRadarAnimation
                ? const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
          ),
          const SizedBox(height: 14),

          // Card 1: TUNJUKKAN / SEBUTKAN PIN KE KASIR TOKO & Digit 4 0 9 2
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'TUNJUKKAN / SEBUTKAN PIN KE KASIR TOKO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF17152B),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _pinCode,
                  style: const TextStyle(
                    color: Color(0xFF17152B),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kasir wajib memasukkan 4 angka ini sebelum diserahkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Card 2: Rincian Menu Makanan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2x Nasi Goreng Spesial (1 pedas, 1 tidak)',
                  style: TextStyle(
                    color: Color(0xFF17152B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '1x Nasi Goreng telur (pedas )',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF17152B),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _orderId,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Konfirmasi Kasir
          InkWell(
            onTap: _verifyPinAndPickup,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF17152B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Kasir Sudah Verifikasi PIN & Makanan Diterima',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// State Delivering: Floating Card Lokasi Pengantaran (pengataran.png)
  Widget _buildDeliveringCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Putih: Lokasi Pengataran
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi pengataran',
                        style: TextStyle(
                          color: Color(0xFF17152B),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _customerAddress,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildKlikMapsButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Teks Keterangan Pelanggan
          const Text(
            'Setelah Customer mengkonfirmasi pesanan di terima otomatis bali ke radar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Aksi Telepon & Chat Lingkaran Sesuai Figma
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Call Hijau Lingkaran Putih
              InkWell(
                key: const Key('btn_call_customer'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CallScreen(
                        customerName: 'Fikri',
                        avatarInitials: 'F',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Color(0xFF00A859),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Tombol Chat Ungu Lingkaran
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatDetailScreen(
                        customerName: 'Fikri',
                        avatarInitials: 'F',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC6BCFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol Simulasi Selesaikan Pengantaran
          InkWell(
            onTap: _completeOrder,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SELESAIKAN PENGANTARAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Dialog Penyelesaian Orderan (Figma: iPhone 14 & 15 Pro - 20.png)
  Widget _buildCompletionDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Checklist Hijau Lingkaran
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00A859).withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF00A859),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // Title "Selesaikan Orderan"
              const Text(
                'Selesaikan Orderan',
                style: TextStyle(
                  color: Color(0xFF17152B),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Barang telah diantarkan dengan selamat, tekan tombol selesai untuk kembali keradar dan mencari orderan baru.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Card Transaksi
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('ID Transaksi', '#I2E4S67'),
                    const SizedBox(height: 8),
                    _buildDialogRow('Tanggal & Jam', '5 Okt 2026 13:02 WIB'),
                    const SizedBox(height: 8),
                    _buildDialogRow('Biaya', 'Rp 183.000', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Selesai
              InkWell(
                onTap: _dismissCompletedOrder,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17152B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Selesai',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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

  Widget _buildDialogRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF17152B),
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// 7. Bottom Navigation Bar Sesuai Desain Figma
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
              _buildNavItem(
                index: 0,
                icon: Icons.radar,
                label: 'Radar',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Aktivitas',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Dompet',
              ),
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
