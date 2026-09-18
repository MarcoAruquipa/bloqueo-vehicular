import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'api_service.dart';
import '../models/ubicacion.dart';

/// Resultado de un intento de obtención de ubicación.
enum EstadoObtencion {
  ok,
  servicioDesactivado,
  permisoDenegado,
  permisoDenegadoDefinitivo,
  sinSenal,
  error,
}

class ResultadoUbicacion {
  final EstadoObtencion estado;
  final Ubicacion? ubicacion;
  final Position? posicion;
  final String mensaje;

  const ResultadoUbicacion({
    required this.estado,
    this.ubicacion,
    this.posicion,
    this.mensaje = '',
  });

  bool get exitoso => estado == EstadoObtencion.ok;
}

/// Servicio de ubicación: permisos del teléfono y comunicación con la API.
class UbicacionService {
  final ApiService _api;

  UbicacionService([ApiService? api]) : _api = api ?? apiService;

  /// Última ubicación registrada del vehículo, o `null` si no existe.
  Future<Ubicacion?> getUltimaUbicacion(int vehiculoId) async {
    try {
      final datos = await _api.get('/ubicacion/$vehiculoId');
      final mapa = _mapa(datos);
      final u = mapa['ubicacion'] ?? mapa;
      if (u is Map && u.isNotEmpty) {
        return Ubicacion.fromJson(_mapa(u));
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Historial de ubicaciones del vehículo.
  Future<List<Ubicacion>> getHistorial(int vehiculoId) async {
    final datos = await _api.get('/ubicaciones/$vehiculoId');
    final lista = _extraerLista(datos, clave: 'ubicaciones');
    return lista
        .map((e) => Ubicacion.fromJson(_mapa(e)))
        .toList(growable: false);
  }

  /// Envía una ubicación real del teléfono del conductor.
  Future<void> enviarUbicacion(Ubicacion ubicacion) async {
    await _api.post('/api/ubicaciones', body: ubicacion.toJson());
  }

  /// Notifica al backend que el conductor comenzó a compartir.
  Future<void> iniciarComparticion({
    required int conductorId,
    required int vehiculoId,
  }) async {
    await _api.post(
      '/api/ubicacion/iniciar',
      body: {'conductor_id': conductorId, 'vehiculo_id': vehiculoId},
    );
  }

  /// Notifica al backend que el conductor dejó de compartir.
  Future<void> detenerComparticion({required int conductorId}) async {
    try {
      await _api.post(
        '/api/ubicacion/detener',
        body: {'conductor_id': conductorId},
      );
    } on ApiException {
      // No debe impedir que el conductor detenga el envío localmente.
    }
  }

  // ---------------------------------------------------------------------
  // Permisos y obtención de posición del teléfono.
  // ---------------------------------------------------------------------

  Future<bool> servicioActivado() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> permisoActual() =>
      Geolocator.checkPermission();

  Future<LocationPermission> solicitarPermiso() =>
      Geolocator.requestPermission();

  /// Obtiene la posición real del teléfono.
  Future<Position> obtenerPosicion() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  /// Verifica permisos, consulta el GPS del teléfono y devuelve una
  /// [Ubicacion] real. Nunca inventa coordenadas.
  Future<ResultadoUbicacion> obtenerUbicacion({
    required int vehiculoId,
    required int conductorId,
  }) async {
    if (!await servicioActivado()) {
      return const ResultadoUbicacion(
        estado: EstadoObtencion.servicioDesactivado,
        mensaje: 'Activa la ubicación del teléfono para compartir tu posición',
      );
    }

    var permiso = await permisoActual();
    if (permiso == LocationPermission.denied) {
      permiso = await solicitarPermiso();
    }
    if (permiso == LocationPermission.denied) {
      return const ResultadoUbicacion(
        estado: EstadoObtencion.permisoDenegado,
        mensaje: 'Permiso de ubicación requerido',
      );
    }
    if (permiso == LocationPermission.deniedForever) {
      return const ResultadoUbicacion(
        estado: EstadoObtencion.permisoDenegadoDefinitivo,
        mensaje:
            'Permiso de ubicación rechazado. Puedes activarlo desde la '
            'configuración del teléfono cuando quieras.',
      );
    }

    try {
      final posicion = await obtenerPosicion();
      final ahora = DateTime.now();
      return ResultadoUbicacion(
        estado: EstadoObtencion.ok,
        posicion: posicion,
        ubicacion: Ubicacion(
          vehiculoId: vehiculoId,
          conductorId: conductorId,
          latitud: posicion.latitude,
          longitud: posicion.longitude,
          precision: posicion.accuracy,
          fecha:
              '${ahora.year.toString().padLeft(4, '0')}-'
              '${ahora.month.toString().padLeft(2, '0')}-'
              '${ahora.day.toString().padLeft(2, '0')}',
          hora:
              '${ahora.hour.toString().padLeft(2, '0')}:'
              '${ahora.minute.toString().padLeft(2, '0')}:'
              '${ahora.second.toString().padLeft(2, '0')}',
        ),
      );
    } catch (e) {
      return const ResultadoUbicacion(
        estado: EstadoObtencion.sinSenal,
        mensaje: 'No se pudo obtener la ubicación en este momento',
      );
    }
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