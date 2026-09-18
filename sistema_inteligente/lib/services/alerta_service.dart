import 'dart:convert';

import 'api_service.dart';
import '../models/alerta.dart';

/// Servicio de consulta de alertas.
class AlertaService {
  final ApiService _api;

  AlertaService([ApiService? api]) : _api = api ?? apiService;

  Future<List<Alerta>> getAlertas() async {
    final datos = await _api.get('/alertas');
    final lista = _extraerLista(datos, clave: 'alertas');
    return lista.map((e) => Alerta.fromJson(_mapa(e))).toList(growable: false);
  }

  List<dynamic> _extraerLista(Object? datos, {String clave = 'data'}) {
    if (datos is List) return datos;
    if (datos is Map) {
      final v = datos[clave] ?? datos['data'];
      if (v is List) return v;
    }
    return <dynamic>[];
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