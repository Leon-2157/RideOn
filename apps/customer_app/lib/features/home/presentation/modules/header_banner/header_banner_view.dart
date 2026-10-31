import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/features/home/presentation/modules/services_header/services_header_section.dart';
import 'header_banner_logic.dart';
import 'search_bar_widget.dart';

export 'header_banner_logic.dart';
export 'search_bar_widget.dart';

/// Komponen visual header beranda.
///
/// Tanggung jawab murni UI:
/// - Banner iklan promo atas (Figma node [1:7956] Rectangle 40, height 259px)
/// - Gradasi transisi lembut di ujung bawah banner (y=235..259) menyatu ke latar putih
/// - Floating service buttons (FlexRide, FlexFood, FlexSend pada y=219px)
/// - Top bar (Search bar + Avatar profil / Tombol Login)
class HeaderBannerView extends StatelessWidget {
  final bool isLoggedIn;
  final String? userName;
  final String? photoUrl;
  final VoidCallback? onLoginTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;
  final int? activeServiceIndex;
  final Function(int index)? onServiceTap;

  const HeaderBannerView({
    super.key,
    this.isLoggedIn = true,
    this.userName,
    this.photoUrl,
    this.onLoginTap,
    this.onProfileTap,
    this.onSearchTap,
    this.activeServiceIndex,
    this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePhotoUrl =
        HeaderBannerLogic.resolvePhotoUrl(explicitUrl: photoUrl) ??
            AppAssets.userAvatar;
    final effectiveUserName =
        HeaderBannerLogic.resolveUserName(explicitName: userName) ?? 'User';

    return SizedBox(
      height: 304,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Background Banner Image (Height 259 matching Figma Rectangle 40)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 259,
            child: Image.asset(
              AppAssets.bannerHeader,
              width: double.infinity,
              height: 259,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Top Dark Gradient (Membuat Search Bar & Status Bar kontras tajam)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 85,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Soft Fade Transition (Hanya di ujung bawah banner y=235..259 agar es & kaleng tetap bening)
          Positioned(
            left: 0,
            right: 0,
            top: 235,
            height: 25,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.70),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.60, 1.0],
                ),
              ),
            ),
          ),

          // 4. Floating Service Buttons (FlexRide, FlexFood, FlexSend mengambang presisi y=219 Figma node [1:7957])
          Positioned(
            left: 0,
            right: 0,
            top: 219,
            child: ServicesHeaderSection(
              initialSelectedIndex: activeServiceIndex,
              onServiceTap: onServiceTap,
            ),
          ),

          // 5. Top Bar: Search Bar + Avatar / Tombol Login
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: HomeSearchBar(onTap: onSearchTap),
                    ),
                    const SizedBox(width: 12),
                    if (isLoggedIn)
                      GestureDetector(
                        key: const Key('home_avatar_btn'),
                        onTap: onProfileTap,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              effectivePhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF6B48FC),
                                alignment: Alignment.center,
                                child: Text(
                                  effectiveUserName.isNotEmpty
                                      ? effectiveUserName[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        key: const Key('home_login_btn'),
                        onTap: onLoginTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Login',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
