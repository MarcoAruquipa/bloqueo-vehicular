import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/ubicacion_provider.dart';
import 'providers/vehiculo_provider.dart';
import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartCarApp());
}

class SmartCarApp extends StatelessWidget {
  const SmartCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehiculoProvider()),
        ChangeNotifierProvider(create: (_) => UbicacionProvider()),
      ],
      child: MaterialApp(
        title: 'Sistema de Bloqueo Vehicular',
        debugShowCheckedModeBanner: false,
        theme: _tema(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const _PantallaCarga(),
      ),
    );
  }

  ThemeData _tema() {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0));
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Pantalla de arranque: restaura la sesión guardada y redirige.
class _PantallaCarga extends StatefulWidget {
  const _PantallaCarga();

  @override
  State<_PantallaCarga> createState() => _PantallaCargaState();
}

class _PantallaCargaState extends State<_PantallaCarga> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final sesion = await context.read<AuthProvider>().restaurarSesion();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      sesion ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.primary, color.tertiary],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.time_to_leave, size: 72, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'SMART CAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}