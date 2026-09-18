import 'package:flutter/material.dart';

import '../models/prueba.dart';
import '../services/api_service.dart';
import '../services/prueba_service.dart';
import '../utils/constants.dart';

/// Consulta de pruebas de alcohol registradas por el ESP32.
class PruebasScreen extends StatefulWidget {
  const PruebasScreen({super.key});

  @override
  State<PruebasScreen> createState() => _PruebasScreenState();
}

class _PruebasScreenState extends State<PruebasScreen> {
  final PruebaService _servicio = PruebaService();
  List<Prueba> _pruebas = const [];
  bool _cargando = true;
  String? _error;
  String _filtro = 'todas';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pruebas = await _servicio.getPruebas();
      pruebas.sort(_comparar);
      if (mounted) setState(() => _pruebas = pruebas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Exception {
      if (mounted) setState(() => _error = 'No se pudieron cargar las pruebas');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  int _comparar(Prueba a, Prueba b) {
    return '${b.fecha} ${b.hora}'.compareTo('${a.fecha} ${a.hora}');
  }

  List<Prueba> get _filtradas {
    switch (_filtro) {
      case 'normal':
        return _pruebas.where((p) => p.esNormal).toList();
      case 'bloqueado':
        return _pruebas.where((p) => p.esBloqueada).toList();
      case 'error':
        return _pruebas.where((p) => p.esError).toList();
      default:
        return _pruebas;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ChipFiltro(
                  etiqueta: 'Todas',
                  seleccionado: _filtro == 'todas',
                  onTap: () => setState(() => _filtro = 'todas'),
                ),
                _ChipFiltro(
                  etiqueta: 'Normal',
                  seleccionado: _filtro == 'normal',
                  onTap: () => setState(() => _filtro = 'normal'),
                ),
                _ChipFiltro(
                  etiqueta: 'Bloqueado',
                  seleccionado: _filtro == 'bloqueado',
                  onTap: () => setState(() => _filtro = 'bloqueado'),
                ),
                _ChipFiltro(
                  etiqueta: 'Error de lectura',
                  seleccionado: _filtro == 'error',
                  onTap: () => setState(() => _filtro = 'error'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorPruebas(mensaje: _error!, onReintentar: _cargar)
                  : _filtradas.isEmpty
                      ? const Center(
                          child: Text('No hay pruebas registradas'),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtradas.length,
                            itemBuilder: (context, i) =>
                                _PruebaCard(prueba: _filtradas[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(etiqueta),
        selected: seleccionado,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ErrorPruebas extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorPruebas({required this.mensaje, required this.onReintentar});

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
            const Text('No se pudieron cargar las pruebas'),
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

class _PruebaCard extends StatelessWidget {
  final Prueba prueba;

  const _PruebaCard({required this.prueba});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = Formatos.colorDeEstado(prueba.resultado);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined,
                    color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  prueba.resultado.toUpperCase(),
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${prueba.id ?? '—'}',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Info(etiqueta: 'Vehículo', valor: prueba.placa ?? '—'),
            const SizedBox(height: 4),
            _Info(etiqueta: 'Conductor', valor: prueba.conductorNombre ?? '—'),
            const SizedBox(height: 4),
            _Info(
              etiqueta: 'Nivel detectado',
              valor: '${prueba.nivelAlcohol ?? '—'} ppm',
            ),
            const SizedBox(height: 4),
            _Info(
              etiqueta: 'Fecha y hora',
              valor: '${prueba.fecha} ${prueba.hora}'.trim(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Info({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
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
    );
  }
}