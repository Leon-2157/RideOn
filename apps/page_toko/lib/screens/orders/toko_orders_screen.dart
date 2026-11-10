import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/toko_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_image.dart';

class TokoOrdersScreen extends StatefulWidget {
  const TokoOrdersScreen({super.key});

  @override
  State<TokoOrdersScreen> createState() => _TokoOrdersScreenState();
}

class _TokoOrdersScreenState extends State<TokoOrdersScreen> {
  int _selectedTabIndex = 1; // Default to 'Diproses'

  void _openOrderDetail(Map<String, dynamic> order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: unified order list with TokoState listener; upgrade to paginated infinite scroll if volume grows
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: TokoState.orders,
          builder: (context, orders, _) {
            final baruList = orders.where((o) => o['tab'] == 'baru').toList();
            final diprosesList = orders.where((o) => o['tab'] == 'diproses').toList();
            final selesaiList = orders.where((o) => o['tab'] == 'selesai').toList();
            final batalList = orders.where((o) => o['tab'] == 'batal').toList();

            final tabs = [
              'Pesanan Baru (${baruList.length})',
              'Diproses (${diprosesList.length})',
              'Selesai (${selesaiList.length})',
              'Batal (${batalList.length})',
            ];

            List<Map<String, dynamic>> activeList;
            if (_selectedTabIndex == 0) {
              activeList = baruList;
            } else if (_selectedTabIndex == 1) {
              activeList = diprosesList;
            } else if (_selectedTabIndex == 2) {
              activeList = selesaiList;
            } else {
              activeList = batalList;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Text(
                    'Pesanan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildTabBar(tabs),
                const SizedBox(height: 12),
                Expanded(
                  child: activeList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 10),
                              Text(
                                'Tidak ada pesanan di kategori ini',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                          itemCount: activeList.length,
                          itemBuilder: (context, index) {
                            return _buildOrderItem(order: activeList[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(List<String> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTabIndex = index);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderItem({required Map<String, dynamic> order}) {
    final statusColor = (order['statusColor'] as Color?) ?? AppColors.primary;
    final statusBg = (order['statusBg'] as Color?) ?? AppColors.primarySoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  'ID Pesanan ${order['id']}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order['status'] as String? ?? 'Pesanan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order['items'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order['price'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order['driverStatus'] as String? ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openOrderDetail(order),
                child: const Text(
                  'Rincian >',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int _selectedMinutes = 35;
  Timer? _countdownTimer;
  int _remainingSeconds = 271;

  @override
  void initState() {
    super.initState();
    if (widget.order['tab'] == 'baru') {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showDriverCallDialog() {
    final driverName = widget.order['driverName'] as String? ?? 'Kurir Mitra';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _DriverCallOverlay(
        driverName: '$driverName (Driver)',
        onHangup: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimerBanner(),
            const SizedBox(height: 18),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildBadgesRow(),
            if ((widget.order['buyerNote'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              _buildBuyerNote(),
            ],
            const SizedBox(height: 22),
            _buildMenuItemsSection(),
            if (widget.order['tab'] == 'baru') ...[
              const SizedBox(height: 22),
              _buildCookingTimeEstimation(),
            ],
            if (widget.order['driverName'] != null) ...[
              const SizedBox(height: 24),
              _buildCourierCallCard(),
            ],
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBanner() {
    final tab = widget.order['tab'] as String? ?? 'diproses';
    final status = widget.order['status'] as String? ?? 'Diproses';
    final statusBg = (widget.order['statusBg'] as Color?) ?? AppColors.primarySoft;
    final statusColor = (widget.order['statusColor'] as Color?) ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab == 'baru' ? Icons.timer_outlined : Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tab == 'baru'
                        ? 'Batas Konfirmasi'
                        : (tab == 'diproses' ? 'Status Masak' : 'Status Akhir'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab == 'baru'
                          ? 'Pesanan Masuk'
                          : (tab == 'diproses' ? 'Pesanan Diproses' : status),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.order['driverStatus'] as String? ?? 'Status terkini pesanan',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (tab == 'baru')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
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

  Widget _buildCustomerCard() {
    final customerName = widget.order['customerName'] as String? ?? 'Pelanggan';
    final parts = customerName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.length > 1
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (parts.isNotEmpty ? parts[0][0].toUpperCase() : 'P');

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Pelanggan Mitra Toko',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            widget.order['id'] as String? ?? '#FD-0000',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesRow() {
    final payment = widget.order['payment'] as String? ?? 'Tunai / COD';
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PEMBAYARAN', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      Text(payment, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PENGIRIMAN', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      Text('Kurir Mitra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerNote() {
    final note = widget.order['buyerNote'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Pembeli:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '"$note"',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsSection() {
    final itemDetails = widget.order['itemDetails'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Rincian Menu (${itemDetails != null ? itemDetails.length : 1} Menu)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.order['price'] as String? ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (itemDetails != null && itemDetails.isNotEmpty)
          ...itemDetails.map((it) {
            final m = it as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _menuRow(
                name: m['name'] as String? ?? '',
                price: m['price'] as String? ?? '',
                basePrice: m['basePrice'] as String? ?? '',
                tags: (m['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                imageAsset: m['image'] as String?,
              ),
            );
          })
        else
          _menuRow(
            name: widget.order['items'] as String? ?? '',
            price: widget.order['price'] as String? ?? '',
            basePrice: widget.order['price'] as String? ?? '',
            tags: const ['Menu Pesanan'],
            imageAsset: 'assets/images/food_nasgor.png',
          ),
      ],
    );
  }

  Widget _menuRow({
    required String name,
    required String price,
    required String basePrice,
    required List<String> tags,
    String? imageAsset,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageAsset != null
              ? AppImage(
                  assetPath: imageAsset,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(12),
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                basePrice,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          price,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCookingTimeEstimation() {
    final times = [15, 25, 35, 45];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Expanded(
              child: Text(
                'Estimasi Waktu Memasak',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Wajib Dipilih',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Waktu ini dijadikan acuan kedatangan kurir penjemput makanan.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: times.map((t) {
            final isSelected = _selectedMinutes == t;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMinutes = t),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$t',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Menit',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCourierCallCard() {
    final driverName = widget.order['driverName'] as String? ?? 'Kurir Mitra';
    final driverPlat = widget.order['driverPlat'] as String? ?? 'Plat Motor Driver';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kurir: $driverName',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  driverPlat,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showDriverCallDialog,
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
            label: const Text('Telepon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final tab = widget.order['tab'] as String? ?? 'diproses';
    final orderId = widget.order['id'] as String? ?? '';

    if (tab == 'baru') {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                TokoState.rejectOrder(orderId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pesanan $orderId telah ditolak')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: Color(0xFFFECDD3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Tolak Pesanan'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                TokoState.acceptOrder(orderId, _selectedMinutes);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pesanan $orderId diterima! Estimasi: $_selectedMinutes menit')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Terima & Mulai Masak',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    if (tab == 'diproses') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            TokoState.completeOrder(orderId);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pesanan $orderId selesai diserahkan ke kurir')),
            );
          },
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: const Text('Tandai Pesanan Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: tab == 'selesai' ? AppColors.successLight : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        tab == 'selesai' ? 'Pesanan Telah Selesai' : 'Pesanan Telah Dibatalkan',
        style: TextStyle(
          color: tab == 'selesai' ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DriverCallOverlay extends StatefulWidget {
  final String driverName;
  final VoidCallback onHangup;

  const _DriverCallOverlay({
    required this.driverName,
    required this.onHangup,
  });

  @override
  State<_DriverCallOverlay> createState() => _DriverCallOverlayState();
}

class _DriverCallOverlayState extends State<_DriverCallOverlay> {
  bool _isSpeakerOn = false;
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    String callStatus = 'Menghubungkan suara...';
    if (_isMuted && _isSpeakerOn) {
      callStatus = 'Speaker aktif • Mikrofon dibisukan';
    } else if (_isMuted) {
      callStatus = 'Mikrofon dibisukan';
    } else if (_isSpeakerOn) {
      callStatus = 'Speaker aktif';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.dark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.driverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              callStatus,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.delivery_dining_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callActionButton(
                  icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                  color: _isSpeakerOn ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                ),
                _callActionButton(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted ? AppColors.danger : Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _callActionButton(
                  icon: Icons.call_end_rounded,
                  color: AppColors.danger,
                  iconColor: Colors.white,
                  onTap: widget.onHangup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _callActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
