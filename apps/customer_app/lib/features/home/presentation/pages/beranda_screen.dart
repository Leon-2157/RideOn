import 'package:flutter/material.dart';
import 'package:rideon/core/constants/app_colors.dart';
import '../modules/header_banner/header_banner_view.dart';
import '../modules/services_header/services_header_section.dart';
import '../modules/pilihan_terlaris/food_section_view.dart';
import '../modules/cek_promo/promo_section_view.dart';
import '../modules/rekomendasi_wisata/wisata_section_view.dart';

export '../modules/header_banner/header_banner_view.dart';
export '../modules/header_banner/search_bar_widget.dart';
export '../modules/header_banner/header_banner_logic.dart';
export '../modules/services_header/services_header_section.dart';
export '../modules/pilihan_terlaris/food_section_view.dart';
export '../modules/cek_promo/promo_section_view.dart';
export '../modules/rekomendasi_wisata/wisata_section_view.dart';

/// Entry point koordinator halaman Beranda.
///
/// File ini hanya bertindak sebagai orchestrator modular:
///   1. [HeaderBannerView]        — Banner atas, search bar, login / user avatar
///   2. [ServicesHeaderSection]    — Baris layanan FlexRide / FlexFood / FlexSend
///   3. [PilihanTerlarisSection]   — Kartu makanan horizontal ungu
///   4. [CekPromoSection]          — Carousel promo diskon horizontal
///   5. [RekomendasiWisataSection] — Kartu wisata vertikal dengan badge Bestseller
///
/// Logika, data layer, dan widget tampilan detail masing-masing terisolasi rapi
/// dalam folder `presentation/modules/` masing-masing fitur.
class BerandaScreen extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onProfileTap;
  final Function(int)? onServiceTap;
  final VoidCallback? onSearchTap;
  final bool isLoggedIn;
  final String? userName;
  final String? photoUrl;
  final int? activeServiceIndex;

  const BerandaScreen({
    super.key,
    this.onLoginTap,
    this.onProfileTap,
    this.onServiceTap,
    this.onSearchTap,
    this.isLoggedIn = true,
    this.userName,
    this.photoUrl,
    this.activeServiceIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeaderBannerView(
              isLoggedIn: isLoggedIn,
              userName: userName,
              photoUrl: photoUrl,
              onLoginTap: onLoginTap,
              onProfileTap: onProfileTap,
              onSearchTap: onSearchTap,
              activeServiceIndex: activeServiceIndex,
              onServiceTap: onServiceTap,
            ),
          ),
          const SliverToBoxAdapter(child: PilihanTerlarisSection()),
          const SliverToBoxAdapter(child: CekPromoSection()),
          const SliverToBoxAdapter(child: RekomendasiWisataSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
