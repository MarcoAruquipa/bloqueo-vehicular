import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ubicacion.dart';
import '../models/vehiculo.dart';
import '../providers/ubicacion_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/constants.dart';
import '../widgets/location_map.dart';
import 'historial_ubicacion_screen.dart';

/// Pantalla “Ubicación del vehículo” para el responsable.
///
/// Muestra la última ubicación real compartida desde el teléfono del
/// conductor, diferenciando entre ubicación actualizada y última conocida.
class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  int? _vehiculoId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_inicializar);
  }

  Future<void> _inicializar() async {
    final vp = context.read<VehiculoProvider>();
    await vp.cargarVehiculos();
    if (!mounted) return;
    final vehiculos = vp.vehiculos;
    if (vehiculos.isEmpty) return;
    final seleccionado = vehiculos.first.id;
    setState(() {
      _vehiculoId = _vehiculoId ?? seleccionado;
    });
    await _cargarUbicacion(_vehiculoId);
  }

  Future<void> _cargarUbicacion(int? vehiculoId) async {
    if (vehiculoId == null) return;
    setState(() => _vehiculoId = vehiculoId);
    final up = context.read<UbicacionProvider>();
    await up.cargarUltimaUbicacion(vehiculoId);
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehiculoProvider>();
    final up = context.watch<UbicacionProvider>();
    final vehiculos = vp.vehiculos;

    if (vp.cargandoVehiculos && vehiculos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vehiculos.isEmpty) {
      return const Center(child: Text('No hay vehículos registrados'));
    }

    final vehiculo = _vehiculoElegido(vehiculos, _vehiculoId);
    final ubicacion = up.ultimaUbicacion;

    return RefreshIndicator(
      onRefresh: () => _cargarUbicacion(vehiculo?.id),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (vehiculos.length > 1) ...[
            DropdownButtonFormField<int>(
              initialValue: vehiculo?.id,
              decoration: const InputDecoration(
                labelText: 'Vehículo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              items: vehiculos
                  .map((v) => DropdownMenuItem(value: v.id, child: Text(v.placa)))
                  .toList(),
              onChanged: (id) {
                if (id != null) _cargarUbicacion(id);
              },
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Ubicación del vehículo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'La posición proviene del GPS del teléfono del conductor '
            'cuando compartió su ubicación.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (up.cargandoInfo && ubicacion == null)
            const LinearProgressIndicator()
          else if (ubicacion == null)
            const _SinUbicacion()
          else
            _MapaYPormenores(
              vehiculo: vehiculo!,
              ubicacion: ubicacion,
              reciente: up.ubicacionReciente,
            ),
        ],
      ),
    );
  }

  Vehiculo? _vehiculoElegido(List<Vehiculo> vehiculos, int? id) {
    for (final v in vehiculos) {
      if (v.id == id) return v;
    }
    return vehiculos.isNotEmpty ? vehiculos.first : null;
  }
}

class _SinUbicacion extends StatelessWidget {
  const _SinUbicacion();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: tema.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              'No se ha recibido una ubicación reciente',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Cuando el conductor comparta su ubicación, podrás verla aquí.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaYPormenores extends StatelessWidget {
  final Vehiculo vehiculo;
  final Ubicacion ubicacion;
  final bool reciente;

  const _MapaYPormenores({
    required this.vehiculo,
    required this.ubicacion,
    required this.reciente,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fecha = ubicacion.fechaHora;
    final placa = vehiculo.placa.isEmpty ? 'Vehículo' : vehiculo.placa;
    final conductor = ubicacion.conductorNombre ??
        vehiculo.conductorNombre ??
        '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationMap(
          latitud: ubicacion.latitud,
          longitud: ubicacion.longitud,
          tituloMarcador: 'Vehículo $placa',
        ),
        const SizedBox(height: 12),
        if (!reciente)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Última ubicación conocida\nEl conductor dejó de enviar '
                    'ubicación o está sin conexión.',
                    style: tema.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tema.dividerColor.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Fila(etiqueta: 'Vehículo', valor: placa),
                _Fila(etiqueta: 'Conductor', valor: conductor),
                _Fila(
                  etiqueta: 'Última ubicación',
                  valor: fecha != null ? Formatos.fechaHora.format(fecha) : '—',
                ),
                _Fila(
                  etiqueta: 'Precisión',
                  valor: '${ubicacion.precision?.round() ?? '—'} metros',
                ),
                _Fila(
                  etiqueta: 'Estado de conexión',
                  valor: reciente ? 'Conectado' : 'Sin conexión',
                ),
                _Fila(
                  etiqueta: 'Estado de ubicación',
                  valor: reciente ? 'Ubicación disponible' : 'Última registrada',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistorialUbicacionScreen(
                vehiculoId: vehiculo.id ?? 0,
                titulo: placa,
              ),
            ),
          ),
          icon: const Icon(Icons.route_outlined),
          label: const Text('Historial de ubicaciones'),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Fila({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
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