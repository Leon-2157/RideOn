import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/theme_service.dart';

export '../../services/theme_service.dart' show AppThemeMode;

/// [ThemeSelectionSheet]
/// Bottom sheet pemilihan tema sesuai spesifikasi Figma:
/// - Figma/PengaturanAkun/mode terang.png
/// - Figma/PengaturanAkun/mode gelap.png
/// - Figma/PengaturanAkun/ikuti sistem.png
class ThemeSelectionSheet extends StatefulWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode>? onThemeSelected;

  const ThemeSelectionSheet({
    super.key,
    this.currentTheme = AppThemeMode.system,
    this.onThemeSelected,
  });

  static Future<AppThemeMode?> show(
    BuildContext context, {
    AppThemeMode? currentTheme,
    ValueChanged<AppThemeMode>? onThemeSelected,
  }) {
    final activeTheme = currentTheme ?? ThemeService().currentTheme;
    return showModalBottomSheet<AppThemeMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSelectionSheet(
        currentTheme: activeTheme,
        onThemeSelected: onThemeSelected,
      ),
    );
  }

  @override
  State<ThemeSelectionSheet> createState() => _ThemeSelectionSheetState();
}

class _ThemeSelectionSheetState extends State<ThemeSelectionSheet> {
  late AppThemeMode _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
  }

  bool _isDarkPreview(BuildContext context) {
    if (_selectedTheme == AppThemeMode.dark) return true;
    if (_selectedTheme == AppThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void _onOptionTapped(AppThemeMode mode) {
    setState(() {
      _selectedTheme = mode;
    });
    // Aktifkan perubahan secara langsung agar tema aplikasi dan layar di belakangnya langsung berubah reaktif
    ThemeService().setTheme(mode);
    widget.onThemeSelected?.call(mode);
  }

  void _onDone() {
    ThemeService().setTheme(_selectedTheme);
    widget.onThemeSelected?.call(_selectedTheme);
    Navigator.of(context).pop(_selectedTheme);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkPreview(context);

    final sheetBg = isDark ? AppColors.dark : AppColors.white;
    final headerIconBoxColor = isDark ? AppColors.white : AppColors.dark;
    final headerIconColor = isDark ? AppColors.dark : AppColors.white;
    final titleColor = isDark ? AppColors.white : AppColors.dark;
    final closeBorderColor = isDark
        ? AppColors.white.withValues(alpha: 0.3)
        : AppColors.dark.withValues(alpha: 0.3);
    final closeIconColor = isDark ? AppColors.white : AppColors.dark;
    final dividerColor =
        isDark ? const Color(0xFF28234B) : const Color(0xFFEEEEEE);

    final doneBtnBg = isDark ? AppColors.white : AppColors.dark;
    final doneBtnText = isDark ? AppColors.dark : AppColors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Icon + Title + Close Button
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: headerIconBoxColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: headerIconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pilih Tema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(_selectedTheme),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: closeBorderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: closeIconColor,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: dividerColor, height: 24),
            const SizedBox(height: 8),

            // Option 1: Mode Terang
            _buildThemeOption(
              mode: AppThemeMode.light,
              icon: Icons.wb_sunny_outlined,
              title: 'Mode Terang',
              subtitle: 'Tampilan cerah',
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Option 2: Mode Gelap
            _buildThemeOption(
              mode: AppThemeMode.dark,
              icon: Icons.nightlight_round,
              title: 'Mode Gelap',
              subtitle: 'Tampilan Gelap',
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Option 3: Ikuti Sistem
            _buildThemeOption(
              mode: AppThemeMode.system,
              icon: Icons.sync_rounded,
              title: 'Ikuti Sistem',
              subtitle: 'Sesuai Perangkat Anda',
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Selesai Button
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: _onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: doneBtnBg,
                    foregroundColor: doneBtnText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SELESAI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required AppThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = _selectedTheme == mode;

    final cardBg = isDark ? const Color(0xFF28234B) : const Color(0xFFF3F0FF);
    final iconColor = isDark ? AppColors.white : AppColors.dark;
    final titleColor = isDark ? AppColors.white : AppColors.dark;
    final subtitleColor = isDark
        ? const Color(0xFFA59ACF)
        : AppColors.dark.withValues(alpha: 0.6);
    final radioColor = isDark ? AppColors.white : AppColors.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onOptionTapped(mode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 26,
                color: iconColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Custom Radio Circle
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: radioColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: radioColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
