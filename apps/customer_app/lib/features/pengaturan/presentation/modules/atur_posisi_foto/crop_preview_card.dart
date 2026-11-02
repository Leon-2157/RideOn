import 'dart:io';
import 'package:flutter/material.dart';
import 'crop_frame_painter.dart';

/// Preview card interactive viewport for cropping
class CropPreviewCard extends StatelessWidget {
  final GlobalKey cropKey;
  final TransformationController transformController;
  final File imageFile;
  final double boxSize;
  final double childWidth;
  final double childHeight;
  final double framePadding;

  const CropPreviewCard({
    super.key,
    required this.cropKey,
    required this.transformController,
    required this.imageFile,
    required this.boxSize,
    required this.childWidth,
    required this.childHeight,
    required this.framePadding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Gambar interaktif yang mengisi penuh (Cover) tanpa bar hitam
            RepaintBoundary(
              key: cropKey,
              child: ClipRect(
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  color: Colors.black,
                  child: InteractiveViewer(
                    transformationController: transformController,
                    minScale: 1.0,
                    maxScale: 4.0,
                    boundaryMargin: EdgeInsets.all(framePadding),
                    child: SizedBox(
                      width: childWidth,
                      height: childHeight,
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Overlay Bingkai Crop (Siku-siku Figma + Panduan Lingkaran Avatar)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CropFramePainter(
                    padding: framePadding,
                    bracketLength: 28.0,
                    strokeWidth: 3.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
