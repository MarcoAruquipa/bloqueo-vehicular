import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehiculo.dart';
import '../providers/ubicacion_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../utils/constants.dart';
import '../widgets/status_card.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/location_map.dart';

/// Lista de vehículos de la familia.
class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VehiculoProvider>().cargarVehiculos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehiculoProvider>();

    if (vp.cargandoVehiculos && vp.vehiculos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vp.vehiculos.isEmpty && vp.error != null) {
      return _ErrorCarga(mensaje: vp.error!, onReintentar: vp.cargarVehiculos);
    }
    if (vp.vehiculos.isEmpty) {
      return const Center(
        child: Text('No hay vehículos registrados'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vp.cargarVehiculos(forzar: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vp.vehiculos.length,
        itemBuilder: (context, i) {
          final vehiculo = vp.vehiculos[i];
          return VehicleCard(
            vehiculo: vehiculo,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _DetalleVehiculoScreen(vehiculo: vehiculo),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 12),
            const Text('No se pudieron cargar los vehículos'),
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

/// Detalle de un vehículo: estado, ESP32 y última ubicación.
class _DetalleVehiculoScreen extends StatefulWidget {
  final Vehiculo vehiculo;

  const _DetalleVehiculoScreen({required this.vehiculo});

  @override
  State<_DetalleVehiculoScreen> createState() => _DetalleVehiculoScreenState();
}

class _DetalleVehiculoScreenState extends State<_DetalleVehiculoScreen> {
  int? _vehiculoId;

  @override
  void initState() {
    super.initState();
    _vehiculoId = widget.vehiculo.id;
    final id = _vehiculoId;
    final vp = context.read<VehiculoProvider>();
    final up = context.read<UbicacionProvider>();
    if (id != null) {
      Future.microtask(() {
        vp.cargarEstadoEsp32(id);
        up.cargarUltimaUbicacion(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehiculoProvider>();
    final up = context.watch<UbicacionProvider>();
    final esp32 = vp.esp32;
    final ubicacion = up.ultimaUbicacion;
    final vehiculo = widget.vehiculo;

    return Scaffold(
      appBar: AppBar(title: Text(vehiculo.placa)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatusCard(
            titulo: 'Vehículo',
            valor: vehiculo.placa,
            icono: Icons.directions_car_filled,
            subtitulo: '${vehiculo.marca} ${vehiculo.modelo}'.trim(),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          StatusCard(
            titulo: 'Estado',
            valor: vehiculo.estado.toUpperCase(),
            icono: Icons.verified_user_outlined,
            color: Formatos.colorDeEstado(vehiculo.estado),
          ),
          const SizedBox(height: 12),
          Text(
            'ESP32',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (vp.cargandoEsp32)
            const LinearProgressIndicator()
          else
            StatusCard(
              titulo: 'Estado',
              valor: esp32 == null
                  ? 'SIN CONEXIÓN'
                  : (esp32.conectado ? 'CONECTADO' : 'DESCONECTADO'),
              icono: Icons.memory,
              color: esp32?.conectado == true ? Colors.green : Colors.red,
              subtitulo: esp32 == null
                  ? 'El ESP32 está desconectado'
                  : 'Última conexión: ${esp32.ultimaConexion}',
            ),
          const SizedBox(height: 12),
          if (esp32 != null) ...[
            StatusCard(
              titulo: 'Wi-Fi',
              valor: esp32.wifi.toUpperCase(),
              icono: Icons.wifi,
              color: Formatos.colorDeEstado(esp32.wifi),
            ),
            const SizedBox(height: 12),
            StatusCard(
              titulo: 'Sensor MQ-3',
              valor: esp32.sensor.toUpperCase(),
              icono: Icons.sensors,
              color: Formatos.colorDeEstado(esp32.sensor),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Ubicación del vehículo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (up.cargandoInfo && ubicacion == null)
            const LinearProgressIndicator()
          else if (ubicacion == null)
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se ha recibido una ubicación reciente'),
            ))
          else ...[
            LocationMap(
              latitud: ubicacion.latitud,
              longitud: ubicacion.longitud,
              tituloMarcador: 'Vehículo ${vehiculo.placa}',
            ),
            const SizedBox(height: 8),
            StatusCard(
              titulo: 'Última ubicación',
              valor: up.ubicacionReciente
                  ? 'ACTUALIZADA'
                  : 'ÚLTIMA REGISTRADA',
              icono: Icons.location_on_outlined,
              color: up.ubicacionReciente ? Colors.green : Colors.orange,
              subtitulo: ubicacion.fechaHora != null
                  ? Formatos.fechaHora.format(ubicacion.fechaHora!)
                  : '',
            ),
          ],
        ],
      ),
    );
  }
}