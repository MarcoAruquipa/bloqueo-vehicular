import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prueba.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../providers/auth_provider.dart';
import '../providers/ubicacion_provider.dart';
import '../providers/vehiculo_provider.dart';
import '../routes/app_routes.dart';
import '../services/alerta_service.dart';
import '../services/api_service.dart';
import '../services/prueba_service.dart';
import '../utils/constants.dart';
import '../widgets/location_status_card.dart';
import '../widgets/status_card.dart';
import 'alertas_screen.dart';
import 'compartir_ubicacion_screen.dart';
import 'historial_ubicacion_screen.dart';
import 'pruebas_screen.dart';
import 'ubicacion_screen.dart';
import 'vehiculos_screen.dart';

/// Pantalla principal con navegación inferior y el rol del usuario.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.indiceInicial = 0});

  final int indiceInicial;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _indice;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  Future<void> _salir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await context.read<AuthProvider>().cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    if (usuario == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sesión no disponible'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                ),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    final Widget contenido;
    switch (_indice) {
      case 0:
        contenido = _InicioDashboard(usuario: usuario);
      case 1:
        contenido = const VehiculosScreen();
      case 2:
        contenido = usuario.esConductor
            ? const CompartirUbicacionScreen()
            : const UbicacionScreen();
      case 3:
        contenido = const PruebasScreen();
      default:
        contenido = const AlertasScreen();
    }

    final iconoUbicacion =
        usuario.esConductor ? Icons.share_location : Icons.location_on_outlined;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SMART CAR',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  usuario.esResponsable ? 'Responsable' : 'Conductor',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _salir,
          ),
        ],
      ),
      body: contenido,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Vehículo',
          ),
          NavigationDestination(
            icon: Icon(iconoUbicacion),
            selectedIcon: Icon(iconoUbicacion),
            label: 'Ubicación',
          ),
          const NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Pruebas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

/// Contenido del inicio según el rol.
class _InicioDashboard extends StatefulWidget {
  final Usuario usuario;

  const _InicioDashboard({required this.usuario});

  @override
  State<_InicioDashboard> createState() => _InicioDashboardState();
}

class _InicioDashboardState extends State<_InicioDashboard> {
  final PruebaService _pruebaService = PruebaService();
  final AlertaService _alertaService = AlertaService();

  List<Prueba> _pruebas = const [];
  int _contadorAlertas = 0;
  bool _cargando = true;
  String? _errorPruebas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);
    final vp = context.read<VehiculoProvider>();
    final up = context.read<UbicacionProvider>();
    await vp.cargarVehiculos(forzar: true);

    final vehiculo = _vehiculoElegido(widget.usuario, vp);
    final vehiculoId = vehiculo?.id;

    if (vehiculoId != null) {
      await vp.cargarEstadoEsp32(vehiculoId);
      await up.cargarUltimaUbicacion(vehiculoId);
    }

    try {
      final pruebas = await _pruebaService.getPruebas();
      if (mounted) setState(() => _pruebas = _ordenarPruebas(pruebas));
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorPruebas = e.message);
    } on Exception {
      if (mounted) setState(() => _errorPruebas = 'No se pudieron cargar las pruebas');
    }

    try {
      final alertas = await _alertaService.getAlertas();
      if (mounted) setState(() => _contadorAlertas = alertas.length);
    } on Exception {
      // Sin alertas disponibles no bloquea el resto del panel.
    }

    if (mounted) setState(() => _cargando = false);
  }

  Vehiculo? _vehiculoElegido(
    Usuario usuario,
    VehiculoProvider vp,
  ) {
    if (usuario.vehiculoId != null) {
      final asignado = vp.vehiculoPorId(usuario.vehiculoId);
      if (asignado != null) return asignado;
    }
    final vehiculos = vp.vehiculos;
    if (vehiculos.isEmpty) return null;
    if (usuario.vehiculoPlaca != null) {
      for (final v in vehiculos) {
        if (v.placa == usuario.vehiculoPlaca) return v;
      }
    }
    return vehiculos.first;
  }

  List<Prueba> _ordenarPruebas(List<Prueba> pruebas) {
    final lista = [...pruebas];
    lista.sort((a, b) {
      final fa = '${a.fecha} ${a.hora}';
      final fb = '${b.fecha} ${b.hora}';
      return fb.compareTo(fa);
    });
    return lista;
  }

  Prueba? get _ultimaPrueba =>
      _pruebas.isNotEmpty ? _pruebas.first : null;

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: widget.usuario.esResponsable
          ? _BuildResponsable(
              vehiculo: _vehiculoElegido(
                widget.usuario,
                context.watch<VehiculoProvider>(),
              ),
              ultimaPrueba: _ultimaPrueba,
              contadorAlertas: _contadorAlertas,
              errorPruebas: _errorPruebas,
            )
          : _BuildConductor(
              usuario: widget.usuario,
              ultimaPrueba: _ultimaPrueba,
            ),
    );
  }
}

