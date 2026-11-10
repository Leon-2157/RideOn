import 'package:flutter/material.dart';
import '../../data/toko_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_image.dart';

class TokoHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const TokoHomeScreen({super.key, this.onNavigateTab});

  @override
  State<TokoHomeScreen> createState() => _TokoHomeScreenState();
}

class _TokoHomeScreenState extends State<TokoHomeScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'tag': 'Baru',
      'tagColor': const Color(0xFFFEF3C7),
      'tagTextColor': const Color(0xFF92400E),
      'title': 'Pesanan Baru Masuk #FD-8822',
      'time': '1 mnt lalu',
      'desc': 'Pesanan baru masuk dari Rian Pratama (2× Nasi Goreng Spesial, Rp 50.000)....',
      'hasButton': true,
      'buttonText': 'Lihat Detail Pesanan >',
      'icon': Icons.receipt_long_rounded,
      'iconBg': AppColors.primarySoft,
      'iconColor': AppColors.primary,
      'imageAsset': 'assets/images/food_nasgor.png',
      'isRead': false,
    },
    {
      'tag': 'Selesai',
      'tagColor': AppColors.successLight,
      'tagTextColor': AppColors.success,
      'title': 'Pesanan Selesai #FD-8819',
      'time': '15 mnt lalu',
      'desc': 'Pesanan telah diambil oleh kurir dan selesai. Saldo +Rp 38.000 masuk ke dompet.',
      'icon': Icons.check_circle_rounded,
      'iconBg': AppColors.successLight,
      'iconColor': AppColors.success,
      'extraInfo': 'Otomatis dicairkan ke saldo merchant',
      'imageAsset': 'assets/images/avatar_customer.png',
      'isRead': false,
    },
    {
      'tag': 'Peringatan',
      'tagColor': const Color(0xFFFFEDD5),
      'tagTextColor': const Color(0xFFC2410C),
      'title': 'Peringatan Stok Menu',
      'time': '1 jam lalu',
      'desc': 'Menu Ayam Bakar Madu tersisa 2 porsi. Segera update stok toko agar tidak terjadi pembatalan otomatis.',
      'icon': Icons.warning_amber_rounded,
      'iconBg': const Color(0xFFFFEDD5),
      'iconColor': const Color(0xFFC2410C),
      'isRead': false,
    },
    {
      'tag': 'Info',
      'tagColor': AppColors.infoLight,
      'tagTextColor': AppColors.info,
      'title': 'Toko Dibuka Otomatis',
      'time': '08:00 WIB',
      'desc': 'Toko Anda otomatis aktif menerima pesanan sesuai jadwal operasional.',
      'icon': Icons.store_rounded,
      'iconBg': AppColors.primarySoft,
      'iconColor': AppColors.primary,
      'extraInfo': 'Status: Menerima Pesanan',
      'isRead': true,
    },
  ];

  String _formatRp(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _showNotificationSheet() {
    _notifications[3]['time'] = '${TokoState.openHour.value} WIB';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationSheet(
        notifications: _notifications,
        onMarkAllRead: () {
          setState(() {
            for (final n in _notifications) {
              n['isRead'] = true;
            }
          });
        },
        onMarkOneRead: (index) {
          setState(() {
            _notifications[index]['isRead'] = true;
          });
        },
        onViewOrder: () {
          setState(() {
            _notifications[0]['isRead'] = true;
          });
          Navigator.pop(ctx);
          widget.onNavigateTab?.call(1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: ListenableBuilder syncs home metrics with TokoState; upgrade to Provider/Bloc when backend API connected
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            TokoState.isStoreOpen,
            TokoState.orders,
            TokoState.storeName,
            TokoState.storeCategory,
            TokoState.openHour,
            TokoState.closeHour,
          ]),
          builder: (context, _) {
            final isStoreOpen = TokoState.isStoreOpen.value;
            final newOrders = TokoState.orders.value.where((o) => o['tab'] == 'baru').toList();
            final doneOrders = TokoState.orders.value.where((o) => o['tab'] == 'selesai').toList();
            final addedRevenue = doneOrders.fold<int>(
              0,
              (sum, o) => sum + TokoState.parsePrice(o['price'] as String?),
            );
            final totalRevenue = 845000 + addedRevenue;
            final totalCompleted = 18 + doneOrders.length;
            final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isStoreOpen, unreadCount),
                  const SizedBox(height: 18),
                  _buildStoreStatusCard(isStoreOpen),
                  const SizedBox(height: 18),
                  _buildRevenueCard(totalRevenue, totalCompleted),
                  const SizedBox(height: 22),
                  _buildOrdersSection(newOrders),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isStoreOpen, int unreadCount) {
    final storeName = TokoState.storeName.value;
    final parts = storeName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.length > 1
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (parts.isNotEmpty ? parts[0][0].toUpperCase() : 'T');

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      storeName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isStoreOpen ? AppColors.primarySoft : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isStoreOpen ? 'BUKA' : 'TUTUP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isStoreOpen ? AppColors.primary : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                TokoState.storeCategory.value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showNotificationSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreStatusCard(bool isStoreOpen) {
    final open = TokoState.openHour.value;
    final close = TokoState.closeHour.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isStoreOpen ? AppColors.primaryLight : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isStoreOpen ? AppColors.primarySoft : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isStoreOpen ? Icons.store_rounded : Icons.store_outlined,
              color: isStoreOpen ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStoreOpen ? 'Toko Menerima Pesanan' : 'Toko Tutup Sementara',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isStoreOpen ? 'Jam operasional: $open - $close' : 'Pesanan baru dijeda',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isStoreOpen,
            onChanged: (val) {
              TokoState.isStoreOpen.value = val;
            },
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(int totalRevenue, int totalCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendapatan Hari Ini',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rp ${_formatRp(totalRevenue)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesanan Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCompleted Pesanan',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: AppColors.borderLight,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating Toko',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: const [
                          Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                          SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(128)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(List<Map<String, dynamic>> newOrders) {
    final activeOrder = newOrders.isNotEmpty ? newOrders.first : null;
    final activeId = activeOrder?['id'] as String? ?? '';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Pesanan Perlu Diproses (${newOrders.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => widget.onNavigateTab?.call(1),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeOrder != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activeId,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Konfirmasi Segera',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  activeOrder['items'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activeOrder['price']} • ${activeOrder['payment'] ?? 'Tunai / COD'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          TokoState.rejectOrder(activeId);
                          setState(() {
                            if (_notifications.isNotEmpty) {
                              _notifications[0]['isRead'] = true;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pesanan $activeId ditolak')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          TokoState.acceptOrder(activeId);
                          setState(() {
                            if (_notifications.isNotEmpty) {
                              _notifications[0]['isRead'] = true;
                            }
                          });
                          widget.onNavigateTab?.call(1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pesanan $activeId diterima')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Terima Pesanan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: const [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 40),
                SizedBox(height: 10),
                Text(
                  'Semua pesanan telah diproses',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NotificationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onMarkAllRead;
  final ValueChanged<int> onMarkOneRead;
  final VoidCallback onViewOrder;

  const _NotificationSheet({
    required this.notifications,
    required this.onMarkAllRead,
    required this.onMarkOneRead,
    required this.onViewOrder,
  });

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  @override
  Widget build(BuildContext context) {
    final unread = widget.notifications.where((n) => n['isRead'] != true).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Notifikasi',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: const Key('btn_mark_all_read'),
                  onTap: unread == 0
                      ? null
                      : () {
                          setState(() {
                            widget.onMarkAllRead();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Semua notifikasi ditandai dibaca')),
                          );
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 16,
                        color: unread == 0 ? AppColors.textMuted : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tandai Dibaca',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: unread == 0 ? AppColors.textMuted : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.notifications.length,
              itemBuilder: (context, i) {
                final n = widget.notifications[i];
                final isRead = n['isRead'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () {
                      if (!isRead) {
                        setState(() {
                          widget.onMarkOneRead(i);
                        });
                      }
                    },
                    child: Opacity(
                      opacity: isRead ? 0.72 : 1.0,
                      child: _buildNotifItem(
                        tag: n['tag'] as String,
                        tagColor: n['tagColor'] as Color,
                        tagTextColor: n['tagTextColor'] as Color,
                        title: n['title'] as String,
                        time: n['time'] as String,
                        desc: n['desc'] as String,
                        icon: n['icon'] as IconData,
                        iconBg: n['iconBg'] as Color,
                        iconColor: n['iconColor'] as Color,
                        hasButton: n['hasButton'] == true,
                        buttonText: n['buttonText'] as String?,
                        onTapButton: widget.onViewOrder,
                        extraInfo: n['extraInfo'] as String?,
                        imageAsset: n['imageAsset'] as String?,
                        isRead: isRead,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem({
    required String tag,
    required Color tagColor,
    required Color tagTextColor,
    required String title,
    required String time,
    required String desc,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool hasButton = false,
    String? buttonText,
    VoidCallback? onTapButton,
    String? extraInfo,
    String? imageAsset,
    bool isRead = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (imageAsset != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: AppImage(
                    assetPath: imageAsset,
                    borderRadius: BorderRadius.circular(12),
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tagTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (extraInfo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                extraInfo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          if (hasButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTapButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText ?? 'Lihat',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
