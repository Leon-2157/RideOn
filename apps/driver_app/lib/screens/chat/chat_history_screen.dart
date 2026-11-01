import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../activity/activity_list_screen.dart';
import '../radar/radar_screen.dart';
import '../wallet/wallet_screen.dart';
import 'chat_detail_screen.dart';

/// Item Model untuk Riwayat Chat
class ChatConversationItem {
  final String id;
  final String name;
  final String subtitle;
  final bool isMissedCall;
  final String avatarInitials;

  const ChatConversationItem({
    required this.id,
    required this.name,
    required this.subtitle,
    this.isMissedCall = false,
    required this.avatarInitials,
  });
}

/// [ChatHistoryScreen]
/// Implementasi Layar Riwayat Chat Mitra Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanFlexSend/Halaman Chat.png
class ChatHistoryScreen extends StatefulWidget {
  final int initialTabIndex;
  final ValueChanged<int>? onTabSelected;

  const ChatHistoryScreen({
    super.key,
    this.initialTabIndex = 3, // Default Tab: Chat (index 3)
    this.onTabSelected,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  late int _currentTabIndex;

  final List<ChatConversationItem> _conversations = const [
    ChatConversationItem(
      id: '1',
      name: 'M.topik',
      subtitle: 'Panggilan berakhir',
      isMissedCall: true,
      avatarInitials: 'MT',
    ),
    ChatConversationItem(
      id: '2',
      name: 'Melissa',
      subtitle: 'Anda : Baik',
      isMissedCall: false,
      avatarInitials: 'M',
    ),
  ];

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
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        _createNavBarRoute(const ActivityListScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        _createNavBarRoute(const WalletScreen()),
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
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          // Header Bar dengan Gradien Ungu Sesuai Figma
          _buildHeader(context),

          // Daftar Percakapan
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _conversations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _conversations[index];
                return _buildConversationCard(item);
              },
            ),
          ),

          // Bottom Navigation Bar
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  /// Header Atas Riwayat Chat
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF9D84FC),
            Color(0xFFC7B7FC),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: const Center(
        child: Text(
          'Riwayat Chat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }

  /// Kartu Percakapan Sesuai Desain Figma
  Widget _buildConversationCard(ChatConversationItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              customerName: item.name,
              avatarInitials: item.avatarInitials,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF6B48FC),
              child: Text(
                item.avatarInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Nama & Status / Pesan Terakhir
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.isMissedCall) ...[
                        const Icon(
                          Icons.phone_missed_rounded,
                          size: 15,
                          color: Color(0xFFFF4D4F),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          item.subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ikon Chat Ungu & Chevron Sesuai Figma
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B48FC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFF6B48FC),
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF17152B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar Sesuai Desain Figma
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
