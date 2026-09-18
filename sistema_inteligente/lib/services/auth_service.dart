import 'dart:convert';

import 'api_service.dart';
import '../models/usuario.dart';

/// Resultado de un inicio de sesión exitoso.
class LoginResult {
  final String? token;
  final Usuario usuario;

  const LoginResult({this.token, required this.usuario});
}

/// Servicio de autenticación y recuperación de contraseña.
class AuthService {
  final ApiService _api;

  AuthService([ApiService? api]) : _api = api ?? apiService;

  /// Inicia sesión con correo y contraseña.
  Future<LoginResult> login(String correo, String password) async {
    final datos = await _api.post(
      '/login',
      body: {'correo': correo.trim(), 'password': password},
    );
    final mapa = _mapa(datos);
    final token = mapa['token'] ?? mapa['access_token'];
    final usuarioMapa = mapa['usuario'] ?? mapa['user'] ?? mapa;
    return LoginResult(
      token: token?.toString(),
      usuario: Usuario.fromJson(_mapa(usuarioMapa)),
    );
  }

  /// Solicita el restablecimiento de la contraseña.
  Future<void> recuperarContrasena(String correo) async {
    await _api.post(
      '/recuperar-contrasena',
      body: {'correo': correo.trim()},
    );
  }

  /// Registra un nuevo usuario de la familia.
  ///
  /// Devuelve el [LoginResult] si el backend inicia sesión automáticamente,
  /// o `null` si solo crea la cuenta (entonces el usuario debe iniciar sesión).
  Future<LoginResult?> register({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
  }) async {
    final datos = await _api.post(
      '/register',
      body: {
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'password': password,
        'rol': rol,
      },
    );
    final mapa = _mapa(datos);
    final token = mapa['token'] ?? mapa['access_token'] ?? mapa['auth_token'];
    if (token == null) return null;
    final usuarioMapa = mapa['usuario'] ?? mapa['user'] ?? mapa;
    return LoginResult(
      token: token.toString(),
      usuario: Usuario.fromJson(_mapa(usuarioMapa)),
    );
  }

  Map<String, dynamic> _mapa(Object? datos) {
    if (datos is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(datos));
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    if (datos is Map) {
      return Map<String, dynamic>.from(datos);
    }
    return <String, dynamic>{};
  }
}