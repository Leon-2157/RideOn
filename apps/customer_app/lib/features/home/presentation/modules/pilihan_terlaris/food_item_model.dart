/// Model data satu item makanan di section Pilihan Terlaris.
///
/// Widget kartu [FoodCardItem] hanya menerima model ini, sehingga
/// saat backend / database siap, cukup memetakan respons JSON ke model ini.
class FoodItemModel {
  final String title;
  final String description;
  final String price;
  final String imageAsset;
  final String rating;
  final bool isFavorite;

  const FoodItemModel({
    required this.title,
    required this.description,
    required this.price,
    required this.imageAsset,
    this.rating = '4.9',
    this.isFavorite = false,
  });

  FoodItemModel copyWith({
    String? title,
    String? description,
    String? price,
    String? imageAsset,
    String? rating,
    bool? isFavorite,
  }) {
    return FoodItemModel(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageAsset: imageAsset ?? this.imageAsset,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Factory untuk integrasi REST API / Firestore mendatang:
  factory FoodItemModel.fromJson(Map<String, dynamic> json) => FoodItemModel(
        title: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: json['formatted_price'] as String? ?? '',
        imageAsset: json['image_url'] as String? ?? '',
        rating: json['rating'] as String? ?? '4.9',
        isFavorite: json['is_favorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': title,
        'description': description,
        'formatted_price': price,
        'image_url': imageAsset,
        'rating': rating,
        'is_favorite': isFavorite,
      };
}
