import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_item_model.dart';
import 'services_header_logic.dart';

export 'service_item_model.dart';
export 'services_header_logic.dart';

/// Section baris 3 layanan utama (FlexRide, FlexFood, FlexSend).
/// Presisi 100% Figma node [1:7955] (page utama), [1:7957], [1:7958], [1:7959]:
/// - Default (page utama): Tiga tombol putih 64x64, border gradasi lavender-ungu (#C6BCFF ke #6B48FC 65%),
///   bayangan ungu halus (#6B48FC 18%, offset 0,2, blur 6), ikon hitam proporsional HD 36x36 px.
/// - Selected (saat aktif): Latar ungu muda #BCB3FC, ikon putih, label warna #6B48FC.
/// - Label: Roboto Medium (weight 500), fontSize 9px, warna #17152B, jarak 2px dari kotak tombol.
class ServicesHeaderSection extends StatefulWidget {
  final int? initialSelectedIndex;
  final Function(int index)? onServiceTap;
  final List<ServiceItemModel>? services;

  const ServicesHeaderSection({
    super.key,
    this.initialSelectedIndex,
    this.onServiceTap,
    this.services,
  });

  @override
  State<ServicesHeaderSection> createState() => _ServicesHeaderSectionState();
}

class _ServicesHeaderSectionState extends State<ServicesHeaderSection> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  void didUpdateWidget(covariant ServicesHeaderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedIndex != oldWidget.initialSelectedIndex) {
      _selectedIndex = widget.initialSelectedIndex;
    }
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    widget.onServiceTap?.call(index);
    // Kembalikan ke warna default setelah animasi tap selesai (tidak menetap ungu)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _selectedIndex = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services ?? ServicesHeaderLogic.defaultServices;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(services.length, (index) {
        final s = services[index];
        final bool isSelected = _selectedIndex == index;

        return GestureDetector(
          key: Key('btn_service_${s.title.toLowerCase()}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTap(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kotak Tombol Layanan presisi Figma Rectangle 4 / 23 / Group 9
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  // Border gradasi presisi Figma node [1:7957] strokes: #C6BCFF ke #6B48FC (65% alpha)
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFC6BCFF),
                      Color(0xA66B48FC),
                    ],
                    stops: [0.18, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF6B48FC).withValues(alpha: 0.32)
                          : const Color(0xFF6B48FC).withValues(alpha: 0.18),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(0.6), // Ketebalan border 0.6px
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFBCB3FC) : Colors.white,
                    borderRadius: BorderRadius.circular(9.4),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Image.asset(
                      isSelected ? s.iconWhiteAsset : s.iconAsset,
                      fit: BoxFit.contain,
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
              ),

              // Jarak vertikal tombol ke teks label (Figma: 2px)
              const SizedBox(height: 2),

              // Label tombol layanan: Roboto Bold 9.5px (Figma node [1:7964])
              Text(
                s.title,
                style: GoogleFonts.roboto(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF6B48FC)
                      : const Color(0xFF17152B),
                  height: 1.17,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
