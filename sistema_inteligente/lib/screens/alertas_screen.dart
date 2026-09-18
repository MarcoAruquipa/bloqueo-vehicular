import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../services/alerta_service.dart';
import '../services/api_service.dart';
import '../widgets/alert_card.dart';

/// Consulta de alertas del sistema.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final AlertaService _servicio = AlertaService();
  List<Alerta>? _alertas;
  String? _error;
  bool _cargando = true;

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
      final alertas = await _servicio.getAlertas();
      alertas.sort((a, b) => '${b.fecha} ${b.hora}'.compareTo('${a.fecha} ${a.hora}'));
      if (mounted) setState(() => _alertas = alertas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Exception {
      if (mounted) setState(() => _error = 'No se pudieron cargar las alertas');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _alertas == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _alertas == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 8),
              const Text('No se pudieron cargar las alertas'),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final alertas = _alertas ?? const <Alerta>[];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Estas son las alertas recientes del sistema.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: alertas.isEmpty
              ? const Center(child: Text('No hay alertas registradas'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: alertas.length,
                    itemBuilder: (context, i) => AlertCard(alerta: alertas[i]),
                  ),
                ),
        ),
      ],
    );
  }
}