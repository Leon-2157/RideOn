import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/crop_frame_painter.dart';
import '../widgets/sub_header_widget.dart';

class AturPosisiFotoScreen extends StatefulWidget {
  final File imageFile;

  const AturPosisiFotoScreen({super.key, required this.imageFile});

  @override
  State<AturPosisiFotoScreen> createState() => _AturPosisiFotoScreenState();
}

class _AturPosisiFotoScreenState extends State<AturPosisiFotoScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  bool _isProcessing = false;
  static const double _framePadding = 24.0;

  double? _aspectRatio;
  bool _hasInitializedTransform = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      if (mounted && w > 0 && h > 0) {
        setState(() {
          _aspectRatio = w / h;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aspectRatio = 1.0;
        });
      }
    }
  }

  void _initTransformIfNeeded(double childWidth, double childHeight, double boxSize) {
    if (_hasInitializedTransform) return;
    _hasInitializedTransform = true;
    final dx = (childWidth > boxSize) ? -(childWidth - boxSize) / 2 : 0.0;
    final dy = (childHeight > boxSize) ? -(childHeight - boxSize) / 2 : 0.0;
    _transformController.value = Matrix4.translationValues(dx, dy, 0.0);
  }

  Future<void> _handleFinishCrop(double boxSize) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(widget.imageFile);
        return;
      }

      // 1. Tangkap seluruh viewport gambar yang terlihat
      final ui.Image fullImage = await boundary.toImage(pixelRatio: 2.5);
      final double pixelRatio = fullImage.width / boxSize;

      final double frameSize = boxSize - (2 * _framePadding);

      // 2. Potong area di dalam batas siku-siku & lingkaran
      // Batasi target resolusi maksimal 512x512 agar tajam dan hemat penyimpanan
      final double targetSize = (frameSize * pixelRatio).clamp(256.0, 512.0);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final srcRect = Rect.fromLTWH(
        _framePadding * pixelRatio,
        _framePadding * pixelRatio,
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

      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        Navigator.of(context).pop(widget.imageFile);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
        '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(pngBytes);

      if (!mounted) return;
      Navigator.of(context).pop(croppedFile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      Navigator.of(context).pop(widget.imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildSubHeader(context, 'Atur Posisi Foto'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tentukan ukuran kotak crop agar proporsional di semua layar
                final double boxSize = (constraints.maxWidth - 40).clamp(280.0, 350.0);

                double childWidth = boxSize;
                double childHeight = boxSize;
                if (_aspectRatio != null) {
                  if (_aspectRatio! >= 1.0) {
                    // Landscape
                    childHeight = boxSize;
                    childWidth = boxSize * _aspectRatio!;
                  } else {
                    // Portrait (standar kamera HP)
                    childWidth = boxSize;
                    childHeight = boxSize / _aspectRatio!;
                  }
                  _initTransformIfNeeded(childWidth, childHeight, boxSize);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Square Crop Container with Framing Overlay
                      Center(
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
                                key: _cropKey,
                                child: ClipRect(
                                  child: Container(
                                    width: boxSize,
                                    height: boxSize,
                                    color: Colors.black,
                                    child: InteractiveViewer(
                                      transformationController: _transformController,
                                      minScale: 1.0,
                                      maxScale: 4.0,
                                      boundaryMargin: const EdgeInsets.all(_framePadding),
                                      child: SizedBox(
                                        width: childWidth,
                                        height: childHeight,
                                        child: Image.file(
                                          widget.imageFile,
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
                                      padding: _framePadding,
                                      bracketLength: 28.0,
                                      strokeWidth: 3.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hint microcopy
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pinch_outlined,
                            size: 16,
                            color: const Color(0xFF17152B).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Geser & cubit untuk menyesuaikan foto dalam lingkaran',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF17152B).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Action Buttons: BATAL & SELESAI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tombol BATAL
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              height: 44,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E0EE),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'BATAL',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1832),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Tombol SELESAI
                          GestureDetector(
                            onTap: _isProcessing ? null : () => _handleFinishCrop(boxSize),
                            child: Container(
                              height: 44,
                              width: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1832),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'SELESAI',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
