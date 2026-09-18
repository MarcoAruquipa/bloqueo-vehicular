import 'package:flutter/foundation.dart';

import '../models/dispositivo_esp32.dart';
import '../models/vehiculo.dart';
import '../services/api_service.dart';
import '../services/esp32_service.dart';
import '../services/vehiculo_service.dart';

/// Maneja los vehículos de la familia y el estado del ESP32.
class VehiculoProvider extends ChangeNotifier {
  final VehiculoService _vehiculoService;
  final Esp32Service _esp32Service;

  List<Vehiculo>? _vehiculos;
  DispositivoEsp32? _esp32;
  bool _cargandoVehiculos = false;
  bool _cargandoEsp32 = false;
  String? _error;

  VehiculoProvider({VehiculoService? vehiculoService, Esp32Service? esp32Service})
      : _vehiculoService = vehiculoService ?? VehiculoService(),
        _esp32Service = esp32Service ?? Esp32Service();

  List<Vehiculo> get vehiculos => _vehiculos ?? const [];
  DispositivoEsp32? get esp32 => _esp32;
  bool get cargandoVehiculos => _cargandoVehiculos;
  bool get cargandoEsp32 => _cargandoEsp32;
  String? get error => _error;

  Vehiculo? vehiculoPorId(int? id) {
    if (id == null) return null;
    for (final v in vehiculos) {
      if (v.id == id) return v;
    }
    return null;
  }

  Future<void> cargarVehiculos({bool forzar = false}) async {
    if (_vehiculos != null && !forzar) return;
    _cargandoVehiculos = true;
    _error = null;
    notifyListeners();
    try {
      _vehiculos = await _vehiculoService.getVehiculos();
    } on ApiException catch (e) {
      _error = e.message;
    } on Exception {
      _error = 'No se pudieron cargar los vehículos';
    } finally {
      _cargandoVehiculos = false;
      notifyListeners();
    }
  }

  Future<void> cargarEstadoEsp32(int vehiculoId) async {
    _cargandoEsp32 = true;
    _esp32 = null;
    notifyListeners();
    try {
      _esp32 = await _esp32Service.getEstadoEsp32(vehiculoId);
    } on Exception {
      _esp32 = null;
    } finally {
      _cargandoEsp32 = false;
      notifyListeners();
    }
  }
}