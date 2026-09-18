import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registro_screen.dart';

/// Rutas de la aplicación.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String registro = '/registro';
  static const String dashboard = '/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registro:
        return MaterialPageRoute(builder: (_) => const RegistroScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}