import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/country_code.dart';

/// Modal Bottom Sheet Pemilih Negara & Kode Nomor Telepon
class CountryPickerModal extends StatelessWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode> onCountrySelected;
  final String title;
  final String subtitle;

  const CountryPickerModal({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
    this.title = 'Pilih Negara & Kode Nomor',
    this.subtitle = 'Format kode telepon internasional',
  });

  static void show(
    BuildContext context, {
    required CountryCode selectedCountry,
    required ValueChanged<CountryCode> onCountrySelected,
    String title = 'Pilih Negara & Kode Nomor',
    String subtitle = 'Format kode telepon internasional',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerModal(
        selectedCountry: selectedCountry,
        onCountrySelected: onCountrySelected,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.dark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2DCFE)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: supportedCountries.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFEEEBFE)),
              itemBuilder: (context, index) {
                final item = supportedCountries[index];
                final isSelected = item.dialCode == selectedCountry.dialCode;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : null,
                  leading: Text(
                    item.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    item.name,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.dark,
                    ),
                  ),
                  trailing: Text(
                    item.dialCode,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.dark,
                    ),
                  ),
                  onTap: () {
                    onCountrySelected(item);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

