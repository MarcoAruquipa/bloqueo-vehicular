import '../utils/constants.dart' show Formatos, EstadoVehiculo;

/// Vehículo familiar registrado en el sistema.
class Vehiculo {
  final int? id;
  final String placa;
  final String marca;
  final String modelo;
  final int? conductorId;
  final String? conductorNombre;
  final String estado;

  const Vehiculo({
    this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    this.conductorId,
    this.conductorNombre,
    this.estado = EstadoVehiculo.sinInformacion,
  });

  bool get bloqueado => Formatos.normalizarEstado(estado) == 'bloqueado';
  bool get operativo => Formatos.normalizarEstado(estado) == 'operativo';

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: Formatos.toInt(json['id']),
      placa: (json['placa'] as String?) ?? '',
      marca: (json['marca'] as String?) ?? '',
      modelo: (json['modelo'] as String?) ?? '',
      conductorId: Formatos.toInt(json['conductor_id']),
      conductorNombre: (json['conductor_nombre'] as String?) ??
          (json['conductor'] as String?),
      estado: (json['estado'] as String?) ?? EstadoVehiculo.sinInformacion,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'placa': placa,
        'marca': marca,
        'modelo': modelo,
        if (conductorId != null) 'conductor_id': conductorId,
        if (conductorNombre != null) 'conductor_nombre': conductorNombre,
        'estado': estado,
      };
}