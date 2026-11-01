import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../activity/activity_list_screen.dart';
import '../chat/chat_history_screen.dart';
import '../radar/radar_screen.dart';
import 'withdraw_screen.dart';
import 'claim_talangan_screen.dart';

/// Model untuk item transaksi online pada dompet driver
class WalletTransaction {
  final String title;
  final String orderId;
  final String amount;
  final bool isDebit;
  final String date;
  final String category; // 'Pendapatan', 'Fee admin', 'Penarikan', 'Refund', 'Top Up'
  final String status;
  final String serviceType; // 'FlexRide', 'FlexFood', 'FlexSend', 'Bank', 'Deposit'
  final int? grossAmount;
  final int? adminFee;
  final int? netAmount;

  const WalletTransaction({
    required this.title,
    required this.orderId,
    required this.amount,
    required this.isDebit,
    this.date = '30 Okt 2026, 12:45 WIB',
    this.category = 'Pendapatan',
    this.status = 'Berhasil',
    this.serviceType = 'FlexRide',
    this.grossAmount,
    this.adminFee,
    this.netAmount,
  });
}

/// [WalletScreen]
/// Layar Utama Dompet Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanDompet/dompet.png
/// Dilengkapi sistem keuangan driver yang jelas:
/// 1. Saldo aktif driver real-time & dinamis
/// 2. Alur penarikan saldo (Withdraw) yang langsung memotong saldo & mencatat mutasi
/// 3. Fitur Top Up / Isi Saldo Deposit driver
/// 4. Riwayat transaksi dengan filter (Semua, Pendapatan, Fee admin, Penarikan)
/// 5. Struk rincian transaksi interaktif (Modal Bottom Sheet)
/// 6. Klaim jaminan talangan belanja FlexSend
class WalletScreen extends StatefulWidget {
  final int initialTabIndex;
  final ValueChanged<int>? onTabSelected;
  final int initialBalance;
  final int initialShippingEarnings;
  final int initialTalanganRefund;
  final List<WalletTransaction>? customTransactions;

  const WalletScreen({
    super.key,
    this.initialTabIndex = 2, // Default tab: Dompet (index 2)
    this.onTabSelected,
    this.initialBalance = 327000,
    this.initialShippingEarnings = 45000,
    this.initialTalanganRefund = 50000,
    this.customTransactions,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late int _currentTabIndex;
  late int _currentBalance;
  late int _shippingEarnings;
  late int _talanganRefund;
  late List<WalletTransaction> _transactions;
  String _selectedFilter = 'Semua';
  OverlayEntry? _activeNotificationEntry;

  @override
  void dispose() {
    if (_activeNotificationEntry != null && _activeNotificationEntry!.mounted) {
      _activeNotificationEntry!.remove();
    }
    _activeNotificationEntry = null;
    super.dispose();
  }

  void _showTopSuccessNotification({
    required String title,
    required String message,
  }) {
    if (!mounted) return;
    if (_activeNotificationEntry != null && _activeNotificationEntry!.mounted) {
      _activeNotificationEntry!.remove();
    }
    _activeNotificationEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotificationBanner(
        title: title,
        message: message,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
          if (_activeNotificationEntry == entry) {
            _activeNotificationEntry = null;
          }
        },
      ),
    );

    _activeNotificationEntry = entry;
    overlay.insert(entry);
  }

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _currentBalance = widget.initialBalance;
    _shippingEarnings = widget.initialShippingEarnings;
    _talanganRefund = widget.initialTalanganRefund;