class _BuildResponsable extends StatelessWidget {
  final Vehiculo? vehiculo;
  final Prueba? ultimaPrueba;
  final int contadorAlertas;
  final String? errorPruebas;

  const _BuildResponsable({
    this.vehiculo,
    this.ultimaPrueba,
    required this.contadorAlertas,
    this.errorPruebas,
  });

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehiculoProvider>();
    final up = context.watch<UbicacionProvider>();
    final esp32 = vp.esp32;
    final ubicacion = up.ultimaUbicacion;

    final veh = vehiculo ?? (vp.vehiculos.isNotEmpty ? vp.vehiculos.first : null);

    final estadoVehiculo = veh?.estado ?? 'Sin información';
    final placaV = veh?.placa ?? '—';

    final fechaUbicacion = ubicacion?.fechaHora;
    final tituloUbicacion = up.ubicacionReciente
        ? 'Actualizada'
        : (ubicacion != null ? 'Última conocida' : 'No disponible');
    final colorUbicacion =
        up.ubicacionReciente ? Colors.green : (ubicacion != null ? Colors.orange : Colors.grey);

    final ultimaHora = fechaUbicacion != null
        ? Formatos.fechaHora.format(fechaUbicacion)
        : 'Sin datos';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('¡Hola! Este es el estado de tu familia y tu vehículo.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columnas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatusCard(
                  titulo: 'Vehículo',
                  valor: placaV,
                  icono: Icons.directions_car_filled,
                  subtitulo: veh != null
                      ? '${veh.marca} ${veh.modelo}'.trim()
                      : null,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatusCard(
                  titulo: 'Estado',
                  valor: estadoVehiculo.toUpperCase(),
                  icono: Icons.verified_user_outlined,
                  color: Formatos.colorDeEstado(estadoVehiculo),
                ),
                StatusCard(
                  titulo: 'Última prueba',
                  valor: ultimaPrueba?.resultado.toUpperCase() ?? 'Sin pruebas',
                  icono: Icons.science_outlined,
                  color: ultimaPrueba != null
                      ? Formatos.colorDeEstado(ultimaPrueba!.resultado)
                      : Colors.grey,
                  subtitulo: ultimaPrueba != null
                      ? '${ultimaPrueba!.fecha} ${ultimaPrueba!.hora}'.trim()
                      : null,
                ),
                StatusCard(
                  titulo: 'ESP32',
                  valor: esp32 == null
                      ? 'SIN CONEXIÓN'
                      : (esp32.conectado ? 'CONECTADO' : 'DESCONECTADO'),
                  icono: Icons.memory,
                  color: esp32?.conectado == true ? Colors.green : Colors.red,
                ),
                StatusCard(
                  titulo: 'Sensor MQ-3',
                  valor: (esp32?.sensor ?? 'desconocido').toUpperCase(),
                  icono: Icons.sensors,
                  color: Formatos.colorDeEstado(esp32?.sensor),
                ),
                StatusCard(
                  titulo: 'Ubicación',
                  valor: tituloUbicacion,
                  icono: Icons.location_on_outlined,
                  color: colorUbicacion,
                ),
                StatusCard(
                  titulo: 'Última actualización',
                  valor: ultimaHora,
                  icono: Icons.schedule,
                  color: Colors.blueGrey,
                ),
                StatusCard(
                  titulo: 'Alertas',
                  valor: '$contadorAlertas alertas',
                  icono: Icons.notifications_active_outlined,
                  color: contadorAlertas > 0 ? Colors.orange : Colors.grey,
                ),
              ],
            );
          },
        ),
        if (errorPruebas != null) ...[
          const SizedBox(height: 12),
          Text('Pruebas: $errorPruebas',
              style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        _BotonesRapidos(vehiculoId: veh?.id),
      ],
    );
  }
}

