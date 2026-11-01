import 'package:flutter/material.dart';
import '../../../../../core/constants/app_assets.dart';

/// Logo + judul bagian atas halaman Login.
class LoginHeaderView extends StatelessWidget {
  const LoginHeaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logoWhite,
      width: 124,
      height: 83,
      fit: BoxFit.contain,
    );
  }
}

