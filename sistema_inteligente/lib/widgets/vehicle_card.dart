import 'package:flutter/material.dart';

import '../models/vehiculo.dart';
import '../utils/constants.dart';

/// Tarjeta que muestra un vehículo familiar.
class VehicleCard extends StatelessWidget {
  final Vehiculo vehiculo;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehiculo, this.onTap});

  String get _etiquetaEstado {
    final e = Formatos.normalizarEstado(vehiculo.estado);
    if (e == 'bloqueado') return 'BLOQUEADO';
    if (e == 'operativo') return 'OPERATIVO';
    return 'SIN INFORMACIÓN';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = Formatos.colorDeEstado(vehiculo.estado);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.dividerColor.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tema.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_car_filled,
                  color: tema.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehiculo.placa.isEmpty ? 'Vehículo' : vehiculo.placa,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehiculo.marca} ${vehiculo.modelo}'.trim(),
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (vehiculo.conductorNombre != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Conductor: ${vehiculo.conductorNombre}',
                        style: tema.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.circle, size: 12, color: color),
                  const SizedBox(height: 4),
                  Text(
                    _etiquetaEstado,
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}