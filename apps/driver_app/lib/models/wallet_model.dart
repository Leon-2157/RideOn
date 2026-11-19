class WalletModel {
  final String id;
  final String ownerType;
  final String ownerId;
  final int balance;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountHolder;

  const WalletModel({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.balance,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountHolder,
  });

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
        id: (j['id'] ?? '').toString(),
        ownerType: (j['owner_type'] ?? 'DRIVER').toString(),
        ownerId: (j['owner_id'] ?? '').toString(),
        balance: (j['balance'] as num?)?.toInt() ?? 0,
        bankName: (j['bank_name'] ?? '').toString(),
        bankAccountNumber: (j['bank_account_number'] ?? '').toString(),
        bankAccountHolder: (j['bank_account_holder'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_type': ownerType,
        'owner_id': ownerId,
        'balance': balance,
        'bank_name': bankName,
        'bank_account_number': bankAccountNumber,
        'bank_account_holder': bankAccountHolder,
      };

  bool get canWithdraw => balance >= 20000;
  bool get isNegative => balance < 0;
  bool get isAtNegativeLimit => balance <= -20000;
}

class WalletTransaction {
  final String id;
  final String type;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String referenceType;
  final String referenceId;
  final String description;
  final String createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceBefore = 0,
    required this.balanceAfter,
    this.referenceType = '',
    this.referenceId = '',
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) =>
      WalletTransaction(
        id: (j['id'] ?? '').toString(),
        type: (j['tx_type'] ?? j['type'] ?? '').toString(),
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        balanceBefore: (j['balance_before'] as num?)?.toInt() ?? 0,
        balanceAfter: (j['balance_after'] as num?)?.toInt() ?? 0,
        referenceType: (j['reference_type'] ?? '').toString(),
        referenceId: (j['reference_id'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
      );

  bool get isCredit {
    final upper = type.toUpperCase();
    if (upper == 'CREDIT' ||
        upper.contains('TOPUP') ||
        upper.contains('EARNING') ||
        upper.contains('REIMBURSE')) {
      return true;
    }
    if (upper == 'DEBIT' ||
        upper.contains('WITHDRAW') ||
        upper.contains('COMMISSION')) {
      return false;
    }
    return amount >= 0;
  }

  String get category {
    final upper = type.toUpperCase();
    if (upper.contains('COMMISSION') || upper == 'FEE') return 'Fee admin';
    if (upper.contains('WITHDRAW')) return 'Penarikan';
    if (upper.contains('TOPUP')) return 'Top Up';
    if (upper.contains('REIMBURSE') || upper.contains('REFUND')) return 'Refund';
    return 'Pendapatan';
  }
}

class QrisTopUpResult {
  final String id;
  final String referenceId;
  final int baseAmount;
  final int uniqueCode;
  final int payableAmount;
  final String qrisPayload;
  final String qrSvg;
  final String status;
  final String expiresAt;

  const QrisTopUpResult({
    required this.id,
    required this.referenceId,
    required this.baseAmount,
    required this.uniqueCode,
    required this.payableAmount,
    required this.qrisPayload,
    this.qrSvg = '',
    required this.status,
    required this.expiresAt,
  });

  factory QrisTopUpResult.fromJson(Map<String, dynamic> j) => QrisTopUpResult(
        id: (j['id'] ?? '').toString(),
        referenceId: (j['reference_id'] ?? '').toString(),
        baseAmount: (j['base_amount'] as num?)?.toInt() ?? 0,
        uniqueCode: (j['unique_code'] as num?)?.toInt() ?? 0,
        payableAmount: (j['payable_amount'] as num?)?.toInt() ??
            (j['amount'] as num?)?.toInt() ??
            0,
        qrisPayload: (j['qris_payload'] ?? '').toString(),
        qrSvg: (j['qr_svg'] ?? '').toString(),
        status: (j['status'] ?? 'PENDING').toString(),
        expiresAt: (j['expires_at'] ?? '').toString(),
      );
}
