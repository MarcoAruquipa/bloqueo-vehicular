import 'dart:convert';

import 'api_service.dart';
import '../models/dispositivo_esp32.dart';

/// Servicio de consulta del estado del ESP32.
class Esp32Service {
  final ApiService _api;

  Esp32Service([ApiService? api]) : _api = api ?? apiService;

  /// Consulta el estado del ESP32 asociado a un vehículo.
  Future<DispositivoEsp32> getEstadoEsp32(int vehiculoId) async {
    final datos = await _api.get('/estado-esp32?vehiculo_id=$vehiculoId');
    final mapa = _mapa(datos);
    if (mapa.containsKey('dispositivo')) {
      return DispositivoEsp32.fromJson(_mapa(mapa['dispositivo']));
    }
    return DispositivoEsp32.fromJson(mapa);
  }

  Map<String, dynamic> _mapa(Object? datos) {
    if (datos is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(datos));
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    if (datos is Map) return Map<String, dynamic>.from(datos);
    return <String, dynamic>{};
  }
}