import 'package:flutter/material.dart';
import '../../data/toko_state.dart';
import '../../theme/app_colors.dart';

class TokoFinanceScreen extends StatefulWidget {
  const TokoFinanceScreen({super.key});

  @override
  State<TokoFinanceScreen> createState() => _TokoFinanceScreenState();
}

class _TokoFinanceScreenState extends State<TokoFinanceScreen> {
  String _activeFilter = 'Semua';

  String _formatRp(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _showTarikSaldoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TarikSaldoSheet(
        maxBalance: TokoState.balance.value,
        activeBank: TokoState.activeBank.value,
        onProceedToPin: (amount) {
          _showPinVerificationDialog(amount);
        },
      ),
    );
  }

  void _showPinVerificationDialog(int amount) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _PinVerificationDialog(
        onVerified: () {
          Navigator.pop(dialogCtx);
          if (amount <= 0 || amount > TokoState.balance.value) return;

          final formatted = _formatRp(amount);
          final now = DateTime.now();
          final hh = now.hour.toString().padLeft(2, '0');
          final mm = now.minute.toString().padLeft(2, '0');
          final txId = '#WD-${now.millisecondsSinceEpoch.toString().substring(7)}';
          final timeStr = 'Hari ini, $hh:$mm WIB';
          final bankName = TokoState.activeBank.value.split(' ').first;

          TokoState.balance.value -= amount;
          TokoState.transactions.value = [
            {
              'title': 'Tarik Saldo Berhasil',
              'subtitle': timeStr,
              'target': 'Ke $bankName',
              'amount': '-Rp $formatted',
              'isNegative': true,
            },
            ...TokoState.transactions.value,
          ];

          _showTarikSuccessDialog(amount, txId, timeStr);
        },
      ),
    );
  }

  void _showTarikSuccessDialog(int amount, String txId, String timeStr) {
    final formatted = _formatRp(amount);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengajuan Tarik Saldo Berhasil!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dana Rp $formatted sedang dikirimkan ke rekening ${TokoState.activeBank.value}. Mohon cek mutasi rekening Anda.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _detailRow('ID Transaksi', txId),
                  const SizedBox(height: 6),
                  _detailRow('Tanggal & Jam', timeStr),
                  const SizedBox(height: 6),
                  _detailRow('Total Ditransfer', 'Rp $formatted', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddBankSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBankSheet(
        ownerName: TokoState.ownerName.value.toUpperCase(),
        onSaved: (bankLabel) {
          TokoState.activeBank.value = bankLabel;
        },
      ),
    );
  }

  void _showFinanceSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pengaturan Keuangan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Rekening Utama', TokoState.activeBank.value, isBold: true),
            const SizedBox(height: 8),
            _detailRow('Jadwal Pencairan', 'Instan (1×24 jam)'),
            const SizedBox(height: 8),
            _detailRow('Min. Tarik Saldo', 'Rp 10.000'),
            const SizedBox(height: 8),
            _detailRow('PIN Keamanan Default', TokoState.securityPin),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: ListenableBuilder tracks TokoState balance, activeBank, and transaction history; upgrade to API pagination when history grows
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            TokoState.balance,
            TokoState.activeBank,
            TokoState.transactions,
          ]),
          builder: (context, _) {
            final formattedBalance = _formatRp(TokoState.balance.value);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Keuangan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textPrimary),
                          onPressed: _showFinanceSettingsDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildBalanceCard(formattedBalance),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat Transaksi',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Semua', 'Masuk', 'Keluar'].map((f) {
                          final isSel = _activeFilter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _activeFilter = f),
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTransactionList(TokoState.transactions.value),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String formattedBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  'Saldo Aktif Toko',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  TokoState.activeBank.value,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rp $formattedBalance',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showTarikSaldoSheet,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text('Tarik Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showAddBankSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> txs) {
    final filteredTxs = txs.where((t) {
      if (_activeFilter == 'Masuk') return !(t['isNegative'] as bool);
      if (_activeFilter == 'Keluar') return (t['isNegative'] as bool);
      return true;
    }).toList();

    if (filteredTxs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Text(
          'Belum ada transaksi pada filter ini',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTxs.length,
      itemBuilder: (context, index) {
        final tx = filteredTxs[index];
        final isNegative = tx['isNegative'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tx['subtitle'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx['amount'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isNegative ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isNegative ? const Color(0xFFF3F4F6) : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tx['target'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isNegative ? AppColors.textSecondary : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TarikSaldoSheet extends StatefulWidget {
  final int maxBalance;
  final String activeBank;
  final ValueChanged<int> onProceedToPin;

  const _TarikSaldoSheet({
    required this.maxBalance,
    required this.activeBank,
    required this.onProceedToPin,
  });

  @override
  State<_TarikSaldoSheet> createState() => _TarikSaldoSheetState();
}

class _TarikSaldoSheetState extends State<_TarikSaldoSheet> {
  late final TextEditingController _amountController;
  String? _amountError;

  String _formatDot(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    final defaultAmt = widget.maxBalance >= 1000000 ? 1000000 : widget.maxBalance;
    _amountController = TextEditingController(text: defaultAmt > 0 ? _formatDot(defaultAmt) : '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tarik Saldo Omzet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rekening Tujuan Pencairan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text(widget.activeBank, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Jumlah Penarikan',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _amountController.text = _formatDot(widget.maxBalance);
                    setState(() => _amountError = null);
                  },
                  child: const Text('Tarik Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
              decoration: InputDecoration(
                prefixText: 'Rp ',
                errorText: _amountError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amt = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  if (amt < 10000) {
                    setState(() => _amountError = 'Minimal penarikan Rp 10.000');
                    return;
                  }
                  if (amt > widget.maxBalance) {
                    setState(() => _amountError = 'Saldo tidak mencukupi');
                    return;
                  }
                  Navigator.pop(context);
                  widget.onProceedToPin(amt);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Konfirmasi & Masukkan PIN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinVerificationDialog extends StatefulWidget {
  final VoidCallback onVerified;

  const _PinVerificationDialog({required this.onVerified});

  @override
  State<_PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<_PinVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verify() {
    final pin = _pinController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _pinError = 'PIN keamanan harus 6 digit angka');
      return;
    }
    if (pin != TokoState.securityPin) {
      setState(() => _pinError = 'PIN keamanan salah (default: ${TokoState.securityPin})');
      return;
    }
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Expanded(
                  child: Text(
                    'Masukkan PIN Keamanan',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                GestureDetector(
                  key: const Key('btn_close_pin_dialog'),
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Masukkan 6 digit PIN toko (default: 123456)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              onChanged: (_) {
                if (_pinError != null) setState(() => _pinError = null);
              },
              style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                errorText: _pinError,
                hintText: '••••••',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.45),
                  fontWeight: FontWeight.normal,
                  letterSpacing: 6,
                ),
                filled: true,
                fillColor: AppColors.primarySoft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _verify,
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text('VERIFIKASI', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBankSheet extends StatefulWidget {
  final String ownerName;
  final ValueChanged<String> onSaved;

  const _AddBankSheet({required this.ownerName, required this.onSaved});

  @override
  State<_AddBankSheet> createState() => _AddBankSheetState();
}

class _AddBankSheetState extends State<_AddBankSheet> {
  String _selectedBank = 'Bank Mandiri (Persero)';
  final TextEditingController _accountNumberController = TextEditingController(text: '1420019283741');
  bool _isMainAccount = true;
  bool _isVerified = false;
  String? _accountError;

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  void _checkAccount() {
    final digits = _accountNumberController.text.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{8,}$').hasMatch(digits)) {
      setState(() {
        _isVerified = false;
        _accountError = 'Nomor rekening minimal 8 digit angka';
      });
      return;
    }
    setState(() {
      _accountError = null;
      _isVerified = true;
    });
  }

  void _saveBank() {
    final digits = _accountNumberController.text.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{8,}$').hasMatch(digits)) {
      setState(() {
        _isVerified = false;
        _accountError = 'Masukkan nomor rekening yang valid (min. 8 digit)';
      });
      return;
    }
    if (!_isVerified) {
      setState(() {
        _accountError = 'Tekan Periksa untuk memverifikasi rekening terlebih dahulu';
      });
      return;
    }

    final cleanBank = _selectedBank.startsWith('Bank ') ? _selectedBank.substring(5) : _selectedBank;
    final shortBank = cleanBank.split(' ').first;
    final lastFour = digits.substring(digits.length - 4);
    if (_isMainAccount) {
      widget.onSaved('$shortBank •••• $lastFour');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rekening $shortBank •••• $lastFour disimpan sebagai rekening cadangan')),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Tambah Rekening Bank',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Pilih Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedBank,
              items: const [
                DropdownMenuItem(value: 'Bank Mandiri (Persero)', child: Text('Bank Mandiri (Persero)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'BCA (Bank Central Asia)', child: Text('BCA (Bank Central Asia)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'BRI (Bank Rakyat Indonesia)', child: Text('BRI (Bank Rakyat Indonesia)', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'BSI (Bank Syariah Indonesia)', child: Text('BSI (Bank Syariah Indonesia)', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBank = val;
                    _isVerified = false;
                  });
                }
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Nomor Rekening', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {
                        _isVerified = false;
                        _accountError = null;
                      });
                    },
                    decoration: InputDecoration(
                      errorText: _accountError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _checkAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Periksa', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (_isVerified) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nama Pemilik: ${widget.ownerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                          const Text('Rekening terverifikasi dan sesuai dengan data pemilik toko.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Jadikan Rekening Utama', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Hasil pencairan saldo akan otomatis masuk ke rekening ini', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isMainAccount,
                  onChanged: (val) => setState(() => _isMainAccount = val),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveBank,
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Simpan Rekening', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
