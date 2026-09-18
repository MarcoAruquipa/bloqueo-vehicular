class Alerta {
  final int? id;
  final int? vehiculoId;
  final String tipo;
  final String mensaje;
  final String fecha;
  final String hora;
  final String estado;

  const Alerta({
    this.id,
    this.vehiculoId,
    required this.tipo,
    required this.mensaje,
    this.fecha = '',
    this.hora = '',
    this.estado = 'pendiente',
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: _toIntNull(json['id']),
      vehiculoId: _toIntNull(json['vehiculo_id']),
      tipo: (json['tipo'] as String?) ?? '',
      mensaje: (json['mensaje'] as String?) ?? '',
      fecha: (json['fecha'] as String?) ?? '',
      hora: (json['hora'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? 'pendiente',
    );
  }

  static int? _toIntNull(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }
}