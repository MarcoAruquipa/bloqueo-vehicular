import 'dart:convert';

import 'api_service.dart';
import '../models/vehiculo.dart';

/// Servicio de consulta de vehículos familiares.
class VehiculoService {
  final ApiService _api;

  VehiculoService([ApiService? api]) : _api = api ?? apiService;

  Future<List<Vehiculo>> getVehiculos() async {
    final datos = await _api.get('/vehiculos');
    final lista = _extraerLista(datos, clave: 'vehiculos');
    return lista
        .map((e) => Vehiculo.fromJson(_mapa(e)))
        .toList(growable: false);
  }

  Future<Vehiculo> getVehiculo(int id) async {
    final datos = await _api.get('/vehiculos/$id');
    final mapa = _mapa(datos);
    if (mapa.containsKey('vehiculo')) {
      return Vehiculo.fromJson(_mapa(mapa['vehiculo']));
    }
    return Vehiculo.fromJson(mapa);
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