import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sub_header_widget.dart';
import '../modules/atur_posisi_foto/crop_action_buttons.dart';
import '../modules/atur_posisi_foto/crop_image_processor.dart';
import '../modules/atur_posisi_foto/crop_preview_card.dart';

export '../modules/atur_posisi_foto/crop_action_buttons.dart';
export '../modules/atur_posisi_foto/crop_frame_painter.dart';
export '../modules/atur_posisi_foto/crop_image_processor.dart';
export '../modules/atur_posisi_foto/crop_preview_card.dart';

/// Screen Atur Posisi Foto Profil (Slim Coordinator)
class AturPosisiFotoScreen extends StatefulWidget {
  final File imageFile;

  const AturPosisiFotoScreen({super.key, required this.imageFile});

  @override
  State<AturPosisiFotoScreen> createState() => _AturPosisiFotoScreenState();
}

class _AturPosisiFotoScreenState extends State<AturPosisiFotoScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
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
    final ratio =
        await CropImageProcessor.loadImageAspectRatio(widget.imageFile);
    if (mounted) {
      setState(() => _aspectRatio = ratio);
    }
  }

  void _initTransformIfNeeded(
      double childWidth, double childHeight, double boxSize) {
    if (_hasInitializedTransform) return;
    _hasInitializedTransform = true;
    final dx = (childWidth > boxSize) ? -(childWidth - boxSize) / 2 : 0.0;
    final dy = (childHeight > boxSize) ? -(childHeight - boxSize) / 2 : 0.0;
    _transformController.value = Matrix4.translationValues(dx, dy, 0.0);
  }

  Future<void> _handleFinishCrop(double boxSize) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final croppedFile = await CropImageProcessor.cropVisibleArea(
        cropKey: _cropKey,
        boxSize: boxSize,
        framePadding: _framePadding,
        originalFile: widget.imageFile,
      );

      if (!mounted) return;
      Navigator.of(context).pop(croppedFile);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
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
                final double boxSize =
                    (constraints.maxWidth - 40).clamp(280.0, 350.0);

                double childWidth = boxSize;
                double childHeight = boxSize;
                if (_aspectRatio != null) {
                  if (_aspectRatio! >= 1.0) {
                    childHeight = boxSize;
                    childWidth = boxSize * _aspectRatio!;
                  } else {
                    childWidth = boxSize;
                    childHeight = boxSize / _aspectRatio!;
                  }
                  _initTransformIfNeeded(childWidth, childHeight, boxSize);
                }

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      CropPreviewCard(
                        cropKey: _cropKey,
                        transformController: _transformController,
                        imageFile: widget.imageFile,
                        boxSize: boxSize,
                        childWidth: childWidth,
                        childHeight: childHeight,
                        framePadding: _framePadding,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pinch_outlined,
                            size: 16,
                            color:
                                const Color(0xFF17152B).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Geser & cubit untuk menyesuaikan foto dalam lingkaran',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF17152B)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      CropActionButtons(
                        isProcessing: _isProcessing,
                        onCancel: () => Navigator.of(context).pop(),
                        onFinish: () => _handleFinishCrop(boxSize),
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
