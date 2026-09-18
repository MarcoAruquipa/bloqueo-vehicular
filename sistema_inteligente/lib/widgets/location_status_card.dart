import 'package:flutter/material.dart';

import '../models/ubicacion.dart';
import '../providers/ubicacion_provider.dart';
import '../utils/constants.dart';

/// Tarjeta que resume el estado de la ubicación (compartida, sin permiso,
/// sin conexión, etc.) y cuándo fue la última actualización.
class LocationStatusCard extends StatelessWidget {
  final EstadoComparticion estado;
  final String mensaje;
  final Ubicacion? ultimaEnviada;
  final bool recibidaRecientemente;

  const LocationStatusCard({
    super.key,
    required this.estado,
    required this.mensaje,
    this.ultimaEnviada,
    this.recibidaRecientemente = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final (titulo, subtitulo, icono, color) = _textos();

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: tema.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (subtitulo.isNotEmpty)
              Text(subtitulo, style: tema.textTheme.bodyMedium),
            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                mensaje,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (ultimaEnviada != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _FilaInfo(
                icono: Icons.schedule,
                etiqueta: 'Última actualización',
                valor: Formatos.fechaHora.format(ultimaEnviada!.fechaHora ??
                    DateTime.now()),
              ),
              const SizedBox(height: 6),
              _FilaInfo(
                icono: Icons.gps_fixed,
                etiqueta: 'Precisión',
                valor: '${ultimaEnviada!.precision?.round() ?? '—'} m',
              ),
              const SizedBox(height: 6),
              _FilaInfo(
                icono: Icons.location_on_outlined,
                etiqueta: 'Coordenadas',
                valor:
                    '${ultimaEnviada!.latitud.toStringAsFixed(5)}, ${ultimaEnviada!.longitud.toStringAsFixed(5)}',
              ),
            ],
            if (recibidaRecientemente) ...[
              const SizedBox(height: 12),
              Text(
                'Ubicación actualizada recientemente',
                style: tema.textTheme.labelMedium?.copyWith(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, String, IconData, Color) _textos() {
    switch (estado) {
      case EstadoComparticion.activa:
        return (
          'Ubicación compartida',
          'El vehículo mostrará tu posición a los responsables autorizados.',
          Icons.share_location,
          Colors.green,
        );
      case EstadoComparticion.inactiva:
        return (
          'Ubicación no compartida',
          'El responsable no puede ver la ubicación del vehículo.',
          Icons.location_off_outlined,
          Colors.grey,
        );
      case EstadoComparticion.sinPermiso:
        return (
          'Permiso de ubicación requerido',
          'Activa el permiso desde la configuración del teléfono.',
          Icons.location_disabled,
          Colors.orange,
        );
      case EstadoComparticion.sinServicio:
        return (
          'Ubicación desactivada',
          'Activa la ubicación del teléfono para compartir tu posición.',
          Icons.location_off,
          Colors.orange,
        );
      case EstadoComparticion.sinInternet:
        return (
          'Sin conexión',
          'No se puede enviar la ubicación en este momento.',
          Icons.wifi_off,
          Colors.red,
        );
      case EstadoComparticion.error:
        return (
          'Error de ubicación',
          mensaje.isEmpty ? 'Ocurrió un problema al enviar la ubicación.' : mensaje,
          Icons.error_outline,
          Colors.red,
        );
    }
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaInfo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Icon(icono, size: 16, color: tema.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          etiqueta,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: tema.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}