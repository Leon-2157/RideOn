import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Processor helper for cropping and image aspect ratio calculations
class CropImageProcessor {
  static Future<double> loadImageAspectRatio(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      if (w > 0 && h > 0) {
        return w / h;
      }
    } catch (_) {}
    return 1.0;
  }

  static Future<File> cropVisibleArea({
    required GlobalKey cropKey,
    required double boxSize,
    required double framePadding,
    required File originalFile,
  }) async {
    final boundary =
        cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return originalFile;
    }

    final ui.Image fullImage = await boundary.toImage(pixelRatio: 2.5);
    final double pixelRatio = fullImage.width / boxSize;
    final double frameSize = boxSize - (2 * framePadding);
    final double targetSize = (frameSize * pixelRatio).clamp(256.0, 512.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcRect = Rect.fromLTWH(
      framePadding * pixelRatio,
      framePadding * pixelRatio,
      frameSize * pixelRatio,
      frameSize * pixelRatio,
    );
    final dstRect = Rect.fromLTWH(0, 0, targetSize, targetSize);

    canvas.drawImageRect(
      fullImage,
      srcRect,
      dstRect,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high,
    );

    final croppedImage = await recorder.endRecording().toImage(
          targetSize.round(),
          targetSize.round(),
        );

    final byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return originalFile;
    }

    final pngBytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final croppedFile = File(
      '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await croppedFile.writeAsBytes(pngBytes);
    return croppedFile;
  }
}
