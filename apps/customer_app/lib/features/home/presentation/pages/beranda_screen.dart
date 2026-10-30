import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Halaman Beranda strictly based on Figma node [44:7923] (page utama):
/// - Header with search bar and login button
/// - 3 Core Services: FlexRide, FlexFood, FlexSend
/// - Promo Banner Carousel "Cek promo sekarang"
/// - "FlexFood - Pilihan Terlaris" horizontal food cards
/// - "Rekomendasi wisata" (Gunung Rinjani, Ranu Kumbolo, Banda Neira)
class BerandaScreen extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onProfileTap;
  final Function(int)? onServiceTap;
  final bool isLoggedIn;
  final String? userName;
  final String? photoUrl;

  const BerandaScreen({
    super.key,
    this.onLoginTap,
    this.onProfileTap,
    this.onServiceTap,
    this.isLoggedIn = true,
    this.userName,
    this.photoUrl,
  });

  String? get _resolvedPhotoUrl {
    if (photoUrl != null) return photoUrl;
    try {
      return FirebaseAuth.instance.currentUser?.photoURL;
    } catch (_) {
      return null;
    }
  }

  String? get _resolvedUserName {
    if (userName != null) return userName;
    try {
      return FirebaseAuth.instance.currentUser?.displayName;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // Header with Search Bar & Login
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          // 3 Core Services (FlexRide, FlexFood, FlexSend)
          SliverToBoxAdapter(
            child: _buildServicesRow(),
          ),

          // Promo Carousel Section
          SliverToBoxAdapter(
            child: _buildPromoSection(),
          ),

          // FlexFood - Pilihan Terlaris Section
          SliverToBoxAdapter(
            child: _buildPilihanTerlarisSection(),
          ),

          // Rekomendasi Wisata Section
          SliverToBoxAdapter(
            child: _buildWisataSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Background banner image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Image.asset(
            AppAssets.bannerHeader,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay for contrast
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.25),
              ],
            ),
          ),
        ),

        // Search Bar & Login Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Search Input Box
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cari makanan, tujuan, layanan...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Profile Avatar (if logged in) or Login Button
                if (isLoggedIn)
                  GestureDetector(
                    onTap: onProfileTap,
                    child: UserAvatar(
                      photoUrl: _resolvedPhotoUrl,
                      name: _resolvedUserName,
                      size: 38,
                      borderWidth: 2,
                      borderColor: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onLoginTap,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(19.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Login',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesRow() {
    final services = [
      {
        'title': 'FlexRide',
        'icon': AppAssets.icFlexRide,
      },
      {
        'title': 'FlexFood',
        'icon': AppAssets.icFlexFood,
      },
      {
        'title': 'FlexSend',
        'icon': AppAssets.icFlexSend,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(services.length, (index) {
          final s = services[index];
          return GestureDetector(
            onTap: () {
              if (onServiceTap != null) onServiceTap!(index);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    s['icon'] as String,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s['title'] as String,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPromoSection() {
    final promos = [
      AppAssets.promo1,
      AppAssets.promo2,
      AppAssets.promo3,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Cek promo sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: promos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 2.3,
                  child: Image.asset(
                    promos[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPilihanTerlarisSection() {
    final items = [
      {
        'title': 'Bakso Urat',
        'desc': 'Bakso unta bakso dino',
        'price': 'Rp 25.000',
        'image': AppAssets.foodBaksoUrat,
      },
      {
        'title': 'Kebab Turki',
        'desc': 'Menggunakan daging unta turki',
        'price': 'Rp 37.000',
        'image': AppAssets.foodKebabTurki,
      },
      {
        'title': 'Nasi Ayam bakar',
        'desc': 'Nasi ayam bakar ayam',
        'price': 'Rp 19.000',
        'image': AppAssets.foodNasiAyam,
      },
      {
        'title': 'Nasi Goreng',
        'desc': 'Nasi goreng telur mata sapi',
        'price': 'Rp 10.000',
        'image': AppAssets.foodNasiGoreng,
      },
      {
        'title': 'Rendang Siujang',
        'desc': 'Rendang khas padang buatan uajang',
        'price': 'Rp 48.000',
        'image': AppAssets.foodRendang,
      },
      {
        'title': 'Bakso Bakar',
        'desc': 'Bakso bakar bukan bakso goreng',
        'price': 'Rp 13.000',
        'image': AppAssets.foodBaksoBakar,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'FlexFood',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pilihan Terlaris',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final it = items[index];
              return Container(
                width: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.3,
                        child: Image.asset(
                          it['image'] as String,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            it['desc'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 8.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            it['price'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWisataSection() {
    final list = [
      {
        'title': 'Gunung Rinjani',
        'desc':
            'Jangan salah, kami sedia Ojek Gunung! Hemat waktu dan tenaga dari basecamp ke POS 2. Pesan sekarang dan nikmati perjalanan aman bersama driver profesional kami.',
        'image': AppAssets.wisataRinjani,
      },
      {
        'title': 'Ranu Kumbolo',
        'desc':
            'Pesona magis Ranu Kumbolo menantimu! Bebaskan penatmu dan nikmati syahdunya berkemah di surga Semeru. Siapkan ranselmu dan rencanakan pendakianmu sekarang',
        'image': AppAssets.wisataRanuKumbolo,
      },
      {
        'title': 'Banda Neira',
        'desc':
            'Banda Neira, kepingan surga di Maluku! Nikmati pesona bawah laut eksotis dan kekayaan sejarah yang mendunia. Wujudkan liburan impianmu sekarang',
        'image': AppAssets.wisataBandaNeira,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            children: [
              const Icon(
                Icons.place_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Rekomendasi wisata',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final w = list[index];
            return Container(
              height: 133,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image with Bestseller badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                        child: SizedBox(
                          width: 125,
                          height: double.infinity,
                          child: Image.asset(
                            w['image'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bestseller',
                            style: GoogleFonts.roboto(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Text details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              w['desc'] as String,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 9.5,
                                height: 1.35,
                                color: AppColors.dark.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
