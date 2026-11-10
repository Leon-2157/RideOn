import 'dart:io';
import 'package:flutter/foundation.dart';
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
    // ponytail: AppImage standardizes asset, network, and local file rendering across all screens with high quality filtering
    final isNetwork = assetPath.startsWith('http://') ||
        assetPath.startsWith('https://') ||
        assetPath.startsWith('blob:');
    final isAsset = assetPath.startsWith('assets/');

    Widget imageWidget;
    if (isNetwork || (kIsWeb && !isAsset)) {
      imageWidget = Image.network(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (isAsset) {
      imageWidget = Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      imageWidget = Image.file(
        File(assetPath),
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        clipBehavior: Clip.antiAlias,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
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
  }
}
