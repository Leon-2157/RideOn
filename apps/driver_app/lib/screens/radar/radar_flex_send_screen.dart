import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../account_settings/account_settings_screen.dart';
import '../activity/activity_list_screen.dart';
import '../chat/call_screen.dart';
import '../chat/chat_detail_screen.dart';
import '../chat/chat_history_screen.dart';
import '../wallet/wallet_screen.dart';
import '../wallet/widgets/dashed_border_container.dart';

/// Enum Status Alur Layanan Radar & Belanja FlexSend Driver sesuai Figma
enum FlexSendOrderState {
  dashboard, // Figma: dasboard driver.png & dasboard driver 1.png
  radarSearching, // Figma: radar driver.png
  incoming, // Figma: Orderan masuk.png & Orderan masuk (waktu hampir habis).png
  shoppingChecklist, // Figma: iPhone 14 & 15 Pro - 9 s/d 15.png
  inputReceiptParking, // Figma: iPhone 14 & 15 Pro - 16.png
  delivering, // Figma: iPhone 14 & 15 Pro - 18.png
  completed, // Figma: iPhone 14 & 15 Pro - 19.png
}

/// Model Item Belanja untuk Checklist
class ShoppingItem {
  final String name;
  final String? notes;
  final String priceText;
  bool isChecked;

  ShoppingItem({
    required this.name,
    this.notes,
    required this.priceText,
    this.isChecked = false,
  });
}

/// [RadarFlexSendScreen]
/// Implementasi Layar Radar & Order FlexSend (Titip Belanja) Mitra Driver sesuai Figma:
/// - Figma/HalamanRadarFlexSend/dasboard driver.png & dasboard driver 1.png (Dashboard Online/Offline & Proteksi Talangan)
/// - Figma/HalamanRadarFlexSend/atur batas modal kas.png (Modal Bottom Sheet Atur Modal Kas)
/// - Figma/HalamanRadarFlexSend/radar driver.png (Peta radar & pencarian order online)
/// - Figma/HalamanRadarFlexSend/Orderan masuk.png & Orderan masuk (waktu hampir habis).png (Modal Orderan Titip Belanja Masuk)
/// - Figma/HalamanRadarFlexSend/iPhone 14 & 15 Pro - 9 s/d 15.png (Checklist Belanja multi-lokasi & input harga)
/// - Figma/HalamanRadarFlexSend/iPhone 14 & 15 Pro - 16.png (Input Nota Belanja & Parkir)
/// - Figma/HalamanRadarFlexSend/iPhone 14 & 15 Pro - 17.png (Modal Konfirmasi Belanja)
/// - Figma/HalamanRadarFlexSend/iPhone 14 & 15 Pro - 18.png (Pengantaran pesanan di peta ke customer)
/// - Figma/HalamanRadarFlexSend/iPhone 14 & 15 Pro - 19.png (Modal Selesaikan Orderan & rincian biaya)
class RadarFlexSendScreen extends StatefulWidget {
  final String driverName;
  final String plateNumber;
  final bool initialIsOnline;
  final FlexSendOrderState initialOrderState;
  final bool enableRadarAnimation;
  final ValueChanged<int>? onTabSelected;

  const RadarFlexSendScreen({
    super.key,
    this.driverName = 'Joni utama',
    this.plateNumber = 'BK 4892 ABC',
    this.initialIsOnline = true,
    this.initialOrderState = FlexSendOrderState.dashboard,
    this.enableRadarAnimation = true,
    this.onTabSelected,
  });

  @override
  State<RadarFlexSendScreen> createState() => _RadarFlexSendScreenState();
}

