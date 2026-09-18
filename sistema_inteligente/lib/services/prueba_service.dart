import 'dart:convert';

import 'api_service.dart';
import '../models/prueba.dart';

/// Servicio de consulta de pruebas de alcohol.
class PruebaService {
  final ApiService _api;

  PruebaService([ApiService? api]) : _api = api ?? apiService;

  Future<List<Prueba>> getPruebas() async {
    final datos = await _api.get('/pruebas');
    final lista = _extraerLista(datos, clave: 'pruebas');
    return lista.map((e) => Prueba.fromJson(_mapa(e))).toList(growable: false);
  }

  Future<Prueba> getPrueba(int id) async {
    final datos = await _api.get('/pruebas/$id');
    final mapa = _mapa(datos);
    if (mapa.containsKey('prueba')) return Prueba.fromJson(_mapa(mapa['prueba']));
    return Prueba.fromJson(mapa);
  }

  Future<List<Prueba>> getPruebasPorVehiculo(int vehiculoId) async {
    final datos = await _api.get('/pruebas?vehiculo_id=$vehiculoId');
    final lista = _extraerLista(datos, clave: 'pruebas');
    return lista.map((e) => Prueba.fromJson(_mapa(e))).toList(growable: false);
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