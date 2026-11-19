class StoreMenuModel {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final String category;
  final int price;
  final String photoUrl;
  final bool isAvailable;
  final int stock;

  const StoreMenuModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.photoUrl,
    required this.isAvailable,
    this.stock = 100,
  });

  factory StoreMenuModel.fromJson(Map<String, dynamic> json) {
    return StoreMenuModel(
      id: (json['id'] ?? '').toString(),
      storeId: (json['store_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      category: (json['category'] ?? 'Makanan Utama').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      photoUrl: (json['photo_url'] ?? json['image'] ?? '').toString(),
      isAvailable: json['is_available'] == null
          ? (json['isAvailable'] != false)
          : (json['is_available'] == true || json['is_available'] == 1),
      stock: (json['stock'] as num?)?.toInt() ?? 100,
    );
  }

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
      };

  Map<String, dynamic> toScreenMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'desc': description,
      'price': price,
      'isAvailable': isAvailable,
    };
    if (photoUrl.isNotEmpty) {
      map['image'] = photoUrl;
    }
    return map;
  }
}

