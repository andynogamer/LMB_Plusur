import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          const AppHeader(showBack: false),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PrimaryButton(
                    label: 'Escanear Logo',
                    height: 64,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.ar);
                    },
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Seleccionar Equipo Manualmente',
                    height: 64,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.teams);
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
