import 'package:rideon/core/constants/app_assets.dart';
import 'food_item_model.dart';

/// Logika bisnis & data layer untuk section Pilihan Terlaris.
///
/// Menyediakan mock items default dan method untuk integrasi API / Firestore mendatang.
class FoodSectionLogic {
  static const List<FoodItemModel> defaultItems = [
    FoodItemModel(
      title: 'Bakso Urat',
      description: 'Bakso Urat Pak De',
      price: 'Rp 25.000',
      imageAsset: AppAssets.foodBaksoUrat,
      isFavorite: false,
    ),
    FoodItemModel(
      title: 'Kebab Turki',
      description: 'Kebab Turki Istanbul',
      price: 'Rp 37.000',
      imageAsset: AppAssets.foodKebabTurki,
      isFavorite: true,
    ),
    FoodItemModel(
      title: 'Nasi Ayam Bakar',
      description: 'Ayam Madu Solo Juara',
      price: 'Rp 19.000',
      imageAsset: AppAssets.foodNasiAyam,
      isFavorite: false,
    ),
    FoodItemModel(
      title: 'Nasi Goreng',
      description: 'Banku City Resto',
      price: 'Rp 10.000',
      imageAsset: AppAssets.foodNasiGoreng,
      isFavorite: false,
    ),
    FoodItemModel(
      title: 'Rendang Si Ujang',
      description: 'Warung Padang Si Ujang',
      price: 'Rp 48.000',
      imageAsset: AppAssets.foodRendang,
      isFavorite: false,
    ),
    FoodItemModel(
      title: 'Bakso Bakar',
      description: 'Bakso Urat Pak De',
      price: 'Rp 13.000',
      imageAsset: AppAssets.foodBaksoBakar,
      isFavorite: false,
    ),
  ];

  /// Hook untuk fetch data dinamis dari backend ketika siap.
  static Future<List<FoodItemModel>> fetchBestSellers() async {
    // Simulasi network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return defaultItems;
  }
}

