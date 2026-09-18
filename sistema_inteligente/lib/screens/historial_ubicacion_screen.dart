import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ubicacion.dart';
import '../providers/ubicacion_provider.dart';
import '../utils/constants.dart';
import '../widgets/location_map.dart';

/// Historial de ubicaciones compartidas por el conductor.
class HistorialUbicacionScreen extends StatefulWidget {
  final int vehiculoId;
  final String? titulo;

  const HistorialUbicacionScreen({
    super.key,
    required this.vehiculoId,
    this.titulo,
  });

  @override
  State<HistorialUbicacionScreen> createState() =>
      _HistorialUbicacionScreenState();
}

class _HistorialUbicacionScreenState extends State<HistorialUbicacionScreen> {
  bool _verMapa = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<UbicacionProvider>()
            .cargarHistorial(widget.vehiculoId);
      }
    });
  }

  Future<void> _recargar() async {
    await context.read<UbicacionProvider>().cargarHistorial(widget.vehiculoId);
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UbicacionProvider>();
    final historial = up.historial;

    final historialOrdenado = [...historial];
    historialOrdenado.sort((a, b) {
      final fa = a.fechaHora ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fb = b.fechaHora ?? DateTime.fromMillisecondsSinceEpoch(0);
      return fb.compareTo(fa);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo == null
            ? 'Historial de ubicaciones'
            : 'Historial · ${widget.titulo}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.list_alt_outlined),
                  label: Text('Lista'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Mapa'),
                ),
              ],
              selected: {_verMapa},
              onSelectionChanged: (s) => setState(() => _verMapa = s.first),
            ),
          ),
          Expanded(
            child: up.cargandoInfo && historial.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : up.error != null && historial.isEmpty
                    ? _ErrorHistorial(
                        mensaje: up.error!,
                        onReintentar: _recargar,
                      )
                    : historial.isEmpty
                        ? const Center(
                            child: Text(
                              'No se han registrado ubicaciones aún',
                            ),
                          )
                        : _verMapa
                            ? _VistaMapa(
                                historial: historialOrdenado,
                                placa: widget.titulo ?? 'Vehículo',
                              )
                            : RefreshIndicator(
                                onRefresh: _recargar,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: historialOrdenado.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) => _RegistroCard(
                                    ubicacion: historialOrdenado[i],
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }
}

class _RegistroCard extends StatelessWidget {
  final Ubicacion ubicacion;

  const _RegistroCard({required this.ubicacion});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fecha = ubicacion.fechaHora;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fecha != null ? Formatos.fechaHora.format(fecha) : '—',
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Linea(etiqueta: 'Fecha', valor: Formatos.fecha.format(fecha ?? DateTime.now())),
            _Linea(etiqueta: 'Hora', valor: Formatos.hora.format(fecha ?? DateTime.now())),
            _Linea(etiqueta: 'Conductor', valor: ubicacion.conductorNombre ?? '—'),
            _Linea(etiqueta: 'Vehículo', valor: ubicacion.placa ?? '—'),
            _Linea(
              etiqueta: 'Latitud',
              valor: ubicacion.latitud.toStringAsFixed(5),
            ),
            _Linea(
              etiqueta: 'Longitud',
              valor: ubicacion.longitud.toStringAsFixed(5),
            ),
            _Linea(
              etiqueta: 'Precisión',
              valor: '${ubicacion.precision?.round() ?? '—'} metros',
            ),
          ],
        ),
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Linea({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              etiqueta,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: tema.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VistaMapa extends StatelessWidget {
  final List<Ubicacion> historial;
  final String placa;

  const _VistaMapa({required this.historial, required this.placa});

  @override
  Widget build(BuildContext context) {
    final masReciente = historial.isNotEmpty ? historial.first : null;
    if (masReciente == null) {
      return const Center(child: Text('Sin ubicaciones para mostrar'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMap(
            latitud: masReciente.latitud,
            longitud: masReciente.longitud,
            tituloMarcador: 'Vehículo $placa',
            puntos: historial.reversed.toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'La línea azul representa el recorrido compartido desde el '
            'teléfono del conductor.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorHistorial extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorHistorial({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 8),
            const Text('No se pudo cargar el historial'),
            const SizedBox(height: 4),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}