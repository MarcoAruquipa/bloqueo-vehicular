import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';

/// Registro de un nuevo miembro de la familia.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;
  String _rol = AppRoles.conductor;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final resultado = await auth.registrar(
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      password: _passwordController.text,
      rol: _rol,
    );
    if (!mounted) return;

    if (!resultado.exitoso) {
      _mostrarError(resultado.error ?? 'No se pudo crear la cuenta');
      return;
    }

    if (resultado.sesionIniciada) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
      return;
    }

    _mostrarMensaje('Cuenta creada correctamente. Ahora inicia sesión.');
    Navigator.of(context).pop();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  String? _validarCorreo(String? v) {
    final valor = v?.trim() ?? '';
    if (valor.isEmpty) return 'Ingresa tu correo electrónico';
    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(valor)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validarPassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  String? _validarConfirmacion(String? v) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final cargando = context.watch<AuthProvider>().cargando;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colores.primary, colores.tertiary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.group_add_outlined,
                            size: 56,
                            color: colores.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crear cuenta',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Registra a un nuevo miembro de la familia',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nombreController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Ingresa tu nombre'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _correoController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validarCorreo,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _ocultarPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_ocultarPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _ocultarPassword =
                                        !_ocultarPassword),
                              ),
                            ),
                            validator: _validarPassword,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmarController,
                            obscureText: _ocultarConfirmacion,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _registrar(),
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_ocultarConfirmacion
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _ocultarConfirmacion =
                                        !_ocultarConfirmacion),
                              ),
                            ),
                            validator: _validarConfirmacion,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Rol en la familia',
                            style: tema.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: AppRoles.conductor,
                                icon: Icon(Icons.directions_car_outlined),
                                label: Text('Conductor'),
                              ),
                              ButtonSegment(
                                value: AppRoles.responsable,
                                icon: Icon(Icons.family_restroom),
                                label: Text('Responsable'),
                              ),
                            ],
                            selected: {_rol},
                            onSelectionChanged: (s) =>
                                setState(() => _rol = s.first),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Solo registra a personas autorizadas de tu '
                            'familia. El responsable podrá ver la ubicación '
                            'y las alertas del vehículo.',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: cargando ? null : _registrar,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: cargando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: cargando
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Ya tengo cuenta · Iniciar sesión'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}