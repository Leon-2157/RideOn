class StoreProfile {
  final String id;
  final String storeName;
  final String category;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final double ratingAvg;
  final int walletBalance;

  const StoreProfile({
    required this.id,
    required this.storeName,
    required this.category,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    required this.ratingAvg,
    required this.walletBalance,
  });

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      id: (json['id'] ?? '').toString(),
      storeName: (json['store_name'] ?? 'Toko RideOn').toString(),
      category: (json['category'] ?? 'Kuliner').toString(),
      description: (json['description'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      lat: (json['lat'] as num?)?.toDouble() ?? 5.1801,
      lng: (json['lng'] as num?)?.toDouble() ?? 97.1507,
      isOpen: json['is_open'] == true || json['is_open'] == 1,
      openTime: (json['open_time'] ?? '08:00').toString(),
      closeTime: (json['close_time'] ?? '22:00').toString(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 5.0,
      walletBalance: (json['wallet_balance'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_name': storeName,
        'category': category,
        'description': description,
        'address': address,
        'lat': lat,
        'lng': lng,
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
        'rating_avg': ratingAvg,
        'wallet_balance': walletBalance,
      };
}

class StoreUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String avatarUrl;
  final StoreProfile? store;

  const StoreUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.avatarUrl,
    this.store,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPendingApproval => status == 'PENDING_APPROVAL';

  factory StoreUser.fromJson(Map<String, dynamic> json) {
    final storeRaw = json['store'];
    return StoreUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'STORE').toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      store: storeRaw is Map<String, dynamic> ? StoreProfile.fromJson(storeRaw) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
    };
    if (store != null) {
      map['store'] = store!.toJson();
    }
    return map;
  }
}

