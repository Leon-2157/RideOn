import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

/// [WithdrawScreen]
/// Layar Tarik Saldo Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanDompet/dompet-7.png s/d dompet-18.png
/// Menggunakan pemanggilan keyboard HP native (TextInputType.number)
class WithdrawScreen extends StatefulWidget {
  final int initialBalance;
  final String bankName;
  final String accountNumber;
  final ValueChanged<int>? onWithdrawSuccess;

  const WithdrawScreen({
    super.key,
    this.initialBalance = 327000,
    this.bankName = 'Bank Syariah Indonesia (BSI)',
    this.accountNumber = '8820-1928-34 a.n Joni Utama',
    this.onWithdrawSuccess,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  String _amount = '';
  final int _adminFee = 2000;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _setAmount(int val) {
    final text = val.toString();
    setState(() {
      _amount = text;
      _amountController.text = text;
      _amountController.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  String _formatCurrency(String raw) {
    if (raw.isEmpty) return '0';
    final n = int.tryParse(raw) ?? 0;
    return _formatNumber(n);
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

  void _showPinDialog() {
    _amountFocusNode.unfocus();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (context) {
        return _PinEntryDialog(
          amount: _amount,
          onPinSubmitted: () {
            Navigator.of(context).pop(); // Tutup dialog PIN
            _showSuccessDialog();
          },
        );
      },
    );
  }

  void _showSuccessDialog() {
    final transferTotal = _formatCurrency(_amount);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF6EE7B7), width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF00C853),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pengajuan Tarik Saldo Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dana Rp $transferTotal sedang dikirimkan ke rekening BSI 8820192834. Mohon cek mutasi rekening Anda.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E6A8A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F6FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('ID Transaksi', '#99401'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Tanggal & Jam', '5 Okt 2026 13:02 WIB'),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Total Ditransfer',
                        'Rp $transferTotal',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Selesai
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final int parsed = int.tryParse(_amount) ?? 0;
                      if (widget.onWithdrawSuccess != null && parsed > 0) {
                        widget.onWithdrawSuccess!(parsed);
                      }
                      Navigator.of(context).pop(); // tutup modal
                      Navigator.of(context).pop(parsed); // kembali ke dompet dengan membawa nominal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17152B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6A8A),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAmount = _amount.isNotEmpty && (int.tryParse(_amount) ?? 0) > 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // Header Bar
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.dark,
                          size: 22,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Tarik Saldo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Rekening Bank Tujuan Pencairan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rekening Bank Tujuan Pencairan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F0FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: Color(0xFF4A4468),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.bankName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.accountNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6E6A8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Card Jumlah Penarikan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6B48FC),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Jumlah Penarikan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _setAmount(widget.initialBalance),
                              child: const Text(
                                'Tarik Semua',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Display nominal box with native phone keyboard input
                        GestureDetector(
                          onTap: () => _amountFocusNode.requestFocus(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F6FD),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Rp ',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dark,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    focusNode: _amountFocusNode,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(9),
                                    ],
                                    onChanged: (val) {
                                      String cleaned = val;
                                      if (cleaned.length > 1 && cleaned.startsWith('0')) {
                                        cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
                                        _amountController.text = cleaned;
                                        _amountController.selection = TextSelection.collapsed(offset: cleaned.length);
                                      }
                                      setState(() {
                                        _amount = cleaned;
                                      });
                                    },
                                    onSubmitted: (_) {
                                      if (hasAmount) {
                                        _showPinDialog();
                                      }
                                    },
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.dark,
                                    ),
                                    cursorColor: const Color(0xFF6B48FC),
                                    cursorWidth: 2,
                                    cursorHeight: 24,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'saldo yang bisa tarik: Rp ${_formatNumber(widget.initialBalance)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6E6A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Nominal Chips
                  Row(
                    children: [
                      _buildNominalChip(1000000, 'Rp 1000.000'),
                      const SizedBox(width: 8),
                      _buildNominalChip(500000, 'Rp 500.000'),
                      const SizedBox(width: 8),
                      _buildNominalChip(250000, 'Rp 250.000'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Card Biaya Layanan & Estimasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8E5FB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Biaya Layanan Penarikan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                            Text(
                              'Rp ${_formatNumber(_adminFee)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00C853),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Estimasi Dana Masuk',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                            Text(
                              'Instan (15 Menit)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (hasAmount) {
                  _showPinDialog();
                } else {
                  _amountFocusNode.requestFocus();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17152B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                hasAmount ? 'Konfirmasi & Masukkan PIN' : 'Masukan Nominal',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNominalChip(int val, String label) {
    final bool isSelected = _amount == val.toString();
    return Expanded(
      child: InkWell(
        onTap: () => _setAmount(val),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAE6FE) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6B48FC) : const Color(0xFFE8E5FB),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF6B48FC) : AppColors.dark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [_PinEntryDialog]
/// Dialog konfirmasi PIN 6-digit sesuai `dompet-16.png`
class _PinEntryDialog extends StatefulWidget {
  final String amount;
  final VoidCallback onPinSubmitted;

  const _PinEntryDialog({
    required this.amount,
    required this.onPinSubmitted,
  });

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan Sandi Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masukan sandi bank anda',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6E6A8A),
              ),
            ),
            const SizedBox(height: 20),

            // 6-digit display container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE6FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  final text = _pinController.text;
                  final char = (index < text.length) ? text[index] : '';
                  return Text(
                    char,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Kirim
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onPinSubmitted,
                icon: const Icon(
                  Icons.send,
                  size: 16,
                  color: AppColors.white,
                ),
                label: const Text(
                  'KIRIM',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17152B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
