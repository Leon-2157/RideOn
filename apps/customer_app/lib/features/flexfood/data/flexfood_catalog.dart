import 'package:flutter/material.dart';
import 'package:rideon/core/constants/app_assets.dart';

/// Katalog bersama FlexFood (Menu & Restoran) agar dipakai seragam oleh
/// [FoodGridView] dan [GlobalSearchScreen].
class FlexFoodCatalog {
  FlexFoodCatalog._();

  static List<Map<String, dynamic>> createAllFoodItems() => [
        {
          'title': 'Bakso Urat',
          'desc': 'Bakso unta bakso dino',
          'price': 'Rp 25.000',
          'priceInt': 25000,
          'rating': '4.9',
          'image': AppAssets.foodBaksoUrat,
          'resto': 'Bakso Urat Pak De',
          'distance': '0.8 km',
          'fav': false,
          'category': 'Bakso & Mie',
          'isTrending': true,
          'isPromo': true,
        },
        {
          'title': 'Kebab Turki',
          'desc': 'Menggunakan daging unta turki',
          'price': 'Rp 37.000',
          'priceInt': 37000,
          'rating': '4.8',
          'image': AppAssets.foodKebabTurki,
          'resto': 'Kebab Turki Istanbul',
          'distance': '1.9 km',
          'fav': true,
          'category': 'Cepat Saji',
          'isTrending': true,
          'isPromo': true,
        },
        {
          'title': 'Nasi Ayam Bakar',
          'desc': 'Nasi ayam bakar ayam madu',
          'price': 'Rp 19.000',
          'priceInt': 19000,
          'rating': '4.9',
          'image': AppAssets.foodNasiAyam,
          'resto': 'Ayam Madu Solo Juara',
          'distance': '2.5 km',
          'fav': true,
          'category': 'Ayam & Nasi',
          'isTrending': true,
          'isPromo': false,
        },
        {
          'title': 'Nasi Goreng',
          'desc': 'Nasi goreng telur mata sapi',
          'price': 'Rp 10.000',
          'priceInt': 10000,
          'rating': '4.8',
          'image': AppAssets.foodNasiGoreng,
          'resto': 'Banku City Resto & Cafe',
          'distance': '1.2 km',
          'fav': false,
          'category': 'Ayam & Nasi',
          'isTrending': false,
          'isPromo': true,
        },
        {
          'title': 'Rendang Si Ujang',
          'desc': 'Rendang khas padang buatan ujang',
          'price': 'Rp 48.000',
          'priceInt': 48000,
          'rating': '4.9',
          'image': AppAssets.foodRendang,
          'resto': 'Warung Padang Si Ujang',
          'distance': '2.1 km',
          'fav': true,
          'category': 'Ayam & Nasi',
          'isTrending': true,
          'isPromo': false,
        },
        {
          'title': 'Bakso Bakar',
          'desc': 'Bakso bakar bukan bakso goreng',
          'price': 'Rp 13.000',
          'priceInt': 13000,
          'rating': '4.7',
          'image': AppAssets.foodBaksoBakar,
          'resto': 'Bakso Urat Pak De',
          'distance': '0.8 km',
          'fav': false,
          'category': 'Bakso & Mie',
          'isTrending': false,
          'isPromo': true,
        },
        {
          'title': 'Burger Daging',
          'desc': 'Burger daging rasa daging',
          'price': 'Rp 19.000',
          'priceInt': 19000,
          'rating': '4.8',
          'image': AppAssets.foodKebabTurki,
          'resto': 'Banku City Resto & Cafe',
          'distance': '1.2 km',
          'fav': true,
          'category': 'Cepat Saji',
          'isTrending': false,
          'isPromo': false,
        },
        {
          'title': 'Pempek Palembang',
          'desc': 'Pempek asli khas Palembang',
          'price': 'Rp 60.000',
          'priceInt': 60000,
          'rating': '4.9',
          'image': AppAssets.foodRendang,
          'resto': 'Pempek Cek Molek',
          'distance': '1.5 km',
          'fav': true,
          'category': 'Cepat Saji',
          'isTrending': false,
          'isPromo': false,
        },
        {
          'title': 'Mie Ayam Mang Joni',
          'desc': 'Mie ayam jantan lezat',
          'price': 'Rp 14.000',
          'priceInt': 14000,
          'rating': '4.7',
          'image': AppAssets.foodBaksoUrat,
          'resto': 'Bakso & Mie Mang Joni',
          'distance': '1.0 km',
          'fav': false,
          'category': 'Bakso & Mie',
          'isTrending': false,
          'isPromo': true,
        },
      ];

