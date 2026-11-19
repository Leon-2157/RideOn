class OrderItem {
  final String name;
  final int qty;
  final int price;

  const OrderItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: (j['item_name'] ?? j['name'] ?? '').toString(),
        qty: (j['qty'] as num?)?.toInt() ??
            (j['quantity'] as num?)?.toInt() ??
            1,
        price: (j['unit_price'] as num?)?.toInt() ??
            (j['price'] as num?)?.toInt() ??
            0,
      );

  Map<String, dynamic> toJson() => {
        'item_name': name,
        'qty': qty,
        'unit_price': price,
      };
}

class OrderModel {
  final String id;
  final String orderCode;
  final String serviceType;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final String storeName;
  final int subtotal;
  final int deliveryFee;
  final int totalPrice;
  final double distanceKm;
  final int driverCommission;
  final int driverNetEarning;
  final int talanganEstAmount;
  final int talanganActualAmount;
  final int parkingFee;
  final String createdAt;
  final List<OrderItem> items;

  const OrderModel({
    required this.id,
    this.orderCode = '',
    required this.serviceType,
    required this.status,
    this.paymentMethod = 'CASH',
    this.paymentStatus = 'UNPAID',
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.storeName,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalPrice,
    required this.distanceKm,
    required this.driverCommission,
    required this.driverNetEarning,
    this.talanganEstAmount = 0,
    this.talanganActualAmount = 0,
    this.parkingFee = 0,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List? ?? [];
    final store = j['store'] is Map ? j['store'] as Map : null;
    final customer = j['customer'] is Map ? j['customer'] as Map : null;

    return OrderModel(
      id: (j['id'] ?? '').toString(),
      orderCode: (j['order_code'] ?? '').toString(),
      serviceType: (j['service_type'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      paymentMethod: (j['payment_method'] ?? 'CASH').toString(),
      paymentStatus: (j['payment_status'] ?? 'UNPAID').toString(),
      customerName:
          (j['customer_name'] ?? customer?['name'] ?? '').toString(),
      customerPhone:
          (j['customer_phone'] ?? customer?['phone'] ?? '').toString(),
      pickupAddress: (j['pickup_address'] ?? '').toString(),
      deliveryAddress:
          (j['dropoff_address'] ?? j['delivery_address'] ?? '').toString(),
      storeName: (j['store_name'] ?? store?['name'] ?? '').toString(),
      subtotal: (j['subtotal_items'] as num?)?.toInt() ??
          (j['subtotal'] as num?)?.toInt() ??
          0,
      deliveryFee: (j['delivery_fee'] as num?)?.toInt() ?? 0,
      totalPrice: (j['total_customer_pay'] as num?)?.toInt() ??
          (j['total_price'] as num?)?.toInt() ??
          0,
      distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0.0,
      driverCommission:
          (j['platform_commission_driver'] as num?)?.toInt() ??
              (j['driver_commission'] as num?)?.toInt() ??
              0,
      driverNetEarning: (j['driver_net_earning'] as num?)?.toInt() ?? 0,
      talanganEstAmount: (j['talangan_est_amount'] as num?)?.toInt() ?? 0,
      talanganActualAmount:
          (j['talangan_actual_amount'] as num?)?.toInt() ?? 0,
      parkingFee: (j['parking_fee'] as num?)?.toInt() ?? 0,
      createdAt: (j['created_at'] ?? '').toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
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
        'pickup_address': pickupAddress,
        'dropoff_address': deliveryAddress,
        'store_name': storeName,
        'subtotal_items': subtotal,
        'delivery_fee': deliveryFee,
        'total_customer_pay': totalPrice,
        'distance_km': distanceKm,
        'platform_commission_driver': driverCommission,
        'driver_net_earning': driverNetEarning,
        'talangan_est_amount': talanganEstAmount,
        'talangan_actual_amount': talanganActualAmount,
        'parking_fee': parkingFee,
        'created_at': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };

  bool get isFlexFood =>
      serviceType == 'FLEX_FOOD' || serviceType == 'FLEXFOOD';
  bool get isFlexRide =>
      serviceType == 'FLEX_RIDE' || serviceType == 'FLEXRIDE';
  bool get isFlexSend =>
      serviceType == 'FLEX_SEND' || serviceType == 'FLEXSEND';
  bool get isCompleted => status == 'COMPLETED' || status == 'COMPLETE';
  bool get isCancelled => status == 'CANCELLED';
  bool get isSearchingDriver => status == 'SEARCHING_DRIVER';
}
