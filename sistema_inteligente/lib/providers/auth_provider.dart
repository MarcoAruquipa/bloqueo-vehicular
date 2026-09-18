import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

/// Resultado del registro de un nuevo usuario.
class ResultadoRegistro {
  final String? error;
  final bool sesionIniciada;

  const ResultadoRegistro({this.error, this.sesionIniciada = false});

  bool get exitoso => error == null;
}

/// Maneja la autenticación y la persistencia segura de la sesión.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  Usuario? _usuario;
  bool _cargando = false;

  AuthProvider({AuthService? authService, FlutterSecureStorage? storage})
      : _authService = authService ?? AuthService(),
        _storage = storage ?? const FlutterSecureStorage();

  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get sesionIniciada => _usuario != null;
  bool get esResponsable => _usuario?.esResponsable ?? false;
  bool get esConductor => _usuario?.esConductor ?? false;

  /// Inicia sesión. Devuelve `null` en caso de éxito o el mensaje de error.
  Future<String?> iniciarSesion(String correo, String password) async {
    _cargando = true;
    notifyListeners();
    try {
      final resultado = await _authService.login(correo, password);
      _usuario = resultado.usuario;
      apiService.setToken(resultado.token);
      await _guardarSesion(resultado.token);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } on Exception {
      return 'No se pudo conectar con el servidor';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registra un nuevo miembro de la familia.
  ///
  /// Devuelve el [ResultadoRegistro]. Si el backend no devuelve token, la
  /// cuenta se crea pero el usuario debe iniciar sesión después.
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
  }) async {
    _cargando = true;
    notifyListeners();
    try {
      final resultado = await _authService.register(
        nombre: nombre,
        correo: correo,
        password: password,
        rol: rol,
      );
      if (resultado != null) {
        _usuario = resultado.usuario;
        apiService.setToken(resultado.token);
        await _guardarSesion(resultado.token);
        return const ResultadoRegistro(sesionIniciada: true);
      }
      return const ResultadoRegistro();
    } on ApiException catch (e) {
      return ResultadoRegistro(error: e.message);
    } on Exception {
      return const ResultadoRegistro(error: 'No se pudo conectar con el servidor');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Restaura la sesión guardada en el almacenamiento seguro.
  Future<bool> restaurarSesion() async {
    try {
      final token = await _storage.read(key: StorageKeys.token);
      final usuarioJson = await _storage.read(key: StorageKeys.usuario);
      if (token == null || usuarioJson == null) return false;
      final usuario = Usuario.fromJson(jsonDecode(usuarioJson));
      _usuario = usuario;
      apiService.setToken(token);
      notifyListeners();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    await _storage.delete(key: StorageKeys.token);
    await _storage.delete(key: StorageKeys.usuario);
    apiService.setToken(null);
    _usuario = null;
    notifyListeners();
  }

  Future<void> _guardarSesion(String? token) async {
    if (_usuario == null) return;
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: StorageKeys.token, value: token);
    }
    await _storage.write(
      key: StorageKeys.usuario,
      value: jsonEncode(_usuario!.toJson()),
    );
  }
}