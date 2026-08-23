import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title,
    this.showBack = true,
  });

  final String? title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    if (showBack && canPop)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: 28,
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    const AppLogo(size: 52),
                  ],
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 8),
                Text(
                  title!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: 0.8,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
