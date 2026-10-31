import 'package:flutter/material.dart';
import '../modules/register/country_picker_sheet.dart';
import '../../../../core/models/country_code.dart';

export '../modules/register/country_picker_sheet.dart';

/// Backward-compatible wrapper for CountryPickerSheet
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
    CountryPickerSheet.show(
      context,
      selectedCountry: selectedCountry,
      onCountrySelected: onCountrySelected,
      title: title,
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CountryPickerSheet(
      selectedCountry: selectedCountry,
      onCountrySelected: onCountrySelected,
      title: title,
      subtitle: subtitle,
    );
  }
}
