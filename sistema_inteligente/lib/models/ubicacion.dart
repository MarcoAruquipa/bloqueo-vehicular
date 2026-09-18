import 'package:intl/intl.dart';

/// Ubicación real del teléfono del conductor asociada a un vehículo.
class Ubicacion {
  final int? id;
  final int? vehiculoId;
  final String? placa;
  final int? conductorId;
  final String? conductorNombre;
  final double latitud;
  final double longitud;
  final double? precision;
  final String? fecha;
  final String? hora;

  const Ubicacion({
    this.id,
    this.vehiculoId,
    this.placa,
    this.conductorId,
    this.conductorNombre,
    required this.latitud,
    required this.longitud,
    this.precision,
    this.fecha,
    this.hora,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: _intNullable(json['id']),
      vehiculoId: _intNullable(json['vehiculo_id']),
      placa: (json['placa'] as String?) ?? (json['vehiculo'] as String?),
      conductorId: _intNullable(json['conductor_id']),
      conductorNombre: (json['conductor_nombre'] as String?) ??
          (json['conductor'] as String?),
      latitud: _double(json['latitud']),
      longitud: _double(json['longitud']),
      precision: _doubleNullable(json['precision']),
      fecha: (json['fecha'] as String?) ?? '',
      hora: (json['hora'] as String?) ?? '',
    );
  }

  /// Datos enviados al backend (`POST /api/ubicaciones`).
  Map<String, dynamic> toJson() => {
        if (vehiculoId != null) 'vehiculo_id': vehiculoId,
        if (conductorId != null) 'conductor_id': conductorId,
        'latitud': latitud,
        'longitud': longitud,
        if (precision != null) 'precision': precision,
        'fecha': fecha ?? '',
        'hora': hora ?? '',
      };

  /// Fecha/hora combinadas, o `null` si no pueden parsearse.
  DateTime? get fechaHora {
    final texto = '${fecha ?? ''} ${hora ?? ''}'.trim();
    if (texto.isEmpty) return null;
    const formatos = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'yyyy-MM-ddTHH:mm:ss',
    ];
    for (final f in formatos) {
      try {
        return DateFormat(f).parseStrict(texto);
      } catch (_) {
        // continúa con el siguiente formato
      }
    }
    return DateTime.tryParse(texto);
  }

  static int? _intNullable(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }

  static double _double(Object? valor, [double defecto = 0]) {
    if (valor == null) return defecto;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? defecto;
  }

  static double? _doubleNullable(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString().replaceAll(',', '.'));
  }
}