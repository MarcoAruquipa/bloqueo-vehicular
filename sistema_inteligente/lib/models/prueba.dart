import '../utils/constants.dart' show Formatos, ResultadoPrueba;

/// Prueba de alcohol registrada por el ESP32.
class Prueba {
  final int? id;
  final int? vehiculoId;
  final String? placa;
  final int? conductorId;
  final String? conductorNombre;
  final int? nivelAlcohol;
  final String resultado;
  final String fecha;
  final String hora;

  const Prueba({
    this.id,
    this.vehiculoId,
    this.placa,
    this.conductorId,
    this.conductorNombre,
    this.nivelAlcohol,
    required this.resultado,
    this.fecha = '',
    this.hora = '',
  });

  bool get esNormal =>
      Formatos.normalizarEstado(resultado) == ResultadoPrueba.normal;
  bool get esBloqueada =>
      Formatos.normalizarEstado(resultado) == ResultadoPrueba.bloqueado;
  bool get esError =>
      Formatos.normalizarEstado(resultado) == ResultadoPrueba.errorLectura;

  factory Prueba.fromJson(Map<String, dynamic> json) {
    return Prueba(
      id: Formatos.toInt(json['id']),
      vehiculoId: Formatos.toInt(json['vehiculo_id']),
      placa: (json['placa'] as String?) ?? (json['vehiculo'] as String?),
      conductorId: Formatos.toInt(json['conductor_id']),
      conductorNombre: (json['conductor_nombre'] as String?) ??
          (json['conductor'] as String?),
      nivelAlcohol: Formatos.toInt(json['nivel_alcohol']),
      resultado:
          (json['resultado'] as String?) ?? ResultadoPrueba.errorLectura,
      fecha: (json['fecha'] as String?) ?? '',
      hora: (json['hora'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (vehiculoId != null) 'vehiculo_id': vehiculoId,
        if (placa != null) 'vehiculo': placa,
        if (conductorId != null) 'conductor_id': conductorId,
        if (conductorNombre != null) 'conductor': conductorNombre,
        if (nivelAlcohol != null) 'nivel_alcohol': nivelAlcohol,
        'resultado': resultado,
        'fecha': fecha,
        'hora': hora,
      };
}