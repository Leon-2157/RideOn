class CustomerUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String avatarUrl;

  const CustomerUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl = '',
  });

  factory CustomerUser.fromJson(Map<String, dynamic> j) => CustomerUser(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        role: (j['role'] ?? 'CUSTOMER').toString(),
        status: (j['status'] ?? 'ACTIVE').toString(),
        avatarUrl: (j['avatar_url'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'avatar_url': avatarUrl,
      };
}

class PublicMenuItem {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final String category;
  final int price;
  final String photoUrl;
  final bool isAvailable;
  final int stock;
  final String storeName;
  final String storeAddress;
  final double storeLat;
  final double storeLng;
  final bool storeIsOpen;
  final double ratingAvg;
  final int soldCount;

  const PublicMenuItem({
    required this.id,
    required this.storeId,
    required this.name,
    this.description = '',
    this.category = 'Makanan',
    required this.price,
    this.photoUrl = '',
    this.isAvailable = true,
    this.stock = 100,
    this.storeName = '',
    this.storeAddress = '',
    this.storeLat = 5.2041,
    this.storeLng = 97.0638,
    this.storeIsOpen = true,
    this.ratingAvg = 4.8,
    this.soldCount = 0,
  });

  factory PublicMenuItem.fromJson(Map<String, dynamic> j) => PublicMenuItem(
        id: (j['id'] ?? '').toString(),
        storeId: (j['store_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        category: (j['category'] ?? 'Makanan').toString(),
        price: (j['price'] as num?)?.toInt() ?? 0,
        photoUrl: (j['photo_url'] ?? '').toString(),
        isAvailable: j['is_available'] != false,
        stock: (j['stock'] as num?)?.toInt() ?? 100,
        storeName: (j['store_name'] ?? '').toString(),
        storeAddress: (j['store_address'] ?? '').toString(),
        storeLat: (j['store_lat'] as num?)?.toDouble() ?? 5.2041,
        storeLng: (j['store_lng'] as num?)?.toDouble() ?? 97.0638,
        storeIsOpen: j['store_is_open'] != false,
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 4.8,
        soldCount: (j['sold_count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'photo_url': photoUrl,
        'is_available': isAvailable,
        'stock': stock,
        'store_name': storeName,
        'store_address': storeAddress,
        'store_lat': storeLat,
        'store_lng': storeLng,
        'store_is_open': storeIsOpen,
        'rating_avg': ratingAvg,
        'sold_count': soldCount,
      };
}

class PublicStore {
  final String id;
  final String userId;
  final String storeName;
  final String category;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final String bannerUrl;
  final String logoUrl;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final double ratingAvg;
  final List<PublicMenuItem> menus;

  const PublicStore({
    required this.id,
    this.userId = '',
    required this.storeName,
    this.category = 'Kuliner',
    this.description = '',
    this.address = '',
    this.lat = 5.2041,
    this.lng = 97.0638,
    this.bannerUrl = '',
    this.logoUrl = '',
    this.isOpen = true,
    this.openTime = '08:00',
    this.closeTime = '22:00',
    this.ratingAvg = 4.8,
    this.menus = const [],
  });

  factory PublicStore.fromJson(Map<String, dynamic> j) => PublicStore(
        id: (j['id'] ?? '').toString(),
        userId: (j['user_id'] ?? '').toString(),
        storeName: (j['store_name'] ?? '').toString(),
        category: (j['category'] ?? 'Kuliner').toString(),
        description: (j['description'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        lat: (j['lat'] as num?)?.toDouble() ?? 5.2041,
        lng: (j['lng'] as num?)?.toDouble() ?? 97.0638,
        bannerUrl: (j['banner_url'] ?? '').toString(),
        logoUrl: (j['logo_url'] ?? '').toString(),
        isOpen: j['is_open'] != false,
        openTime: (j['open_time'] ?? '08:00').toString(),
        closeTime: (j['close_time'] ?? '22:00').toString(),
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 4.8,
        menus: (j['menus'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PublicMenuItem.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'store_name': storeName,
        'category': category,
        'description': description,
        'address': address,
        'lat': lat,
        'lng': lng,
        'banner_url': bannerUrl,
        'logo_url': logoUrl,
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
        'rating_avg': ratingAvg,
        'menus': menus.map((e) => e.toJson()).toList(),
      };
}

class PromotionItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType;
  final int discountValue;
  final int minOrderAmount;
  final int maxDiscountAmount;
  final bool isActive;
  final String endAt;

  const PromotionItem({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    this.discountType = 'FIXED',
    this.discountValue = 0,
    this.minOrderAmount = 0,
    this.maxDiscountAmount = 0,
    this.isActive = true,
    this.endAt = '',
  });

  factory PromotionItem.fromJson(Map<String, dynamic> j) => PromotionItem(
        id: (j['id'] ?? '').toString(),
        code: (j['code'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        discountType: (j['discount_type'] ?? 'FIXED').toString(),
        discountValue: (j['discount_value'] as num?)?.toInt() ?? 0,
        minOrderAmount: (j['min_order_amount'] as num?)?.toInt() ?? 0,
        maxDiscountAmount: (j['max_discount_amount'] as num?)?.toInt() ?? 0,
        isActive: j['is_active'] != false,
        endAt: (j['end_at'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount_amount': maxDiscountAmount,
        'is_active': isActive,
        'end_at': endAt,
      };
}

class CustomerOrderItem {
  final String menuId;
  final String itemName;
  final int unitPrice;
  final int qty;
  final int subtotal;
  final String notes;

  const CustomerOrderItem({
    this.menuId = '',
    required this.itemName,
    required this.unitPrice,
    required this.qty,
    this.subtotal = 0,
    this.notes = '',
  });

  factory CustomerOrderItem.fromJson(Map<String, dynamic> j) =>
      CustomerOrderItem(
        menuId: (j['menu_id'] ?? '').toString(),
        itemName: (j['item_name'] ?? j['name'] ?? '').toString(),
        unitPrice: (j['unit_price'] as num?)?.toInt() ?? 0,
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        subtotal: (j['subtotal'] as num?)?.toInt() ?? 0,
        notes: (j['notes'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'item_name': itemName,
      'unit_price': unitPrice,
      'qty': qty,
      'notes': notes,
    };
    if (menuId.isNotEmpty) map['menu_id'] = menuId;
    return map;
  }
}

class CustomerOrder {
  final String id;
  final String orderCode;
  final String serviceType;
  final String vehicleType;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String customerId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverPlate;
  final String storeId;
  final String storeName;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int durationMin;
  final int deliveryFee;
  final int itemsSubtotal;
  final int talanganEstAmount;
  final int talanganActualAmount;
  final int parkingFee;
  final int discountAmount;
  final int totalCustomerPay;
  final String createdAt;
  final List<CustomerOrderItem> items;

  const CustomerOrder({
    required this.id,
    this.orderCode = '',
    required this.serviceType,
    this.vehicleType = 'MOTOR',
    required this.status,
    this.paymentMethod = 'CASH',
    this.paymentStatus = 'UNPAID',
    this.customerId = '',
    this.driverId = '',
    this.driverName = '',
    this.driverPhone = '',
    this.driverPlate = '',
    this.storeId = '',
    this.storeName = '',
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.distanceKm = 0,
    this.durationMin = 0,
    this.deliveryFee = 0,
    this.itemsSubtotal = 0,
    this.talanganEstAmount = 0,
    this.talanganActualAmount = 0,
    this.parkingFee = 0,
    this.discountAmount = 0,
    this.totalCustomerPay = 0,
    this.createdAt = '',
    this.items = const [],
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
        id: (j['id'] ?? '').toString(),
        orderCode: (j['order_code'] ?? '').toString(),
        serviceType: (j['service_type'] ?? 'FLEX_FOOD').toString(),
        vehicleType: (j['vehicle_type'] ?? 'MOTOR').toString(),
        status: (j['status'] ?? '').toString(),
        paymentMethod: (j['payment_method'] ?? 'CASH').toString(),
        paymentStatus: (j['payment_status'] ?? 'UNPAID').toString(),
        customerId: (j['customer_id'] ?? '').toString(),
        driverId: (j['driver_id'] ?? '').toString(),
        driverName: (j['driver_name'] ?? '').toString(),
        driverPhone: (j['driver_phone'] ?? '').toString(),
        driverPlate: (j['driver_plate'] ?? '').toString(),
        storeId: (j['store_id'] ?? '').toString(),
        storeName: (j['store_name'] ?? '').toString(),
        pickupAddress: (j['pickup_address'] ?? '').toString(),
        dropoffAddress:
            (j['dropoff_address'] ?? j['delivery_address'] ?? '').toString(),
        distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
        durationMin: (j['duration_min'] as num?)?.toInt() ?? 0,
        deliveryFee: (j['delivery_fee'] as num?)?.toInt() ?? 0,
        itemsSubtotal: (j['items_subtotal'] as num?)?.toInt() ??
            (j['subtotal_items'] as num?)?.toInt() ??
            0,
        talanganEstAmount: (j['talangan_est_amount'] as num?)?.toInt() ?? 0,
        talanganActualAmount:
            (j['talangan_actual_amount'] as num?)?.toInt() ?? 0,
        parkingFee: (j['parking_fee'] as num?)?.toInt() ?? 0,
        discountAmount: (j['discount_amount'] as num?)?.toInt() ?? 0,
        totalCustomerPay: (j['total_customer_pay'] as num?)?.toInt() ?? 0,
        createdAt: (j['created_at'] ?? '').toString(),
        items: (j['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CustomerOrderItem.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_code': orderCode,
        'service_type': serviceType,
        'vehicle_type': vehicleType,
        'status': status,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'customer_id': customerId,
        'driver_id': driverId,
        'driver_name': driverName,
        'store_id': storeId,
        'store_name': storeName,
        'pickup_address': pickupAddress,
        'dropoff_address': dropoffAddress,
        'distance_km': distanceKm,
        'duration_min': durationMin,
        'delivery_fee': deliveryFee,
        'items_subtotal': itemsSubtotal,
        'talangan_est_amount': talanganEstAmount,
        'talangan_actual_amount': talanganActualAmount,
        'parking_fee': parkingFee,
        'discount_amount': discountAmount,
        'total_customer_pay': totalCustomerPay,
        'created_at': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class OrderEstimate {
  final String serviceType;
  final String vehicleType;
  final double distanceKm;
  final int durationMin;
  final int deliveryFee;
  final int itemsSubtotal;
  final int talanganEstAmount;
  final int discountAmount;
  final int totalCustomerPay;

  const OrderEstimate({
    required this.serviceType,
    required this.vehicleType,
    this.distanceKm = 0,
    this.durationMin = 0,
    this.deliveryFee = 0,
    this.itemsSubtotal = 0,
    this.talanganEstAmount = 0,
    this.discountAmount = 0,
    this.totalCustomerPay = 0,
  });

  factory OrderEstimate.fromJson(Map<String, dynamic> j) => OrderEstimate(
        serviceType: (j['service_type'] ?? 'RIDE_MOTOR').toString(),
        vehicleType: (j['vehicle_type'] ?? 'MOTOR').toString(),
        distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
        durationMin: (j['duration_min'] as num?)?.toInt() ?? 0,
        deliveryFee: (j['delivery_fee'] as num?)?.toInt() ?? 0,
        itemsSubtotal: (j['items_subtotal'] as num?)?.toInt() ?? 0,
        talanganEstAmount: (j['talangan_est_amount'] as num?)?.toInt() ?? 0,
        discountAmount: (j['discount_amount'] as num?)?.toInt() ?? 0,
        totalCustomerPay: (j['total_customer_pay'] as num?)?.toInt() ?? 0,
      );
}

class QrisPaymentResult {
  final String id;
  final String referenceId;
  final String orderId;
  final String purpose;
  final int baseAmount;
  final int uniqueCode;
  final int payableAmount;
  final String qrisPayload;
  final String qrSvg;
  final String status;
  final String expiresAt;

  const QrisPaymentResult({
    required this.id,
    required this.referenceId,
    this.orderId = '',
    this.purpose = 'ORDER_PAYMENT',
    this.baseAmount = 0,
    this.uniqueCode = 0,
    this.payableAmount = 0,
    this.qrisPayload = '',
    this.qrSvg = '',
    this.status = 'PENDING',
    this.expiresAt = '',
  });

  bool get isPaid {
    final up = status.toUpperCase();
    return up == 'PAID' || up == 'SETTLEMENT';
  }

  factory QrisPaymentResult.fromJson(Map<String, dynamic> j) =>
      QrisPaymentResult(
        id: (j['id'] ?? '').toString(),
        referenceId: (j['reference_id'] ?? '').toString(),
        orderId: (j['order_id'] ?? '').toString(),
        purpose: (j['purpose'] ?? 'ORDER_PAYMENT').toString(),
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

class UserFavorite {
  final String id;
  final String userId;
  final String targetType;
  final String storeId;
  final String menuId;
  final String createdAt;

  const UserFavorite({
    required this.id,
    required this.userId,
    required this.targetType,
    this.storeId = '',
    this.menuId = '',
    this.createdAt = '',
  });

  factory UserFavorite.fromJson(Map<String, dynamic> j) => UserFavorite(
        id: (j['id'] ?? '').toString(),
        userId: (j['user_id'] ?? '').toString(),
        targetType: (j['target_type'] ?? 'MENU').toString(),
        storeId: (j['store_id'] ?? '').toString(),
        menuId: (j['menu_id'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
      );
}

