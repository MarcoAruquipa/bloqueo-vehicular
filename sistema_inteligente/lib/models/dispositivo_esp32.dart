import 'package:flutter/foundation.dart';

/// Estado del dispositivo ESP32 asociado a un vehículo.
@immutable
class DispositivoEsp32 {
  final int? id;
  final int? vehiculoId;
  final String identificador;
  final String estado;

  /// Fecha/hora de la última conexión (texto, ej. "2026-09-17 12:15:00").
  final String ultimaConexion;

  /// Estado de la conexión Wi-Fi según el ESP32.
  final String wifi;

  /// Estado reportado del sensor MQ-3.
  final String sensor;

  const DispositivoEsp32({
    this.id,
    this.vehiculoId,
    required this.identificador,
    this.estado = 'desconectado',
    this.ultimaConexion = '',
    this.wifi = 'desconocido',
    this.sensor = 'desconocido',
  });

  bool get conectado => estado.trim().toLowerCase() == 'conectado';

  factory DispositivoEsp32.fromJson(Map<String, dynamic> json) {
    return DispositivoEsp32(
      id: _intNullable(json['id']),
      vehiculoId: _intNullable(json['vehiculo_id']),
      identificador: (json['identificador'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? 'desconectado',
      ultimaConexion: (json['ultima_conexion'] as String?) ?? '',
      wifi: (json['wifi'] as String?) ?? 'desconocido',
      sensor: (json['sensor'] as String?) ?? 'desconocido',
    );
  }

  static int? _intNullable(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }
}