  static List<Map<String, dynamic>> createTrendingFoods() => [
        {
          'title': 'Bakso Urat',
          'desc': 'Bakso unta bakso dino',
          'price': 'Rp 25.000',
          'priceInt': 25000,
          'rating': '4.9',
          'image': AppAssets.foodBaksoUrat,
          'resto': 'Bakso Urat Pak De',
          'distance': '0.8 km',
          'fav': false,
        },
        {
          'title': 'Kebab Turki',
          'desc': 'Daging kebab rempah gurih',
          'price': 'Rp 37.000',
          'priceInt': 37000,
          'rating': '4.8',
          'image': AppAssets.foodKebabTurki,
          'resto': 'Kebab Turki Istanbul',
          'distance': '1.9 km',
          'fav': true,
        },
        {
          'title': 'Nasi Ayam Bakar',
          'desc': 'Ayam bakar madu kecap manis',
          'price': 'Rp 19.000',
          'priceInt': 19000,
          'rating': '4.9',
          'image': AppAssets.foodNasiAyam,
          'resto': 'Ayam Madu Solo Juara',
          'distance': '2.5 km',
          'fav': true,
        },
        {
          'title': 'Rendang Si Ujang',
          'desc': 'Daging sapi rempah otentik',
          'price': 'Rp 48.000',
          'priceInt': 48000,
          'rating': '4.9',
          'image': AppAssets.foodRendang,
          'resto': 'Warung Padang Si Ujang',
          'distance': '2.1 km',
          'fav': true,
        },
      ];

  static const List<Map<String, dynamic>> menuCategories = [
    {'name': 'Semua', 'icon': Icons.lunch_dining_rounded},
    {'name': 'Terlaris', 'icon': Icons.local_fire_department_rounded},
    {'name': 'Promo', 'icon': Icons.discount_rounded},
    {'name': 'Ayam & Nasi', 'icon': Icons.rice_bowl_rounded},
    {'name': 'Bakso & Mie', 'icon': Icons.ramen_dining_rounded},
    {'name': 'Cepat Saji', 'icon': Icons.fastfood_rounded},
  ];

  static const List<Map<String, dynamic>> restoCategories = [
    {'name': 'Semua Resto', 'icon': Icons.storefront_rounded},
    {'name': 'Terdekat', 'icon': Icons.near_me_rounded},
    {'name': 'Super Partner', 'icon': Icons.verified_rounded},
    {'name': 'Bintang 4.8+', 'icon': Icons.star_rounded},
    {'name': 'Gratis Ongkir', 'icon': Icons.local_shipping_rounded},
    {'name': 'Promo Diskon', 'icon': Icons.percent_rounded},
  ];

  static const List<Map<String, dynamic>> promoBanners = [
    {
      'image': AppAssets.promo1,
      'title': 'Diskon s/d 60% Setiap Hari',
      'tag': 'Spesial Pengguna Baru',
    },
    {
      'image': AppAssets.promo2,
      'title': 'Gratis Ongkir Sepuasnya',
      'tag': 'Min. Belanja 30rb',
    },
    {
      'image': AppAssets.promo3,
      'title': 'Cashback 50% FlexPay',
      'tag': 'Berlaku Semua Resto',
    },
  ];

