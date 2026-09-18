import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../providers/auth_provider.dart';
import '../providers/ubicacion_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/constants.dart';
import '../widgets/location_status_card.dart';

/// Pantalla del conductor para compartir su ubicación con el responsable.
///
/// Solo se obtiene la ubicación del GPS del teléfono con permiso explícito.
class CompartirUbicacionScreen extends StatefulWidget {
  const CompartirUbicacionScreen({super.key});

  @override
  State<CompartirUbicacionScreen> createState() =>
      _CompartirUbicacionScreenState();
}

class _CompartirUbicacionScreenState extends State<CompartirUbicacionScreen> {
  bool _trabajando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VehiculoProvider>().cargarVehiculos();
    });
  }

  Vehiculo? _vehiculo(BuildContext context) {
    final vp = context.watch<VehiculoProvider>();
    final u = context.watch<AuthProvider>().usuario;
    return vp.vehiculoPorId(u?.vehiculoId) ??
        (vp.vehiculos.isNotEmpty ? vp.vehiculos.first : null);
  }

  Future<void> _iniciar() async {
    final up = context.read<UbicacionProvider>();
    final u = context.read<AuthProvider>().usuario;
    final vp = context.read<VehiculoProvider>();
    await vp.cargarVehiculos();
    if (!mounted) return;

    final vehiculo = vp.vehiculoPorId(u?.vehiculoId) ??
        (vp.vehiculos.isNotEmpty ? vp.vehiculos.first : null);
    if (u?.id == null || vehiculo?.id == null) {
      _mensaje('No se encontró un vehículo asignado para compartir ubicación');
      return;
    }

    setState(() => _trabajando = true);
    await up.iniciarComparticion(
      conductorId: u!.id!,
      vehiculoId: vehiculo!.id!,
    );
    if (mounted) setState(() => _trabajando = false);
  }

  Future<void> _detener() async {
    final up = context.read<UbicacionProvider>();
    setState(() => _trabajando = true);
    await up.detenerComparticion();
    if (mounted) setState(() => _trabajando = false);
  }

  Future<void> _abrirConfiguracion() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      _mensaje('No se pudo abrir la configuración del teléfono');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UbicacionProvider>();
    final vehiculo = _vehiculo(context);
    final usuario = context.watch<AuthProvider>().usuario;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer
              .withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Compartir ubicación',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Para mostrar la ubicación del vehículo al responsable '
                  'autorizado, esta aplicación necesita acceder a la '
                  'ubicación de este teléfono. Puedes permitir o rechazar '
                  'este permiso.',
                ),
                const SizedBox(height: 8),
                Text(
                  'La ubicación solo es visible para los responsables '
                  'autorizados y nunca se usa para controlar el vehículo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (vehiculo != null)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Vehículo asignado'),
              subtitle:
                  Text('${vehiculo.placa} (${vehiculo.marca} ${vehiculo.modelo})'
                      .trim()),
            ),
          )
        else
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay un vehículo asignado a tu cuenta.'),
            ),
          ),
        const SizedBox(height: 16),
        LocationStatusCard(
          estado: up.estado,
          mensaje: up.mensaje,
          ultimaEnviada: up.ultimaEnviada,
        ),
        const SizedBox(height: 16),
        if (up.estado == EstadoComparticion.sinPermiso) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _trabajando ? null : _iniciar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar nuevamente'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _abrirConfiguracion,
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else if (!up.compartiendo)
          FilledButton.icon(
            onPressed: _trabajando ? null : _iniciar,
            icon: _trabajando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_location),
            label: const Text('Compartir ubicación'),
          )
        else
          OutlinedButton.icon(
            onPressed: _trabajando ? null : _detener,
            icon: const Icon(Icons.stop_circle_outlined),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            label: const Text('Dejar de compartir'),
          ),
        const SizedBox(height: 20),
        Text(
          'Frecuencia de envío',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Evita un consumo excesivo de batería y datos.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Duration>(
          initialValue: up.frecuencia,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          items: UbicacionConfig.frecuenciasDisponibles
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(_etiquetaFrecuencia(d)),
                  ))
              .toList(),
          onChanged: _trabajando
              ? null
              : (d) {
                  if (d != null) up.setFrecuencia(d);
                },
        ),
        const SizedBox(height: 24),
        Text(
          'Nota: tu ubicación se envía periódicamente mientras la función '
          'esté activa. Si pierdes Internet, se conserva la última '
          'ubicación registrada y el responsable la verá como "última '
          'conocida".',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        _BannerSesion(usuario: usuario),
      ],
    );
  }

  String _etiquetaFrecuencia(Duration d) {
    if (d.inSeconds < 60) return 'Cada ${d.inSeconds} segundos';
    final minutos = d.inMinutes;
    return minutos == 1 ? 'Cada minuto' : 'Cada $minutos minutos';
  }
}

/// Recordatorio discreto de que hay una sesión activa para el conductor.
class _BannerSesion extends StatelessWidget {
  final Usuario? usuario;

  const _BannerSesion({this.usuario});

  @override
  Widget build(BuildContext context) {
    if (usuario == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Compartiendo como ${usuario!.nombre}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}