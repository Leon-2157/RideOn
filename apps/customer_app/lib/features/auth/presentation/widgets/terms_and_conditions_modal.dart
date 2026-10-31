import 'package:flutter/material.dart';
import '../modules/register/terms_bottom_sheet.dart';

export '../modules/register/terms_bottom_sheet.dart';

/// Backward-compatible wrapper for TermsBottomSheet
class TermsAndConditionsModal extends StatelessWidget {
  final VoidCallback onAgree;

  const TermsAndConditionsModal({
    super.key,
    required this.onAgree,
  });

  static void show(BuildContext context, {required VoidCallback onAgree}) {
    TermsBottomSheet.show(context, onAgree: onAgree);
  }

  @override
  Widget build(BuildContext context) {
    return TermsBottomSheet(onAgree: onAgree);
  }
}
