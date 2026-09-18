import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../utils/constants.dart';

/// Tarjeta que muestra una alerta del sistema.
class AlertCard extends StatelessWidget {
  final Alerta alerta;

  const AlertCard({super.key, required this.alerta});

  IconData get _icono {
    final t = Formatos.normalizarEstado(alerta.tipo);
    if (t.contains('alcohol') || t.contains('prueba')) {
      return Icons.science_outlined;
    }
    if (t.contains('esp32') || t.contains('conexi')) {
      return Icons.wifi_off;
    }
    if (t.contains('sensor')) {
      return Icons.sensors_off;
    }
    if (t.contains('ubicaci') || t.contains('ubicación')) {
      return Icons.location_off_outlined;
    }
    return Icons.notifications_active_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = Formatos.colorDeEstado(
        alerta.tipo.contains('reciente') ? 'no recibida' : alerta.estado);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icono, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.tipo.isEmpty
                        ? 'Alerta'
                        : alerta.tipo[0].toUpperCase() +
                            alerta.tipo.substring(1),
                    style: tema.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alerta.mensaje,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14,
                          color: tema.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${alerta.fecha} ${alerta.hora}'.trim(),
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alerta.estado.toUpperCase(),
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}