    _transactions = widget.customTransactions != null
        ? List<WalletTransaction>.from(widget.customTransactions!)
        : [
            const WalletTransaction(
              title: 'Fee admin',
              orderId: 'ID : I2E4S68',
              amount: '- Rp3.500',
              isDebit: true,
              date: '30 Okt 2026, 12:45 WIB',
              category: 'Fee admin',
              serviceType: 'FlexRide',
              grossAmount: 35000,
              adminFee: 3500,
              netAmount: 31500,
            ),
            const WalletTransaction(
              title: 'Ongkos Kirim',
              orderId: 'ID : I2E4S68',
              amount: '+ Rp 35.000',
              isDebit: false,
              date: '30 Okt 2026, 12:45 WIB',
              category: 'Pendapatan',
              serviceType: 'FlexRide',
              grossAmount: 35000,
              adminFee: 3500,
              netAmount: 35000,
            ),
            const WalletTransaction(
              title: 'Fee admin',
              orderId: 'ID : I2E4S67',
              amount: '- Rp 1.500',
              isDebit: true,
              date: '30 Okt 2026, 11:15 WIB',
              category: 'Fee admin',
              serviceType: 'FlexFood',
              grossAmount: 15000,
              adminFee: 1500,
              netAmount: 13500,
            ),
            const WalletTransaction(
              title: 'Fee admin',
              orderId: 'ID : I2E4S67',
              amount: '- Rp 1.500',
              isDebit: true,
              date: '30 Okt 2026, 11:15 WIB',
              category: 'Fee admin',
              serviceType: 'FlexFood',
              grossAmount: 15000,
              adminFee: 1500,
              netAmount: 13500,
            ),
            const WalletTransaction(
              title: 'Ongkos Kirim',
              orderId: 'ID : I2E4S67',
              amount: '+ Rp 15.000',
              isDebit: false,
              date: '30 Okt 2026, 11:15 WIB',
              category: 'Pendapatan',
              serviceType: 'FlexFood',
              grossAmount: 15000,
              adminFee: 1500,
              netAmount: 15000,
            ),
          ];
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

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  void _navigateToWithdraw() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => WithdrawScreen(
          initialBalance: _currentBalance,
          onWithdrawSuccess: (amount) {
            _handleWithdrawSuccess(amount);
          },
        ),
      ),
    );

    if (result != null && result > 0) {
      _handleWithdrawSuccess(result);
    }
  }

  void _handleWithdrawSuccess(int amount) {
    if (amount <= 0) return;
    setState(() {
      _currentBalance = (_currentBalance - amount).clamp(0, 999999999);
      _transactions.insert(
        0,
        WalletTransaction(
          title: 'Tarik Saldo ke Rekening BSI',
          orderId: 'REF : #99401',
          amount: '- Rp ${_formatNumber(amount)}',
          isDebit: true,
          date: 'Hari ini, ${TimeOfDay.now().format(context)}',
          category: 'Penarikan',
          serviceType: 'Bank',
          grossAmount: amount,
          adminFee: 2000,
          netAmount: amount,
        ),
      );
    });

    if (mounted) {
      _showTopSuccessNotification(
        title: 'Penarikan Berhasil',
        message:
            'Penarikan Rp ${_formatNumber(amount)} berhasil diajukan. Saldo diperbarui.',
      );
    }
  }

  void _showTopUpDialog() {
    int selectedAmount = 50000;
    String selectedMethod = 'Virtual Account BSI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Isi Saldo Dompet Driver',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Isi saldo deposit untuk kelancaran penerimaan orderan tunai & talangan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E6A8A),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pilihan Nominal
                    const Text(
                      'Pilih Nominal Top Up',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [20000, 50000, 100000, 200000].map((amt) {
                        final isSelected = selectedAmount == amt;
                        return ChoiceChip(
                          label: Text('Rp ${_formatNumber(amt)}'),
                          selected: isSelected,
                          onSelected: (_) {
                            setModalState(() => selectedAmount = amt);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          backgroundColor: const Color(0xFFF1F1FD),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Metode Transfer
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F6FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DCFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedMethod,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Konfirmasi Top Up
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _currentBalance += selectedAmount;
                            _transactions.insert(
                              0,
                              WalletTransaction(
                                title: 'Top Up Saldo Driver',
                                orderId: 'TOPUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                amount: '+ Rp ${_formatNumber(selectedAmount)}',
                                isDebit: false,
                                date: 'Hari ini, ${TimeOfDay.now().format(context)}',
                                category: 'Pendapatan',
                                serviceType: 'Deposit',
                                netAmount: selectedAmount,
                              ),
                            );
                          });
                          _showTopSuccessNotification(
                            title: 'Top Up Berhasil',
                            message:
                                'Top Up Rp ${_formatNumber(selectedAmount)} berhasil ditambahkan ke saldo aktif!',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Konfirmasi Top Up',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  void _showTransactionDetail(WalletTransaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Rincian Transaksi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tx.status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Rincian
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F6FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2DCFE)),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Jenis Transaksi', tx.title),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Nomor Order / Ref', tx.orderId),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Waktu Transaksi', tx.date),
                      const Divider(height: 20),
                      _buildReceiptRow('Layanan Terkait', tx.serviceType),
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Nominal Transaksi',
                        tx.amount,
                        valueColor: tx.isDebit ? const Color(0xFFE53935) : const Color(0xFF00C853),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17152B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tutup Rincian',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  Widget _buildReceiptRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppColors.dark,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Center(
                  child: Text(
                    'Dompet Driver',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body Content (Scrollable tanpa overscroll stretch / bouncing)
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Card Saldo Aktif Driver
                  _buildBalanceCard(),
                  const SizedBox(height: 12),

                  // 2. Card Transaksi Online
                  _buildOnlineTransactionsCard(),
                  const SizedBox(height: 12),

                  // 3. Banner Klaim Ganti Rugi Pelanggan Batalkan
                  _buildClaimBanner(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar Sesuai Desain Figma
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  /// Card Saldo Aktif Driver
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Expanded(
                child: Text(
                  'Saldo Aktif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9E9DB2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Top Up di sudut kanan atas kartu Saldo Aktif
              InkWell(
                onTap: _showTopUpDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242238),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B68FC), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_circle_outline, size: 12, color: Color(0xFFC6BCFF)),
                      SizedBox(width: 4),
                      Text(
                        'Top Up Saldo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC6BCFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rp ${_formatNumber(_currentBalance)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Row 2 Mini Cards: Pendapatan Ongkir & Refund Talangan
          Row(
            children: [
              // Pendapatan Ongkir
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242238),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pendapatan Ongkir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B68FC),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatNumber(_shippingEarnings)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Refund Talangan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242238),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Refund Talangan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C853),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatNumber(_talanganRefund)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tombol Tarik Uang Anda (Sesuai Desain Figma)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _navigateToWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Tarik Uang Anda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Daftar Transaksi Online
  Widget _buildOnlineTransactionsCard() {
    final filteredTransactions = _selectedFilter == 'Semua'
        ? _transactions
        : _transactions.where((tx) {
            if (_selectedFilter == 'Pendapatan') return !tx.isDebit;
            if (_selectedFilter == 'Biaya Admin') return tx.title.toLowerCase().contains('fee');
            if (_selectedFilter == 'Penarikan') return tx.category == 'Penarikan';
            return true;
          }).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Transaksi Online
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Transaksi online',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips Horizontal (bebas bouncing/overscroll)
          ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: ['Semua', 'Pendapatan', 'Biaya Admin', 'Penarikan'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFF242238),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFF383556),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFFC6BCFF),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // List item transaksi
          if (filteredTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Tidak ada transaksi di kategori $_selectedFilter',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9DB2),
                  ),
                ),
              ),
            )
          else
            ...filteredTransactions.map((tx) => _buildTransactionItem(tx)),
        ],
      ),
    );
  }

  /// Item Baris Transaksi
  Widget _buildTransactionItem(WalletTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionDetail(tx),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.orderId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6E6A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    tx.amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tx.isDebit
                          ? const Color(0xFFE53935) // Merah untuk Fee admin / Debit
                          : const Color(0xFF00C853), // Hijau untuk Ongkos Kirim / Kredit
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner Klaim Ganti Rugi
  Widget _buildClaimBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Batalkan/Penipuan Belanjaan?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ajukan klaim ganti rugi 100%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ClaimTalanganScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF17152B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Klaim Dana ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 13,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
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
              // 1. Radar
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
              // 3. Dompet (Active)
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

/// Banner notifikasi modern mengambang di bagian atas layar (Heads-up pill style)
/// Menggantikan SnackBar bawah yang kaku dan flat dengan visual rounded, shadow, dan gradient.
class _TopNotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopNotificationBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _dismiss,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! < -4) {
                      _dismiss();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00C853),
                          Color(0xFF00963E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF00C853).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF00963E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

