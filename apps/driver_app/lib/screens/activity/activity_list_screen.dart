import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../chat/chat_history_screen.dart';
import '../radar/radar_screen.dart';
import '../wallet/wallet_screen.dart';
import 'activity_food_detail_screen.dart';
import 'activity_ride_detail_screen.dart';
import 'activity_shopping_detail_screen.dart';

/// Model Item Aktivitas Pesanan Driver
class DriverActivityItem {
  final String id;
  final String orderId;
  final String title;
  final String subtitle;
  final String category; // 'FLEXFOOD', 'FLEXRIDE', 'FLEXSEND'
  final String routeSummary;
  final String dateText;
  final String earningText;
  final String statusText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const DriverActivityItem({
    required this.id,
    required this.orderId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.routeSummary,
    required this.dateText,
    required this.earningText,
    required this.statusText,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });
}

/// [ActivityListScreen]
/// Layar Riwayat Aktivitas & Pesanan Driver RideOn
/// Memadukan desain spesifikasi Figma (HalamanAktivitas) dengan struktur riwayat transaksi
/// aplikasi driver profesional (Filter kategori, rincian rute, status selesai, pendapatan bersih).
class ActivityListScreen extends StatefulWidget {
  final int initialTabIndex;
  final ValueChanged<int>? onTabSelected;

  const ActivityListScreen({
    super.key,
    this.initialTabIndex = 1, // Default tab: Aktivitas (index 1)
    this.onTabSelected,
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  late int _currentTabIndex;
  String _selectedCategory = 'ALL'; // 'ALL', 'FLEXFOOD', 'FLEXRIDE', 'FLEXSEND'

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
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

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        _createNavBarRoute(const RadarScreen()),
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

  List<DriverActivityItem> _getActivityItems() {
    return [
      // 1. Pesanan Makanan (FlexFood)
      DriverActivityItem(
        id: '1',
        orderId: '#12E4S67',
        title: 'Pesanan Makanan',
        subtitle: 'Orderan toko',
        category: 'FLEXFOOD',
        routeSummary: 'Waroeng Bamboe → Jl. Dumai, ARUN (Fikri)',
        dateText: 'Hari ini, 12:45 WIB',
        earningText: '+ Rp 15.000',
        statusText: 'Selesai',
        icon: Icons.fastfood_rounded,
        iconColor: const Color(0xFF6B48FC),
        iconBgColor: const Color(0xFFEDE7F6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ActivityFoodDetailScreen(),
            ),
          );
        },
      ),

      // 2. Antar Penumpang (FlexRide)
      DriverActivityItem(
        id: '2',
        orderId: '#12E4S67',
        title: 'Antar penumpang',
        subtitle: 'Ojek',
        category: 'FLEXRIDE',
        routeSummary: 'Jl.Seulawah no 10 PIM → Suzuya Mall Lhokseumawe',
        dateText: 'Hari ini, 11:20 WIB',
        earningText: '+ Rp 35.000',
        statusText: 'Selesai',
        icon: Icons.two_wheeler_rounded,
        iconColor: const Color(0xFF6B48FC),
        iconBgColor: const Color(0xFFEDE7F6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ActivityRideDetailScreen(),
            ),
          );
        },
      ),

      // 3. Titip Belanja (FlexSend Manual)
      DriverActivityItem(
        id: '3',
        orderId: '#12E4S67',
        title: 'Titip Belanja',
        subtitle: 'Titip Belanja',
        category: 'FLEXSEND',
        routeSummary: 'Pasar Pagi Batuphat & Apotik → Jl. Lauser (Gufran)',
        dateText: 'Hari ini, 09:15 WIB',
        earningText: '+ Rp 183.000',
        statusText: 'Selesai',
        icon: Icons.shopping_bag_rounded,
        iconColor: const Color(0xFF6B48FC),
        iconBgColor: const Color(0xFFEDE7F6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ActivityShoppingDetailScreen(),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _getActivityItems();
    final filteredItems = _selectedCategory == 'ALL'
        ? allItems
        : allItems.where((item) => item.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Column(
        children: [
          // Header Bar dengan Curved Gradient Sesuai Figma
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B68FC),
                  Color(0xFFB4A1FF),
                  Color(0xFFEBE6FE),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Aktivitas',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ringkasan Pendapatan & Order Hari Ini
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B48FC).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Color(0xFF6B48FC),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Hari Ini',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF7A7593),
                                        ),
                                      ),
                                      Text(
                                        '3 Pesanan Selesai',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'Total Hasil',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A7593),
                                ),
                              ),
                              Text(
                                'Rp 233.000',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00A838),
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
            ),
          ),

          // Bar Filter Kategori (Semua, FlexFood, FlexRide, FlexSend)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('Semua (3)', 'ALL'),
                  const SizedBox(width: 8),
                  _buildFilterChip('FlexFood (1)', 'FLEXFOOD'),
                  const SizedBox(width: 8),
                  _buildFilterChip('FlexRide (1)', 'FLEXRIDE'),
                  const SizedBox(width: 8),
                  _buildFilterChip('FlexSend (1)', 'FLEXSEND'),
                ],
              ),
            ),
          ),

          // Daftar Kartu Aktivitas Driver
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRichActivityCard(item),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Bottom Navigation Bar Sesuai Figma
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

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
              // 1. Radar
              _buildNavItem(
                index: 0,
                icon: Icons.radar,
                label: 'Radar',
              ),
              // 2. Aktivitas (Active)
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

  Widget _buildFilterChip(String label, String categoryKey) {
    final bool isSelected = _selectedCategory == categoryKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = categoryKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B48FC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B48FC) : const Color(0xFFE2E0EE),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B48FC).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5A5672),
          ),
        ),
      ),
    );
  }

  Widget _buildRichActivityCard(DriverActivityItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E2FF),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Ikon Layanan, Judul, Subtitle, dan Order ID
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: item.iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6E6A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.orderId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.statusText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFD6CEFA)),
              const SizedBox(height: 10),

              // Baris Tengah: Ringkasan Rute / Toko & Pelanggan
              Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 16,
                    color: Color(0xFF6B48FC),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.routeSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4660),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Baris Bawah: Waktu & Nominal Pendapatan Driver
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF86829D),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF75718E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        item.earningText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00A838),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF75718E),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: Color(0xFF6B48FC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aktivitas pesanan untuk kategori ini belum tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7A7593),
              ),
            ),
          ],
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
