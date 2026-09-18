import 'package:flutter/material.dart';

/// Tarjeta genérica de estado utilizada en los dashboards.
class StatusCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? color;
  final String? subtitulo;

  const StatusCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: color?.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color?.withValues(alpha: 0.25) ?? tema.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icono, size: 28, color: color ?? tema.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo.toUpperCase(),
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color ?? tema.colorScheme.onSurface,
              ),
            ),
            if (subtitulo != null && subtitulo!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitulo!,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}