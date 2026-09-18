import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Excepción propia con mensaje entendible para la interfaz.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente HTTP centralizado.
///
/// Todas las peticiones usan [ApiConfig.apiBaseUrl], llevan el token de
/// autenticación cuando existe y traducen errores de red a [ApiException]
/// con mensajes comprensibles para el usuario.
class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Uri _uri(String path) {
    final base = ApiConfig.apiBaseUrl.endsWith('/')
        ? ApiConfig.apiBaseUrl.substring(0, ApiConfig.apiBaseUrl.length - 1)
        : ApiConfig.apiBaseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (ApiConfig.apiKey.isNotEmpty)
          ApiConfig.apiKeyHeader: ApiConfig.apiKey,
        if (_token != null && _token!.isNotEmpty)
          'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) =>
      _ejecutar(() => http.get(_uri(path), headers: _headers()));

  Future<dynamic> post(String path, {Object? body}) => _ejecutar(
        () => http.post(
          _uri(path),
          headers: _headers(),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<dynamic> put(String path, {Object? body}) => _ejecutar(
        () => http.put(
          _uri(path),
          headers: _headers(),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<dynamic> _ejecutar(Future<http.Response> Function() solicitud) async {
    try {
      final respuesta =
          await solicitud().timeout(ApiConfig.tiempoLimitePeticion);
      dynamic datos;
      try {
        datos = respuesta.body.isEmpty ? null : jsonDecode(respuesta.body);
      } on FormatException {
        datos = null;
      }

      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
        if (datos is Map && datos.containsKey('error')) {
          throw ApiException('${datos['error']}',
              statusCode: respuesta.statusCode);
        }
        return datos;
      }

      String mensaje = 'Error del servidor';
      if (datos is Map) {
        mensaje = (datos['mensaje'] ??
                datos['message'] ??
                datos['error'] ??
                mensaje)
            .toString();
      }
      if (respuesta.statusCode == 401) {
        mensaje = 'Credenciales incorrectas o sesión expirada';
      }
      if (respuesta.statusCode == 404) {
        mensaje = 'No se encontró el recurso solicitado';
      }
      throw ApiException(mensaje, statusCode: respuesta.statusCode);
    } on TimeoutException {
      throw const ApiException('No se pudo conectar con el servidor');
    } on SocketException {
      throw const ApiException('Sin conexión a Internet');
    } on http.ClientException {
      throw const ApiException('Sin conexión a Internet');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('No se pudo conectar con el servidor');
    }
  }
}

/// Instancia compartida del cliente HTTP.
final ApiService apiService = ApiService();