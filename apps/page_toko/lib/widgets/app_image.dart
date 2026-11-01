import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable HD Image Loader with automatic error handling,
/// anti-aliased border radius, and high-quality filtering.
class AppImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const AppImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    // ponytail: AppImage standardizes asset rendering across all screens with high quality filtering
    Widget imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: AppColors.primarySoft,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        clipBehavior: Clip.antiAlias,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
