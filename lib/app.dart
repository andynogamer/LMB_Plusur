import 'package:flutter/material.dart';

import 'models/equipo_model.dart';
import 'routes/app_routes.dart';
import 'screens/ar_view_screen.dart';
import 'screens/highlights_screen.dart';
import 'screens/history_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/team_list_screen.dart';
import 'screens/team_menu_screen.dart';
import 'screens/trivia_results_screen.dart';
import 'screens/trivia_screen.dart';
import 'theme/app_theme.dart';

class LmbPlusurApp extends StatelessWidget {
  const LmbPlusurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMB Plusur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final equipo =
        settings.arguments is Equipo ? settings.arguments as Equipo : null;

    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.main:
        return _page(const MainScreen(), settings);
      case AppRoutes.ar:
        return _page(ArViewScreen(equipoHint: equipo), settings);
      case AppRoutes.teams:
        return _page(const TeamListScreen(), settings);
      case AppRoutes.teamMenu:
        return _page(TeamMenuScreen(equipo: equipo!), settings);
      case AppRoutes.history:
        return _page(HistoryScreen(equipo: equipo!), settings);
      case AppRoutes.trivia:
        return _page(TriviaScreen(equipo: equipo!), settings);
      case AppRoutes.triviaResults:
        return _page(
          TriviaResultsScreen(
            puntaje: (settings.arguments as TriviaResultsArgs).puntaje,
            equipoId: (settings.arguments as TriviaResultsArgs).equipoId,
          ),
          settings,
        );
      case AppRoutes.highlights:
        return _page(HighlightsScreen(equipo: equipo!), settings);
      default:
        return _page(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<void> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => child,
      settings: settings,
    );
  }
}
