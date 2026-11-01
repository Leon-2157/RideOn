import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modal Bottom Sheet untuk Pemilihan Tema (Mode Terang, Mode Gelap, Ikuti Sistem)
class ThemeBottomSheet extends StatefulWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeSelected;

  const ThemeBottomSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  static void show(
    BuildContext context, {
    required String currentTheme,
    required ValueChanged<String> onThemeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeBottomSheet(
        currentTheme: currentTheme,
        onThemeSelected: onThemeSelected,
      ),
    );
  }

  @override
  State<ThemeBottomSheet> createState() => _ThemeBottomSheetState();
}

class _ThemeBottomSheetState extends State<ThemeBottomSheet> {
  late String _tempTheme;

  @override
  void initState() {
    super.initState();
    _tempTheme = widget.currentTheme;
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1B1832)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1B1832),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B1832),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + Title + Close Button
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1832),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pilih Tema',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1832),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1B1832),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF1B1832),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2DCFE)),
          const SizedBox(height: 18),

          // Option 1: Mode Terang
          _buildThemeOptionCard(
            title: 'Mode Terang',
            subtitle: 'Tampilan cerah',
            icon: Icons.wb_sunny_outlined,
            isSelected: _tempTheme == 'Mode Terang',
            onTap: () => setState(() => _tempTheme = 'Mode Terang'),
          ),
          const SizedBox(height: 12),

          // Option 2: Mode Gelap
          _buildThemeOptionCard(
            title: 'Mode Gelap',
            subtitle: 'Tampilan Gelap',
            icon: Icons.nightlight_round,
            isSelected: _tempTheme == 'Mode Gelap',
            onTap: () => setState(() => _tempTheme = 'Mode Gelap'),
          ),
          const SizedBox(height: 12),

          // Option 3: Ikuti Sistem
          _buildThemeOptionCard(
            title: 'Ikuti Sistem',
            subtitle: 'Sesuai Perangkat Anda',
            icon: Icons.sync_rounded,
            isSelected: _tempTheme == 'Ikuti Sistem',
            onTap: () => setState(() => _tempTheme = 'Ikuti Sistem'),
          ),
          const SizedBox(height: 22),

          // Bottom Selesai Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                widget.onThemeSelected(_tempTheme);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1832),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'SELESAI',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
