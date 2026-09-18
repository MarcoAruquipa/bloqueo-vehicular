import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sistema_inteligente/providers/auth_provider.dart';
import 'package:sistema_inteligente/providers/ubicacion_provider.dart';
import 'package:sistema_inteligente/providers/vehiculo_provider.dart';
import 'package:sistema_inteligente/screens/login_screen.dart';

void main() {
  testWidgets('La pantalla de login muestra los campos requeridos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => VehiculoProvider()),
          ChangeNotifierProvider(create: (_) => UbicacionProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsWidgets);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });
}
