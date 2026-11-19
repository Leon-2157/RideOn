import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StoreOrderItem {
  final String id;
  final String itemName;
  final int qty;
  final int unitPrice;
  final int subtotal;
  final String notes;

  const StoreOrderItem({
    required this.id,
    required this.itemName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
    this.notes = '',
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    return StoreOrderItem(
      id: (json['id'] ?? '').toString(),
      itemName: (json['item_name'] ?? json['name'] ?? '').toString(),
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_name': itemName,
        'qty': qty,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'notes': notes,
      };
}

class StoreOrderModel {
  final String id;
  final String orderCode;
  final String serviceType;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String customerName;
  final String customerPhone;
  final String driverName;
  final String dropoffAddress;
  final int itemsSubtotal;
  final int deliveryFee;
  final int totalCustomerPay;
  final int platformCommissionStore;
  final String createdAt;
  final List<StoreOrderItem> items;

  const StoreOrderModel({
    required this.id,
    required this.orderCode,
    required this.serviceType,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.customerName,
    required this.customerPhone,
    required this.driverName,
    required this.dropoffAddress,
    required this.itemsSubtotal,
    required this.deliveryFee,
    required this.totalCustomerPay,
    required this.platformCommissionStore,
    required this.createdAt,
    required this.items,
  });

  String get tabBucket {
    switch (status.toUpperCase()) {
      case 'CREATED':
      case 'WAITING_STORE_CONFIRM':
        return 'baru';
      case 'COMPLETED':
        return 'selesai';
      case 'CANCELLED':
        return 'batal';
      default:
        return 'diproses';
    }
  }

  factory StoreOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    return StoreOrderModel(
      id: (json['id'] ?? '').toString(),
      orderCode: (json['order_code'] ?? json['id'] ?? '').toString(),
      serviceType: (json['service_type'] ?? 'FLEX_FOOD').toString(),
      status: (json['status'] ?? 'WAITING_STORE_CONFIRM').toString(),
      paymentMethod: (json['payment_method'] ?? 'CASH').toString(),
      paymentStatus: (json['payment_status'] ?? 'UNPAID').toString(),
      customerName: (json['customer_name'] ?? 'Pelanggan RideOn').toString(),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      driverName: (json['driver_name'] ?? '').toString(),
      dropoffAddress: (json['dropoff_address'] ?? '').toString(),
      itemsSubtotal: (json['items_subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 0,
      totalCustomerPay: (json['total_customer_pay'] as num?)?.toInt() ?? 0,
      platformCommissionStore: (json['platform_commission_store'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(StoreOrderItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_code': orderCode,
        'service_type': serviceType,
        'status': status,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'driver_name': driverName,
        'dropoff_address': dropoffAddress,
        'items_subtotal': itemsSubtotal,
        'delivery_fee': deliveryFee,
        'total_customer_pay': totalCustomerPay,
        'platform_commission_store': platformCommissionStore,
        'created_at': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };

  static String _fmtRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Map<String, dynamic> toScreenMap() {
    final tab = tabBucket;
    final itemsSummary = items.isNotEmpty
        ? items.map((i) => '${i.qty}× ${i.itemName}').join(', ')
        : 'Pesanan $orderCode';
    final itemDetails = items
        .map((i) => <String, dynamic>{
              'name': '${i.qty}× ${i.itemName}',
              'price': _fmtRp(i.subtotal > 0 ? i.subtotal : i.unitPrice * i.qty),
              'basePrice': _fmtRp(i.unitPrice),
              'tags': i.notes.isNotEmpty ? [i.notes] : ['Menu Toko'],
            })
        .toList();

    String statusLabel = 'Perlu Konfirmasi';
    Color statusColor = const Color(0xFFC2410C);
    Color statusBg = const Color(0xFFFFEDD5);
    String driverNote = 'Menunggu konfirmasi toko';

    if (tab == 'diproses') {
      statusLabel = status == 'SEARCHING_DRIVER'
          ? 'Mencari Kurir'
          : (status == 'IN_TRANSIT' ? 'Dalam Pengantaran' : 'Siap Diambil');
      statusColor = AppColors.primary;
      statusBg = AppColors.primarySoft;
      driverNote = driverName.isNotEmpty ? 'Kurir: $driverName' : 'Mencari driver terdekat';
    } else if (tab == 'selesai') {
      statusLabel = 'Pesanan Selesai';
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
      driverNote = 'Pesanan selesai diantar';
    } else if (tab == 'batal') {
      statusLabel = 'Dibatalkan';
      statusColor = AppColors.danger;
      statusBg = AppColors.dangerLight;
      driverNote = 'Pesanan dibatalkan';
    }

    final displayAmount = itemsSubtotal > 0 ? itemsSubtotal : totalCustomerPay;
    final map = <String, dynamic>{
      'id': orderCode.isNotEmpty ? orderCode : id,
      'apiId': id,
      'rawStatus': status,
      'tab': tab,
      'status': statusLabel,
      'statusColor': statusColor,
      'statusBg': statusBg,
      'items': itemsSummary,
      'itemDetails': itemDetails,
      'price': _fmtRp(displayAmount),
      'driverStatus': driverNote,
      'customerName': customerName,
      'buyerNote': items.map((e) => e.notes).where((n) => n.isNotEmpty).join('; '),
      'payment': paymentMethod == 'QRIS' ? 'QRIS ($paymentStatus)' : 'Tunai / COD',
    };
    if (driverName.isNotEmpty) {
      map['driverName'] = driverName;
    }
    return map;
  }
}

