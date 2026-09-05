import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = true,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  if (showBack && canPop)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.navyCard,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.button.withValues(alpha: 0.35)),
                    ),
                    child: const AppLogo(size: 46),
                  ),
                ],
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 4),
              Text(
                title!.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 0.8,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 42,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.button.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
