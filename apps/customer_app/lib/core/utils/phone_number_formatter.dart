import 'package:flutter/services.dart';

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

