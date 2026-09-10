import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size * dpr).round().clamp(48, 512);
    return ClipOval(
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: px,
        cacheHeight: px,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Logo LMB Plusur',
      ),
    );
  }
}
