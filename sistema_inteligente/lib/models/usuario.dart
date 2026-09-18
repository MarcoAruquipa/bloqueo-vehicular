import '../utils/constants.dart' show Formatos;

/// Usuario de la aplicación (responsable o conductor).
class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String rol;

  /// Vehículo asignado al usuario (importante para el conductor).
  final String? vehiculoPlaca;
  final int? vehiculoId;

  const Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.vehiculoPlaca,
    this.vehiculoId,
  });

  bool get esResponsable => Formatos.normalizarEstado(rol) == 'responsable';
  bool get esConductor => Formatos.normalizarEstado(rol) == 'conductor';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: Formatos.toInt(json['id']),
      nombre: (json['nombre'] as String?) ?? '',
      correo: (json['correo'] as String?) ?? '',
      rol: (json['rol'] as String?) ?? 'conductor',
      vehiculoPlaca: (json['vehiculo_placa'] as String?) ??
          (json['placa'] as String?),
      vehiculoId: Formatos.toInt(json['vehiculo_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'correo': correo,
        'rol': rol,
        if (vehiculoPlaca != null) 'vehiculo_placa': vehiculoPlaca,
        if (vehiculoId != null) 'vehiculo_id': vehiculoId,
      };
}