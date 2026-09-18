import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/ubicacion.dart';
import '../services/api_service.dart';
import '../services/ubicacion_service.dart';
import '../utils/constants.dart';

/// Estado visible del uso compartido de ubicación para el conductor.
enum EstadoComparticion {
  inactiva,
  activa,
  sinServicio,
  sinPermiso,
  sinInternet,
  error,
}

/// Maneja el GPS del teléfono del conductor y las consultas del responsable.
///
/// IMPORTANTE: la ubicación se obtiene con permiso explícito del conductor,
/// nunca se inventan coordenadas y el vehículo no se controla con ella.
class UbicacionProvider extends ChangeNotifier {
  final UbicacionService _servicio;

  Timer? _timer;
  bool _compartiendo = false;
  EstadoComparticion _estado = EstadoComparticion.inactiva;
  String _mensaje = '';
  Ubicacion? _ultimaEnviada;
  Duration _frecuencia = UbicacionConfig.frecuenciaPorDefecto;
  int? _conductorActivoId;
  int? _vehiculoActivoId;

  Ubicacion? _ultimaUbicacion;
  List<Ubicacion> _historial = const [];
  bool _cargandoInfo = false;
  String? _error;

  UbicacionProvider({UbicacionService? servicio})
      : _servicio = servicio ?? UbicacionService();

  bool get compartiendo => _compartiendo;
  EstadoComparticion get estado => _estado;
  String get mensaje => _mensaje;
  Ubicacion? get ultimaEnviada => _ultimaEnviada;
  Duration get frecuencia => _frecuencia;

  Ubicacion? get ultimaUbicacion => _ultimaUbicacion;
  bool get hayUbicacion => _ultimaUbicacion != null;
  List<Ubicacion> get historial => _historial;
  bool get cargandoInfo => _cargandoInfo;
  String? get error => _error;

  /// `true` si la última ubicación fue recibida hace poco tiempo.
  bool get ubicacionReciente {
    final u = _ultimaUbicacion;
    final f = u?.fechaHora;
    if (u == null || f == null) return false;
    return DateTime.now().difference(f) <= UbicacionConfig.maxEdadReciente;
  }

  // ------------------------------------------------------------------
  // Compartir ubicación (conductor)
  // ------------------------------------------------------------------

  /// Inicia el uso compartido periódico. Solicita permisos si es necesario.
  Future<void> iniciarComparticion({
    required int conductorId,
    required int vehiculoId,
  }) async {
    _conductorActivoId = conductorId;
    _vehiculoActivoId = vehiculoId;

    if (!await _servicio.servicioActivado()) {
      _detenerTimerYEstado(EstadoComparticion.sinServicio,
          'Activa la ubicación del teléfono para compartir tu posición');
      return;
    }

    var permiso = await _servicio.permisoActual();
    if (permiso == LocationPermission.denied) {
      permiso = await _servicio.solicitarPermiso();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _detenerTimerYEstado(
          EstadoComparticion.sinPermiso, 'Permiso de ubicación requerido');
      return;
    }

    _compartiendo = true;
    _estado = EstadoComparticion.activa;
    _mensaje = '';
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(_frecuencia, (_) => _enviarAhora());
    await _enviarAhora();

    try {
      await _servicio.iniciarComparticion(
        conductorId: conductorId,
        vehiculoId: vehiculoId,
      );
    } on Exception {
      // El envío local continúa aunque la notificación al backend falle.
    }
  }

  /// Detiene el envío de ubicación y notifica al backend.
  Future<void> detenerComparticion() async {
    final conductor = _conductorActivoId;
    _timer?.cancel();
    _timer = null;
    _compartiendo = false;
    _estado = EstadoComparticion.inactiva;
    notifyListeners();
    if (conductor != null) {
      await _servicio.detenerComparticion(conductorId: conductor);
    }
  }

  /// Cambia la frecuencia del envío periódico.
  void setFrecuencia(Duration duracion) {
    _frecuencia = duracion;
    if (_compartiendo) {
      _timer?.cancel();
      _timer = Timer.periodic(duracion, (_) => _enviarAhora());
    }
    notifyListeners();
  }

  Future<void> _enviarAhora() async {
    final conductor = _conductorActivoId;
    final vehiculo = _vehiculoActivoId;
    if (!_compartiendo || conductor == null || vehiculo == null) return;

    if (!await _servicio.servicioActivado()) {
      _estado = EstadoComparticion.sinServicio;
      _mensaje = 'Activa la ubicación del teléfono para compartir tu posición';
      notifyListeners();
      return;
    }

    final resultado = await _servicio.obtenerUbicacion(
      vehiculoId: vehiculo,
      conductorId: conductor,
    );

    if (resultado.exitoso && resultado.ubicacion != null) {
      try {
        await _servicio.enviarUbicacion(resultado.ubicacion!);
        _ultimaEnviada = resultado.ubicacion;
        _estado = EstadoComparticion.activa;
        _mensaje = '';
      } on ApiException catch (e) {
        if (e.message.contains('Internet')) {
          _estado = EstadoComparticion.sinInternet;
          _mensaje = 'Sin conexión';
        } else {
          _estado = EstadoComparticion.error;
          _mensaje = e.message;
        }
      } catch (_) {
        _estado = EstadoComparticion.error;
        _mensaje = 'Error al enviar la ubicación';
      }
    } else {
      _estado = resultado.estado == EstadoObtencion.permisoDenegado ||
              resultado.estado == EstadoObtencion.permisoDenegadoDefinitivo
          ? EstadoComparticion.sinPermiso
          : resultado.estado == EstadoObtencion.servicioDesactivado
              ? EstadoComparticion.sinServicio
              : EstadoComparticion.error;
      _mensaje = resultado.mensaje;
    }
    notifyListeners();
  }

  void _detenerTimerYEstado(EstadoComparticion estado, String mensaje) {
    _compartiendo = false;
    _estado = estado;
    _mensaje = mensaje;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Consultas del responsable
  // ------------------------------------------------------------------

  Future<void> cargarUltimaUbicacion(int vehiculoId) async {
    _cargandoInfo = true;
    _error = null;
    notifyListeners();
    try {
      _ultimaUbicacion = await _servicio.getUltimaUbicacion(vehiculoId);
    } on ApiException catch (e) {
      _error = e.message;
    } on Exception {
      _error = 'No se pudo cargar la ubicación';
    } finally {
      _cargandoInfo = false;
      notifyListeners();
    }
  }

  Future<void> cargarHistorial(int vehiculoId) async {
    _cargandoInfo = true;
    _error = null;
    notifyListeners();
    try {
      final lista = await _servicio.getHistorial(vehiculoId);
      _historial = lista.reversed.toList(growable: false);
    } on ApiException catch (e) {
      _error = e.message;
    } on Exception {
      _error = 'No se pudo cargar el historial de ubicaciones';
    } finally {
      _cargandoInfo = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}