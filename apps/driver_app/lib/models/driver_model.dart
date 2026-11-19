class DriverInfo {
  final String id;
  final String vehicleType;
  final String vehicleBrand;
  final String vehiclePlate;
  final double ratingAvg;
  final int totalTrips;
  final bool isOnline;
  final int walletBalance;
  final int cashFloatAmount;

  const DriverInfo({
    required this.id,
    required this.vehicleType,
    required this.vehicleBrand,
    required this.vehiclePlate,
    required this.ratingAvg,
    required this.totalTrips,
    required this.isOnline,
    required this.walletBalance,
    required this.cashFloatAmount,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> j) => DriverInfo(
        id: j['id'] as String? ?? '',
        vehicleType: j['vehicle_type'] as String? ?? '',
        vehicleBrand: j['vehicle_brand'] as String? ?? '',
        vehiclePlate: j['vehicle_plate'] as String? ?? '',
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
        totalTrips: j['total_trips'] as int? ?? 0,
        isOnline: j['is_online'] as bool? ?? false,
        walletBalance: j['wallet_balance'] as int? ?? 0,
        cashFloatAmount: j['cash_float_amount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_type': vehicleType,
        'vehicle_brand': vehicleBrand,
        'vehicle_plate': vehiclePlate,
        'rating_avg': ratingAvg,
        'total_trips': totalTrips,
        'is_online': isOnline,
        'wallet_balance': walletBalance,
        'cash_float_amount': cashFloatAmount,
      };
}

class DriverModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String avatarUrl;
  final DriverInfo? driver;

  const DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl = '',
    this.driver,
  });

  factory DriverModel.fromJson(Map<String, dynamic> j) => DriverModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        role: j['role'] as String? ?? '',
        status: j['status'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String? ?? '',
        driver: j['driver'] != null
            ? DriverInfo.fromJson(j['driver'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'avatar_url': avatarUrl,
        if (driver != null) 'driver': driver!.toJson(),
      };

  bool get isPendingApproval => status == 'PENDING_APPROVAL';
  bool get isActive => status == 'ACTIVE';
}

