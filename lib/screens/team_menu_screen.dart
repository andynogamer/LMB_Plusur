import 'package:flutter/material.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

class TeamMenuScreen extends StatelessWidget {
  const TeamMenuScreen({
    super.key,
    required this.equipo,
  });

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          AppHeader(title: equipo.displayName),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PrimaryButton(
                    label: 'Historia',
                    height: 64,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.history,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Trivia',
                    height: 64,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.trivia,
                        arguments: equipo,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Highlights',
                    height: 64,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.highlights,
                        arguments: equipo,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
