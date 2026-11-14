import 'package:flutter/material.dart';
import '../screens/wallet/wallet_screen.dart';

/// [WalletService]
/// Singleton service untuk mengelola saldo dompet mitra driver, mutasi transaksi,
/// serta sinkronisasi penarikan (withdraw) dan top-up di seluruh alur aplikasi RideOn.
class WalletService extends ChangeNotifier {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal() {
    _resetToDefaults();
  }

  late int _balance;
  late int _shippingEarnings;
  late int _talanganRefund;
  late List<WalletTransaction> _transactions;

  int get balance => _balance;
  int get shippingEarnings => _shippingEarnings;
  int get talanganRefund => _talanganRefund;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void _resetToDefaults() {
    _balance = 327000;
    _shippingEarnings = 45000;
    _talanganRefund = 50000;
    _transactions = [
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

  /// Menjalankan penarikan saldo (Withdraw)
  void withdraw(int amount, {String? orderId, String? timeString}) {
    if (amount <= 0) return;
    _balance = (_balance - amount).clamp(0, 999999999);
    final nowTime = timeString ?? 'Hari ini, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB';
    _transactions.insert(
      0,
      WalletTransaction(
        title: 'Tarik Saldo ke Rekening BSI',
        orderId: orderId ?? 'REF : #99401',
        amount: '- Rp ${_formatNumber(amount)}',
        isDebit: true,
        date: nowTime,
        category: 'Penarikan',
        serviceType: 'Bank',
        grossAmount: amount,
        adminFee: 2000,
        netAmount: amount,
      ),
    );
    notifyListeners();
  }

  /// Menjalankan Top Up saldo
  void topUp(int amount, {String? timeString}) {
    if (amount <= 0) return;
    _balance += amount;
    final nowTime = timeString ?? 'Hari ini, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB';
    _transactions.insert(
      0,
      WalletTransaction(
        title: 'Top Up Saldo Driver',
        orderId: 'REF : #TOPUP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        amount: '+ Rp ${_formatNumber(amount)}',
        isDebit: false,
        date: nowTime,
        category: 'Pendapatan',
        serviceType: 'Deposit',
        grossAmount: amount,
        adminFee: 0,
        netAmount: amount,
      ),
    );
    notifyListeners();
  }

  void setBalance(int balance) {
    _balance = balance;
    notifyListeners();
  }

  void setTransactions(List<WalletTransaction> txs) {
    _transactions = List.from(txs);
    notifyListeners();
  }

  /// Reset untuk pengujian / unit testing
  @visibleForTesting
  void reset({int? balance, int? shippingEarnings, int? talanganRefund, List<WalletTransaction>? transactions}) {
    _resetToDefaults();
    if (balance != null) _balance = balance;
    if (shippingEarnings != null) _shippingEarnings = shippingEarnings;
    if (talanganRefund != null) _talanganRefund = talanganRefund;
    if (transactions != null) _transactions = List.from(transactions);
    notifyListeners();
  }
}
