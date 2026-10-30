import 'package:flutter/services.dart';

/// Model Kode Negara untuk Selector
class CountryCode {
  final String name;
  final String flag;
  final String dialCode;

  const CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

const List<CountryCode> supportedCountries = [
  CountryCode(name: 'Indonesia', flag: '🇮🇩', dialCode: '+62'),
  CountryCode(name: 'Malaysia', flag: '🇲🇾', dialCode: '+60'),
  CountryCode(name: 'Singapura', flag: '🇸🇬', dialCode: '+65'),
  CountryCode(name: 'Filipina', flag: '🇵🇭', dialCode: '+63'),
  CountryCode(name: 'Thailand', flag: '🇹🇭', dialCode: '+66'),
  CountryCode(name: 'Vietnam', flag: '🇻🇳', dialCode: '+84'),
  CountryCode(name: 'Arab Saudi', flag: '🇸🇦', dialCode: '+966'),
  CountryCode(name: 'Amerika Serikat', flag: '🇺🇸', dialCode: '+1'),
  CountryCode(name: 'Inggris', flag: '🇬🇧', dialCode: '+44'),
  CountryCode(name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
  CountryCode(name: 'Jepang', flag: '🇯🇵', dialCode: '+81'),
  CountryCode(name: 'Korea Selatan', flag: '🇰🇷', dialCode: '+82'),
];

/// Formatter Nomor Telepon (Cegah awalan 0 dan berikan spasi otomatis setiap 4 digit)
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Cegah angka 0 di awal nomor
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 7 || i == 11) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
