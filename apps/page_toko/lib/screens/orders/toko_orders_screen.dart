import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TokoOrdersScreen extends StatefulWidget {
  const TokoOrdersScreen({super.key});

  @override
  State<TokoOrdersScreen> createState() => _TokoOrdersScreenState();
}

class _TokoOrdersScreenState extends State<TokoOrdersScreen> {
  int _selectedTabIndex = 1; // Default to 'Diproses (3)' as in screenshot

  final List<String> _tabs = [
    'Pesanan Baru (1)',
    'Diproses (3)',
    'Selesai',
    'Batal',
  ];

  void _openOrderDetail(Map<String, dynamic> order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: unified order list with client-side filter; upgrade to paginated infinite scroll if volume grows
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: _buildOrderList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(_tabs[index]),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderList() {
    final List<Map<String, dynamic>> orders = [
      {
        'id': '#FD-8821',
        'status': 'Sedang Dimasak',
        'statusColor': AppColors.primary,
        'statusBg': AppColors.primarySoft,
        'items': '1× Ayam Bakar Madu + Es Teh',
        'price': 'Rp 36.000',
        'driverStatus': 'Driver menunggu pesanan (5 mnt)',
        'customerName': 'Ahmad Fauzi',
        'pin': '8821',
      },
      {
        'id': '#FD-8921',
        'status': 'Perjalanan Ke Toko',
        'statusColor': AppColors.info,
        'statusBg': AppColors.infoLight,
        'items': '1× Ayam Bakar Madu',
        'price': 'Rp 30.000',
        'driverStatus': 'Driver menuju resto (14 mnt)',
        'customerName': 'Siti Rahma',
        'pin': '8921',
      },
      {
        'id': '#FD-7821',
        'status': 'Sedang Dimasak',
        'statusColor': AppColors.primary,
        'statusBg': AppColors.primarySoft,
        'items': 'Es Teh Manis',
        'price': 'Rp 6.000',
        'driverStatus': 'Driver menuju toko (9 mnt)',
        'customerName': 'Budi Santoso',
        'pin': '7821',
      },
    ];

    if (_selectedTabIndex == 0) {
      // Baru
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
        children: [
          _buildOrderItem(
            order: {
              'id': '#FD-8822',
              'status': 'Perlu Diterima',
              'statusColor': const Color(0xFFC2410C),
              'statusBg': const Color(0xFFFFEDD5),
              'items': '2× Nasi Goreng Spesial + 1x Es Teh',
              'price': 'Rp 55.000',
              'driverStatus': 'Konfirmasi dalam 04:31',
              'customerName': 'Rian Pratama',
              'pin': '8822',
            },
          ),
        ],
      );
    }

    if (_selectedTabIndex == 1) {
      // Diproses
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderItem(order: orders[index]);
        },
      );
    }

    return Center(
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
    );
  }

  Widget _buildOrderItem({required Map<String, dynamic> order}) {
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
              Text(
                'ID Pesanan ${order['id']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order['statusBg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order['status'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: order['statusColor'] as Color,
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
                  order['items'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                order['price'] as String,
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
              Text(
                order['driverStatus'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
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

  void _showDriverCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _DriverCallOverlay(
        driverName: 'Joni Utama (Driver)',
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
            const SizedBox(height: 14),
            _buildBuyerNote(),
            const SizedBox(height: 22),
            _buildMenuItemsSection(),
            const SizedBox(height: 22),
            _buildCookingTimeEstimation(),
            const SizedBox(height: 24),
            _buildCourierCallCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBanner() {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PERLU DITERIMA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Batas Konfirmasi',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pesanan Masuk',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Konfirmasi sebelum waktu habis',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.alarm_rounded, size: 16, color: AppColors.textPrimary),
                    SizedBox(width: 6),
                    Text(
                      '04:31',
                      style: TextStyle(
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
          child: const Text(
            'RP',
            style: TextStyle(
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
            children: const [
              Text(
                'Rian Pratama',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pelanggan Reguler • 4 Pesanan',
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
            widget.order['id'] ?? '#FD-8822',
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
              children: const [
                Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PEMBAYARAN', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      Text('Tunai / COD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Pembeli:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                SizedBox(height: 2),
                Text(
                  '"Sambal dipisah ya min"',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Rincian Menu (2 Menu)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              '3 Total Porsi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _menuRow(
          name: '2× Nasi Goreng Spesial',
          price: 'Rp 50.000',
          basePrice: 'Rp 25.000',
          tags: ['Level: Sedang', 'Telur Dadar'],
        ),
        const SizedBox(height: 14),
        _menuRow(
          name: '1× Es Teh Manis',
          price: 'Rp 5.000',
          basePrice: 'Rp 5.000',
          tags: ['Gula Normal'],
        ),
      ],
    );
  }

  Widget _menuRow({
    required String name,
    required String price,
    required String basePrice,
    required List<String> tags,
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
          child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 28),
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
            Text(
              'Estimasi Waktu Memasak',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
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
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kurir: Joni Utama',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Plat B 1234 XYZ • Parkir Depan',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesanan ditolak')),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pesanan diterima! Waktu masak: $_selectedMinutes menit')),
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
}

class _DriverCallOverlay extends StatelessWidget {
  final String driverName;
  final VoidCallback onHangup;

  const _DriverCallOverlay({
    required this.driverName,
    required this.onHangup,
  });

  @override
  Widget build(BuildContext context) {
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
              driverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Berdering...',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callActionButton(
                  icon: Icons.volume_up_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onTap: () {},
                ),
                _callActionButton(
                  icon: Icons.mic_off_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onTap: () {},
                ),
                _callActionButton(
                  icon: Icons.call_end_rounded,
                  color: AppColors.danger,
                  iconColor: Colors.white,
                  onTap: onHangup,
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
