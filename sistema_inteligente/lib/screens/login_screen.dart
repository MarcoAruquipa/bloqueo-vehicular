import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../routes/app_routes.dart';

/// Pantalla moderna de inicio de sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;
  bool _recuperando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final error = await auth.iniciarSesion(
      _correoController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (error != null) {
      _mostrarError(error);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  Future<void> _recuperarContrasena() async {
    final controlador = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: controlador,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'correo@ejemplo.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controlador.text.trim().isEmpty) return;
              Navigator.of(context).pop();
              _enviarRecuperacion(controlador.text.trim());
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controlador.dispose();
  }

  Future<void> _enviarRecuperacion(String correo) async {
    setState(() => _recuperando = true);
    try {
      await AuthService().recuperarContrasena(correo);
      if (!mounted) return;
      _mostrarMensaje(
        'Si la cuenta existe, se enviaron las instrucciones a tu correo.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrarError(e.message);
    } on Exception {
      if (!mounted) return;
      _mostrarError('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _recuperando = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cargando = Provider.of<AuthProvider>(context).cargando;
    final colores = tema.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colores.primary,
              colores.primary.withValues(alpha: 0.85),
              colores.tertiary,
            ],
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
                            Icons.time_to_leave,
                            size: 64,
                            color: colores.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bloqueo Vehicular',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Sistema de detección de alcohol',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: colores.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
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
                            validator: (v) {
                              final valor = v?.trim() ?? '';
                              if (valor.isEmpty) {
                                return 'Ingresa tu correo electrónico';
                              }
                              final expresion = RegExp(
                                r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
                              );
                              if (!expresion.hasMatch(valor)) {
                                return 'Ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _ocultarPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _iniciarSesion(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_ocultarPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _ocultarPassword = !_ocultarPassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: cargando || _recuperando
                                ? null
                                : _iniciarSesion,
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
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _recuperando ? null : _recuperarContrasena,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              const Text('¿No tienes cuenta?'),
                              TextButton(
                                onPressed: cargando || _recuperando
                                    ? null
                                    : () => Navigator.of(context).pushNamed(
                                          AppRoutes.registro,
                                        ),
                                child: const Text('Regístrate'),
                              ),
                            ],
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