class _RadarFlexSendScreenState extends State<RadarFlexSendScreen>
    with SingleTickerProviderStateMixin {
  late bool _isOnline;
  late FlexSendOrderState _orderState;
  int _currentTabIndex = 0; // Tab 0: Radar

  // Radar Pulse Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Modal Kas Talangan State
  String _cashLimit = 'Rp 200.000';

  // Countdown timer untuk orderan titip belanja masuk
  int _countdownSeconds = 18;
  Timer? _countdownTimer;

  // Multi-Lokasi Belanja State
  int _currentShoppingLocationIndex = 0; // 0: Lokasi 1, 1: Lokasi 2

  late List<ShoppingItem> _lokasi1Items;
  late List<ShoppingItem> _lokasi2Items;

  final TextEditingController _parking1Controller =
      TextEditingController(text: 'Rp 2.000');
  final TextEditingController _parking2Controller =
      TextEditingController(text: 'Rp 2.000');

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialIsOnline;
    _orderState = widget.initialOrderState;

    _initShoppingItems();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.enableRadarAnimation && _isOnline) {
      _pulseController.repeat();
    }

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    if (_orderState == FlexSendOrderState.incoming &&
        widget.enableRadarAnimation) {
      _startCountdown();
    }
  }

  void _initShoppingItems() {
    _lokasi1Items = [
      ShoppingItem(
        name: 'Daging Sapi (1 kg)',
        notes: 'Catatan: Potong dadu ukuran rendang',
        priceText: 'Rp 120.000',
        isChecked: true,
      ),
      ShoppingItem(
        name: 'Cabai Merah (0.5 kg)',
        priceText: 'Rp 20.000',
        isChecked: true,
      ),
      ShoppingItem(
        name: 'Bawang Merah (0.25 kg)',
        priceText: 'Rp 10.000',
        isChecked: true,
      ),
      ShoppingItem(
        name: 'Santan Instan (2 bungkus)',
        priceText: 'Rp 6.000',
        isChecked: true,
      ),
    ];

    _lokasi2Items = [
      ShoppingItem(
        name: 'Paracetamol (1 Papan)',
        priceText: 'Rp 10.000',
        isChecked: true,
      ),
    ];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _parking1Controller.dispose();
    _parking2Controller.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 18;
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
          _orderState = FlexSendOrderState.radarSearching;
        }
      });
    });
  }

  void _toggleOnlineStatus(bool value) {
    setState(() {
      _isOnline = value;
      if (!_isOnline) {
        _pulseController.stop();
        _countdownTimer?.cancel();
        _orderState = FlexSendOrderState.dashboard;
      } else if (widget.enableRadarAnimation) {
        _pulseController.repeat();
      }
    });
  }

  void _acceptOrder() {
    _countdownTimer?.cancel();
    setState(() {
      _orderState = FlexSendOrderState.shoppingChecklist;
    });
  }

  void _rejectOrder() {
    _countdownTimer?.cancel();
    setState(() {
      _orderState = FlexSendOrderState.radarSearching;
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
    // Mode full page checklist shopping
    if (_orderState == FlexSendOrderState.shoppingChecklist) {
      return _buildShoppingChecklistScreen();
    }

    // Mode full page input nota & parkir
    if (_orderState == FlexSendOrderState.inputReceiptParking) {
      return _buildInputReceiptParkingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      body: Stack(
        children: [
          // Background Gradient Soft Purple untuk Dashboard
          if (_orderState == FlexSendOrderState.dashboard)
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

          // Layer Peta Satelit Radar
          if (_orderState != FlexSendOrderState.dashboard)
            Positioned.fill(
              child: _buildMapBackground(),
            ),

          // Radar Concentric Circles Animation
          if (_isOnline &&
              (_orderState == FlexSendOrderState.radarSearching ||
                  _orderState == FlexSendOrderState.incoming ||
                  _orderState == FlexSendOrderState.delivering))
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: _buildRadarPulseAnimation(),
                ),
              ),
            ),

          // Area Sibuk Hotspot di Peta
          if (_isOnline && _orderState == FlexSendOrderState.radarSearching)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.48,
              child: Center(
                child: _buildBusyAreaBadge(),
              ),
            ),

          // Konten Dashboard Utama (dasboard driver.png & dasboard driver 1.png)
          if (_orderState == FlexSendOrderState.dashboard)
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

          // Header Bar Driver pada Mode Radar / Pengantaran
          if (_orderState != FlexSendOrderState.dashboard)
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
                      if (_orderState == FlexSendOrderState.radarSearching) ...[
                        const SizedBox(height: 12),
                        _buildOnlineStatusCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Floating Bottom Content (Searching Pill, Incoming Modal, Delivering Sheet)
          if (_orderState != FlexSendOrderState.dashboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70.0 + MediaQuery.of(context).padding.bottom,
              child: _buildBottomOrderContent(),
            ),

          // Dialog Selesaikan Orderan (iPhone 14 & 15 Pro - 19.png)
          if (_orderState == FlexSendOrderState.completed)
            Positioned.fill(
              child: _buildCompletedOrderDialog(),
            ),

          // Bottom Navigation Bar
          if (_orderState == FlexSendOrderState.dashboard ||
              _orderState == FlexSendOrderState.radarSearching)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET KOMPONEN DASBOR & HEADER
  // ==========================================

  Widget _buildTopHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Driver Profile Pill (Avatar + Nama + Plat)
        Flexible(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC6BCFF).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/driver_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.driverName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF17152B),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.plateNumber,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Badge GPS SIAP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFC6BCFF).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                Icons.location_on,
                color: Color(0xFF6B48FC),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC6BCFF).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppColors.onlineGreen
                            : Colors.grey.shade400,
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
                        _isOnline
                            ? 'Geser tombol untuk off'
                            : 'Geser tombol untuk mulai cari order',
                        style: const TextStyle(
                          color: Color(0xFF3E3660),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  /// Card Proteksi Talangan (dasboard driver.png)
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

  /// Card Pendapatan Bersih Hari Ini (dasboard driver.png)
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

  /// Tombol Buka Radar Maps Sekarang
  Widget _buildOpenRadarButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _orderState = FlexSendOrderState.radarSearching;
        });
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
              blurRadius: 12,
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

  // ==========================================
  // MODAL ATUR MODAL KAS BELANJA (atur batas modal kas.png)
  // ==========================================

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
                                selectedAmount = 'Rp 300.000 (Maks)';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAmount.contains('300.000')
                                      ? const Color(0xFF6B48FC)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Rp 300.000 (Maks)',
                                  style: TextStyle(
                                    color: Color(0xFF17152B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info Pill Proteksi Saldo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Pilih Proteksi Saldo Anda untuk menerima order dengan tidak melebihi talangan dana anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B48FC),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan & Terapkan ke Radar
                    InkWell(
                      onTap: () {
                        setState(() {
                          _cashLimit = selectedAmount.replaceAll(' (Maks)', '');
                        });
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Simpan & Terapkan ke Radar',
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
            );
          },
        );
      },
    );
  }

  // ==========================================
  // PETA & RADAR ANIMATION
  // ==========================================

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

  Widget _buildRadarPulseAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Gelombang luar
            Container(
              width: 280 * _pulseAnimation.value,
              height: 280 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6B48FC)
                      .withValues(alpha: 1.0 - _pulseAnimation.value),
                  width: 2,
                ),
              ),
            ),
            // Gelombang tengah hijau putus-putus
            Container(
              width: 190 * _pulseAnimation.value,
              height: 190 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00D26A)
                      .withValues(alpha: (1.0 - _pulseAnimation.value) * 0.8),
                  width: 1.5,
                ),
              ),
            ),
            // Titik Driver Hijau
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF00D26A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBusyAreaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFFFF9800),
            child: Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Area sibuk',
            style: TextStyle(
              color: Color(0xFF17152B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FLOATING BOTTOM ORDER CONTENT
  // ==========================================

  Widget _buildBottomOrderContent() {
    switch (_orderState) {
      case FlexSendOrderState.dashboard:
        return const SizedBox.shrink();
      case FlexSendOrderState.radarSearching:
        return _buildSearchingFloatingPill();
      case FlexSendOrderState.incoming:
        return _buildIncomingSendOrderModal();
      case FlexSendOrderState.shoppingChecklist:
      case FlexSendOrderState.inputReceiptParking:
        return const SizedBox.shrink();
      case FlexSendOrderState.delivering:
        return _buildDeliveringRouteSheet();
      case FlexSendOrderState.completed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSearchingFloatingPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          setState(() {
            _orderState = FlexSendOrderState.incoming;
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

  /// Modal Orderan Masuk Titip Belanja (Orderan masuk.png & Orderan masuk (waktu hampir habis).png)
  Widget _buildIncomingSendOrderModal() {
    final bool isWarning = _countdownSeconds <= 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF533EC4),
            Color(0xFF7A64E8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle putih
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header Badge Status / Alert
          if (!isWarning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
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
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Waktu hampir habis! Orderan akan otomatis dialihkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Row 1: Titip Belanja Badge & Countdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF6B48FC),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'TITIP BELANJA',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF6B48FC),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isWarning ? const Color(0xFFFFEBEE) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isWarning
                      ? Border.all(color: const Color(0xFFE57373))
                      : null,
                ),
                child: Text(
                  '$_countdownSeconds Detik',
                  style: TextStyle(
                    color: isWarning
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF17152B),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: 2 Kartu (Pendapatan Bersih & Estimasi Talangan)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          color: Color(0xFF777777),
                          fontSize: 9,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
          const SizedBox(height: 10),

          // Row 3: Rincian Rute Belanja & Antar
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
                _buildRouteItem(
                    'Pajak batuphat (4 Item)', 'Klik Maps', isStop: true),
                const SizedBox(height: 8),
                _buildRouteItem(
                    'Apotek Kimia Farma (1 Item)', 'Klik Maps', isStop: true),
                const SizedBox(height: 8),
                _buildRouteItem(
                    'Jl. Lauser, PIM No. 88 (Gufran)', 'Klik Maps',
                    isStop: false),
                const SizedBox(height: 10),
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
          const SizedBox(height: 12),

          // Tombol Aksi: SKIP>> & Terima Order Belanja
          Row(
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
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
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkWell(
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteItem(String title, String buttonLabel,
      {required bool isStop}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isStop ? const Color(0xFF17152B) : const Color(0xFF555555),
              fontWeight: isStop ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            buttonLabel,
            style: const TextStyle(
              color: Color(0xFF00A859),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SHOPPING CHECKLIST SCREEN (iPhone 14 & 15 Pro - 9 s/d 15.png)
  // ==========================================

  Widget _buildShoppingChecklistScreen() {
    final isLocation1 = _currentShoppingLocationIndex == 0;
    final currentItems = isLocation1 ? _lokasi1Items : _lokasi2Items;
    final checkedCount = currentItems.where((i) => i.isChecked).length;
    final totalCount = currentItems.length;
    final progressPercent = (checkedCount / totalCount * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFC6BCFF),
                Color(0xFFF7F6FE),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF17152B)),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                        return;
                      }
                      setState(() {
                        _orderState = FlexSendOrderState.dashboard;
                      });
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pesanan',
                        style: TextStyle(
                          color: Color(0xFF17152B),
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  _buildChatIconBadge('Gufran'),
                  const SizedBox(width: 8),
                  _buildCallIconBadge('Gufran'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  // Header Info Pemesan & Lokasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Color(0xFF17152B), size: 22),
                              SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'FlexSend',
                                      style: TextStyle(
                                        color: Color(0xFF17152B),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Titip Belanja Manual',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Pemesan: Gufran',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF17152B),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Color(0xFF6B48FC), size: 13),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      isLocation1
                                          ? 'Lokasi 1: Pasar Pagi Batuphat'
                                          : 'Lokasi 2: Apotik Dien Farma',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF555555),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar Belanja
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Progres Belanja: $checkedCount dari $totalCount Barang',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6B48FC),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$progressPercent% Selesai',
                              style: const TextStyle(
                                color: Color(0xFF6B48FC),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalCount == 0
                                ? 0.0
                                : checkedCount / totalCount,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF333333),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF6B48FC)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Daftar Item Belanja
                  ...currentItems.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E5FB)),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                item.isChecked = !item.isChecked;
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.isChecked
                                    ? const Color(0xFF6B48FC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.isChecked
                                      ? const Color(0xFF6B48FC)
                                      : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: item.isChecked
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Color(0xFF17152B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                if (item.notes != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.notes!,
                                    style: const TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFF6B48FC)),
                            ),
                            child: Text(
                              item.priceText,
                              style: const TextStyle(
                                color: Color(0xFF17152B),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // Tombol Stok Habis? Konfirmasi di Chat
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChatDetailScreen(
                              customerName: 'Gufran',
                              avatarInitials: 'G',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6B48FC)),
                        ),
                        child: const Text(
                          'Stok Habis? Konfirmasi di  Chat',
                          style: TextStyle(
                            color: Color(0xFF6B48FC),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Floating Navigation Arrow (Next / Previous Location)
            Positioned(
              right: 12,
              top: MediaQuery.of(context).size.height * 0.42,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentShoppingLocationIndex =
                        _currentShoppingLocationIndex == 0 ? 1 : 0;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5DEFF),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLocation1 ? Icons.chevron_right : Icons.chevron_left,
                    color: const Color(0xFF6B48FC),
                    size: 26,
                  ),
                ),
              ),
            ),

            // Tombol Bottom: Selesai Belanja > Masukkan Nota & Parkir
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _orderState = FlexSendOrderState.inputReceiptParking;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17152B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Selesai Belanja > Masukkan Nota & Parkir',
                      style: TextStyle(
                        color: Colors.white,
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
      ),
    );
  }

  // ==========================================
  // INPUT NOTA BELANJA & PARKIR (iPhone 14 & 15 Pro - 16.png)
  // ==========================================

  Widget _buildInputReceiptParkingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFC6BCFF),
                Color(0xFFF7F6FE),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF17152B)),
                    onPressed: () {
                      setState(() {
                        _orderState = FlexSendOrderState.shoppingChecklist;
                      });
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Input Nota Belanja & Parkir',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF17152B),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  _buildChatIconBadge('Gufran'),
                  const SizedBox(width: 8),
                  _buildCallIconBadge('Gufran'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Color(0xFF17152B), size: 22),
                              SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'FlexSend',
                                      style: TextStyle(
                                        color: Color(0xFF17152B),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Titip Belanja Manual',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Pemesan: Gufran',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF17152B),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Lokasi 1 Card (Pasar Pagi Batuphat)
                  _buildReceiptLocationCard(
                    locationTitle: 'Lokasi 1: Pasar Pagi Batuphat',
                    itemCountText: '4 Barang',
                    items: const [
                      '1. Daging Sapi (1 kg)\nCatatan: Potong dadu rendang',
                      '2. Cabai Merah (1/2 kg)',
                      '3. Bawang Merah (1/4 kg)',
                      '4. Santan Instan (2 bks)',
                    ],
                    prices: const [
                      'Rp 120.000',
                      'Rp 20.000',
                      'Rp 10.000',
                      'Rp 6.000',
                    ],
                    parkingController: _parking1Controller,
                  ),
                  const SizedBox(height: 14),

                  // Lokasi 2 Card (Apotik Dien Farma)
                  _buildReceiptLocationCard(
                    locationTitle: 'Lokasi 1: Apotik Dien Farma',
                    itemCountText: '1 Barang',
                    items: const [
                      '1. Paracetamol (1 Papan)',
                    ],
                    prices: const [
                      'Rp 10.000',
                    ],
                    parkingController: _parking2Controller,
                  ),
                  const SizedBox(height: 16),

                  // Total Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Total', 'Rp 166.000'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Total Retribusi Parkir', 'Rp 2.000'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Ongkir Driver', '+ Rp 15.000',
                            isGreen: true),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade300, height: 1),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'TOTAL',
                                style: TextStyle(
                                  color: Color(0xFFC6BCFF),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rp 183.000',
                              style: TextStyle(
                                color: Color(0xFFC6BCFF),
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),

            // Tombol Lanjut Antar ke Customer
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: InkWell(
                onTap: _showKonfirmasiBelanjaDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17152B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Lanjut Antar ke Customer',
                      style: TextStyle(
                        color: Colors.white,
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
      ),
    );
  }

  Widget _buildReceiptLocationCard({
    required String locationTitle,
    required String itemCountText,
    required List<String> items,
    required List<String> prices,
    required TextEditingController parkingController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E5FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6BCFF).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF6B48FC), size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF17152B),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                itemCountText,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items list with prices
          for (int i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      color: Color(0xFF17152B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                Text(
                  prices[i],
                  style: const TextStyle(
                    color: Color(0xFF17152B),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 4),
          const Text(
            'Biaya Retribusi Parkir Pasar',
            style: TextStyle(
              color: Color(0xFF17152B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                width: 110,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  parkingController.text,
                  style: const TextStyle(
                    color: Color(0xFF17152B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF6B48FC).withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: Color(0xFF6B48FC), size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '+ png1234567899',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '#Kosong kan saja jika tidak ada parkir',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isGreen ? const Color(0xFF00A859) : const Color(0xFF555555),
              fontWeight: isGreen ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isGreen ? const Color(0xFF00A859) : const Color(0xFF17152B),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MODAL KONFIRMASI BELANJA (iPhone 14 & 15 Pro - 17.png)
  // ==========================================

  void _showKonfirmasiBelanjaDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Dompet Checklist Ungu
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC6BCFF),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF6B48FC),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Konfirmasi Belanja',
                  style: TextStyle(
                    color: Color(0xFF17152B),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Setelah customer mengkonfirmasi penyelesaian pesanan, akan kembali otomatis ke radar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Card Rincian
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Total',
                                style: TextStyle(
                                    color: Color(0xFF777777), fontSize: 12)),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text('Rp 183.000',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Color(0xFF17152B),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Metode Pelunasan',
                                style: TextStyle(
                                    color: Color(0xFF777777), fontSize: 12)),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text('Menyerahkan uang cash',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Color(0xFF00A859),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('ID orderan',
                                style: TextStyle(
                                    color: Color(0xFF777777), fontSize: 12)),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text('ID : I2E4S67',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Color(0xFF17152B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Direct ke Maps Pengantaran
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _orderState = FlexSendOrderState.delivering;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'klik untuk langsung diarahkan ke maps\nlokasi pengataran',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Link Periksa Ulang Nota
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Periksa Ulang Nota',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  // ==========================================
  // PENGANTARAN KE CUSTOMER DI PETA (iPhone 14 & 15 Pro - 18.png)
  // ==========================================

  Widget _buildDeliveringRouteSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF7A64E8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Route breakdown card
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
                _buildRouteItem(
                    'Pajak batuphat (4 Item)', 'Klik Maps', isStop: true),
                const SizedBox(height: 8),
                _buildRouteItem(
                    'Apotek Kimia Farma (1 Item)', 'Klik Maps', isStop: true),
                const SizedBox(height: 8),
                _buildRouteItem(
                    'Jl. Lauser, PIM No. 88 (Gufran)', 'Klik Maps',
                    isStop: false),
                const SizedBox(height: 10),
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
          const SizedBox(height: 14),

          // Tombol SELESAIKAN PENGANTARAN
          InkWell(
            onTap: () {
              setState(() {
                _orderState = FlexSendOrderState.completed;
              });
            },
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
                  'SELESAIKAN PENGANTARAN',
                  style: TextStyle(
                    color: Colors.white,
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

  // ==========================================
  // DIALOG SELESAIKAN ORDERAN (iPhone 14 & 15 Pro - 19.png)
  // ==========================================

  Widget _buildCompletedOrderDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

              const Text(
                'Selesaikan Orderan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17152B),
                ),
              ),
              const SizedBox(height: 10),

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

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E5FB)),
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
              const SizedBox(height: 22),

              InkWell(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                    return;
                  }
                  setState(() {
                    _orderState = FlexSendOrderState.dashboard;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17152B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
              color: const Color(0xFF17152B),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ACTION ICON BADGES (CHAT & CALL)
  // ==========================================

  Widget _buildChatIconBadge(String customerName) {
    return InkWell(
      key: Key('btn_chat_$customerName'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              customerName: customerName,
              avatarInitials: customerName[0],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFC6BCFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.chat_bubble,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildCallIconBadge(String customerName) {
    return InkWell(
      key: Key('btn_call_$customerName'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              customerName: customerName,
              avatarInitials: customerName.isNotEmpty ? customerName[0] : 'C',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.phone,
          color: Color(0xFF00A859),
          size: 18,
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF17152B),
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
                isActive: _currentTabIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                label: 'Aktivitas',
                isActive: _currentTabIndex == 1,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Dompet',
                isActive: _currentTabIndex == 2,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'chat',
                isActive: _currentTabIndex == 3,
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
    required bool isActive,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? const Color(0xFFC6BCFF) : Colors.white60,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? const Color(0xFFC6BCFF) : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
