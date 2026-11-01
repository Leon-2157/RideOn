import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'country_code_model.dart';

/// Field nomor telepon dengan country picker dropdown & auto-spacing
class RegisterPhoneField extends StatelessWidget {
  final TextEditingController phoneController;
  final CountryCode selectedCountry;
  final VoidCallback onCountryTap;
  final bool isPhoneValid;

  const RegisterPhoneField({
    super.key,
    required this.phoneController,
    required this.selectedCountry,
    required this.onCountryTap,
    required this.isPhoneValid,
  });

  @override
  Widget build(BuildContext context) {
    Color phoneBorderColor;
    double phoneBorderWidth;

    if (phoneController.text.trim().isEmpty) {
      phoneBorderColor = Colors.white.withValues(alpha: 0.35);
      phoneBorderWidth = 0.8;
    } else if (isPhoneValid) {
      phoneBorderColor = const Color(0xFF00B894);
      phoneBorderWidth = 1.2;
    } else {
      phoneBorderColor = const Color(0xFFE83535);
      phoneBorderWidth = 1.2;
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 6.0, right: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13.0),
        gradient: LinearGradient(
          begin: const Alignment(-0.94, -0.69),
          end: const Alignment(0.94, 0.78),
          stops: const [0.45, 1.0],
          colors: [
            AppColors.primary.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(
          color: phoneBorderColor,
          width: phoneBorderWidth,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            key: const Key('btn_country_picker'),
            onTap: onCountryTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    selectedCountry.dialCode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: AppColors.dark,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppColors.dark.withValues(alpha: 0.25),
          ),
          Expanded(
            child: TextField(
              key: const Key('input_register_phone'),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneNumberFormatter(),
              ],
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                hintText: '812 3456 7890',
                hintStyle: GoogleFonts.roboto(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.65),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
