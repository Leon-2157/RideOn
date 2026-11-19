class StoreWalletTx {
  final String id;
  final String txType;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String referenceType;
  final String referenceId;
  final String description;
  final String createdAt;

  const StoreWalletTx({
    required this.id,
    required this.txType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.referenceType,
    required this.referenceId,
    required this.description,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;

  factory StoreWalletTx.fromJson(Map<String, dynamic> json) {
    return StoreWalletTx(
      id: (json['id'] ?? '').toString(),
      txType: (json['tx_type'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceBefore: (json['balance_before'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
      referenceType: (json['reference_type'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toScreenMap() {
    final absAmt = amount.abs();
    final formatted = absAmt.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    final isNeg = amount < 0;
    final shortDate = createdAt.length >= 16 ? createdAt.substring(0, 16).replaceFirst('T', ' • ') : createdAt;
    return {
      'title': description.isNotEmpty ? description : txType,
      'subtitle': shortDate.isNotEmpty ? shortDate : referenceId,
      'target': isNeg ? 'Keluar' : 'Masuk',
      'amount': '${isNeg ? '-' : '+'}Rp $formatted',
      'isNegative': isNeg,
    };
  }
}

class StoreWalletModel {
  final String id;
  final String ownerType;
  final String ownerId;
  final int balance;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountHolder;
  final List<StoreWalletTx> transactions;

  const StoreWalletModel({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.balance,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountHolder,
    required this.transactions,
  });

  factory StoreWalletModel.fromJson(Map<String, dynamic> json) {
    final wRaw = json['wallet'];
    final map = wRaw is Map<String, dynamic> ? wRaw : json;
    final txListRaw = (map['transactions'] as List<dynamic>?) ??
        (json['transactions'] as List<dynamic>?) ??
        const [];
    return StoreWalletModel(
      id: (map['id'] ?? '').toString(),
      ownerType: (map['owner_type'] ?? 'STORE').toString(),
      ownerId: (map['owner_id'] ?? '').toString(),
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      bankName: (map['bank_name'] ?? 'BSI').toString(),
      bankAccountNumber: (map['bank_account_number'] ?? '').toString(),
      bankAccountHolder: (map['bank_account_holder'] ?? '').toString(),
      transactions: txListRaw
          .whereType<Map<String, dynamic>>()
          .map(StoreWalletTx.fromJson)
          .toList(),
    );
  }
}