  static const List<Map<String, dynamic>> popularRestaurants = [
    {
      'name': 'Banku City Resto & Cafe',
      'category': 'Aneka Nasi, Bakso, Kebab',
      'rating': '4.9',
      'reviews': '1.2k+ rating',
      'distance': '1.2 km',
      'duration': '15-20 mnt',
      'priceRange': 'Rp 10.000 - Rp 48.000',
      'image': AppAssets.foodNasiGoreng,
      'tag': 'Paling Diminati',
      'badge': 'Super Partner',
    },
    {
      'name': 'Warung Padang Si Ujang',
      'category': 'Rendang Khas Padang, Gulai',
      'rating': '4.8',
      'reviews': '850+ rating',
      'distance': '2.1 km',
      'duration': '20-25 mnt',
      'priceRange': 'Rp 15.000 - Rp 60.000',
      'image': AppAssets.foodRendang,
      'tag': 'Rasa Otentik',
      'badge': 'Super Partner',
    },
    {
      'name': 'Bakso Urat & Bakso Bakar Pak De',
      'category': 'Bakso Urat, Bakso Bakar, Mie',
      'rating': '4.9',
      'reviews': '2.5k+ rating',
      'distance': '0.8 km',
      'duration': '10-15 mnt',
      'priceRange': 'Rp 13.000 - Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'tag': 'Promo Spesial',
      'badge': 'Terlaris',
    },
    {
      'name': 'Kebab Turki Istanbul Express',
      'category': 'Kebab Daging, Burger, Roti Cane',
      'rating': '4.7',
      'reviews': '640+ rating',
      'distance': '1.9 km',
      'duration': '15-25 mnt',
      'priceRange': 'Rp 19.000 - Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'tag': 'Diskon 20%',
      'badge': 'Super Partner',
    },
    {
      'name': 'Ayam Bakar Madu Solo Juara',
      'category': 'Nasi Ayam Bakar, Lalapan, Sambal',
      'rating': '4.8',
      'reviews': '1.8k+ rating',
      'distance': '2.5 km',
      'duration': '20-30 mnt',
      'priceRange': 'Rp 19.000 - Rp 35.000',
      'image': AppAssets.foodNasiAyam,
      'tag': 'Gratis Ongkir',
      'badge': 'Super Partner',
    },
  ];

  /// Menyaring daftar menu makanan berdasarkan query dan nama kategori.
  static List<Map<String, dynamic>> filterFoods(
    List<Map<String, dynamic>> items, {
    String query = '',
    String category = 'Semua',
  }) {
    final q = query.trim().toLowerCase();
    return items.where((food) {
      if (category != 'Semua') {
        if (category == 'Terlaris') {
          final rating = double.tryParse('${food['rating']}') ?? 0.0;
          if (food['isTrending'] != true && rating < 4.9) return false;
        } else if (category == 'Promo') {
          if (food['isPromo'] != true) return false;
        } else if (food['category'] != category) {
          return false;
        }
      }

      if (q.isEmpty) return true;
      final title = (food['title'] as String? ?? '').toLowerCase();
      final desc = (food['desc'] as String? ?? '').toLowerCase();
      final resto = (food['resto'] as String? ?? '').toLowerCase();
      final cat = (food['category'] as String? ?? '').toLowerCase();
      return title.contains(q) ||
          desc.contains(q) ||
          resto.contains(q) ||
          cat.contains(q);
    }).toList();
  }

  /// Menyaring daftar restoran berdasarkan query dan nama kategori.
  static List<Map<String, dynamic>> filterRestaurants(
    List<Map<String, dynamic>> restaurants, {
    String query = '',
    String category = 'Semua Resto',
  }) {
    final q = query.trim().toLowerCase();
    final filtered = restaurants.where((resto) {
      if (category != 'Semua Resto') {
        if (category == 'Terdekat') {
          final dist = _parseKm(resto['distance'] as String? ?? '');
          if (dist > 1.5) return false;
        } else if (category == 'Super Partner') {
          if (resto['badge'] != 'Super Partner') return false;
        } else if (category == 'Bintang 4.8+') {
          final rating = double.tryParse('${resto['rating']}') ?? 0.0;
          if (rating < 4.8) return false;
        } else if (category == 'Gratis Ongkir') {
          final tag = (resto['tag'] as String? ?? '').toLowerCase();
          if (!tag.contains('gratis ongkir')) return false;
        } else if (category == 'Promo Diskon') {
          final tag = (resto['tag'] as String? ?? '').toLowerCase();
          if (!tag.contains('diskon') && !tag.contains('promo')) return false;
        }
      }

      if (q.isEmpty) return true;
      final name = (resto['name'] as String? ?? '').toLowerCase();
      final cat = (resto['category'] as String? ?? '').toLowerCase();
      final tag = (resto['tag'] as String? ?? '').toLowerCase();
      return name.contains(q) || cat.contains(q) || tag.contains(q);
    }).toList();

    if (category == 'Terdekat') {
      filtered.sort(
        (a, b) => _parseKm(a['distance'] as String? ?? '')
            .compareTo(_parseKm(b['distance'] as String? ?? '')),
      );
    }
    return filtered;
  }

  static double _parseKm(String text) {
    final numMatch = RegExp(r'[\d.]+').firstMatch(text);
    return double.tryParse(numMatch?.group(0) ?? '') ?? 99.0;
  }
}