class _BotonesRapidos extends StatelessWidget {
  final int? vehiculoId;

  const _BotonesRapidos({this.vehiculoId});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _BotonRapido(
          icono: Icons.map_outlined,
          texto: 'Historial de ubicaciones',
          onTap: vehiculoId == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistorialUbicacionScreen(
                        vehiculoId: vehiculoId!,
                      ),
                    ),
                  ),
        ),
        _BotonRapido(
          icono: Icons.science_outlined,
          texto: 'Ver pruebas',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PruebasScreen()),
          ),
        ),
      ],
    );
  }
}

class _BotonRapido extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback? onTap;

  const _BotonRapido({
    required this.icono,
    required this.texto,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icono, size: 18),
      label: Text(texto),
      onPressed: onTap,
    );
  }
}

class _BuildConductor extends StatelessWidget {
  final Usuario usuario;
  final Prueba? ultimaPrueba;

  const _BuildConductor({required this.usuario, this.ultimaPrueba});

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehiculoProvider>();
    final up = context.watch<UbicacionProvider>();
    final vehiculo = vp.vehiculoPorId(usuario.vehiculoId) ??
        (vp.vehiculos.isNotEmpty ? vp.vehiculos.first : null);

    final enviada = up.ultimaEnviada;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONDUCTOR',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 1.2,
                    ),
              ),
              Text(
                usuario.nombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columnas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatusCard(
                  titulo: 'Vehículo',
                  valor: vehiculo?.placa ?? '—',
                  icono: Icons.directions_car_filled,
                  subtitulo:
                      '${vehiculo?.marca ?? ''} ${vehiculo?.modelo ?? ''}'.trim(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatusCard(
                  titulo: 'Estado',
                  valor: (vehiculo?.estado ?? 'Sin información').toUpperCase(),
                  icono: Icons.verified_user_outlined,
                  color: Formatos.colorDeEstado(vehiculo?.estado),
                ),
                StatusCard(
                  titulo: 'Última prueba',
                  valor: ultimaPrueba?.resultado.toUpperCase() ?? 'Sin pruebas',
                  icono: Icons.science_outlined,
                  color: ultimaPrueba != null
                      ? Formatos.colorDeEstado(ultimaPrueba!.resultado)
                      : Colors.grey,
                ),
                StatusCard(
                  titulo: 'Ubicación',
                  valor: up.compartiendo
                      ? 'COMPARTIENDO'
                      : (up.estado == EstadoComparticion.sinPermiso
                          ? 'SIN PERMISO'
                          : 'NO COMPARTIDA'),
                  icono: Icons.share_location,
                  color: up.compartiendo
                      ? Colors.green
                      : (up.estado == EstadoComparticion.sinPermiso
                          ? Colors.orange
                          : Colors.grey),
                ),
                StatusCard(
                  titulo: 'Última actualización',
                  valor: enviada?.hora?.isNotEmpty == true
                      ? Formatos.soloHora.format(
                          enviada!.fechaHora ?? DateTime.now())
                      : 'Sin envíos',
                  icono: Icons.schedule,
                  color: Colors.blueGrey,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LocationStatusCard(
          estado: up.estado,
          mensaje: up.mensaje,
          ultimaEnviada: enviada,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: up.compartiendo
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompartirUbicacionScreen(),
                    ),
                  ),
          icon: const Icon(Icons.share_location),
          label: const Text('Compartir ubicación'),
        ),
      ],
    );
  }
}