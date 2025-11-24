import 'package:flutter/material.dart';

import '../models/service.dart';
import '../services/current_service_session.dart';

class ServiceInfoPage extends StatelessWidget {
  const ServiceInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Service?>(
      valueListenable: CurrentServiceSession.instance.currentService,
      builder: (context, service, _) {
        final content = service == null
            ? const Center(
                child: Text('No hay un servicio activo en este momento'),
              )
            : _ServiceDetails(service: service);

        return Scaffold(
          appBar: AppBar(title: const Text('Servicio actual')),
          body: content,
        );
      },
    );
  }
}

class _ServiceDetails extends StatelessWidget {
  const _ServiceDetails({required this.service});

  final Service service;

  String _extractClienteNombre() {
    final cliente = service.cliente;
    final nombre = cliente?.nombreCompleto.trim();
    if (nombre == null || nombre.isEmpty) return 'No especificado';
    return nombre;
  }

  String _extractOrigenNombre() {
    final origen = service.origen?.direccion ?? '';
    final text = origen.toString().trim();
    return text.isEmpty ? 'No especificado' : text;
  }

  String _extractDestinoNombre() {
    final destino = service.destino?.direccion ?? '';
    return destino.toString().trim();
  }

  String _extractField(String key, {String fallback = 'No especificado'}) {
    final value = service.raw[key];
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final clienteNombre = _extractClienteNombre();
    final origenNombre = _extractOrigenNombre();
    final destinoNombre = _extractDestinoNombre();
    final descripcion = _extractField('descripcion');
    final indicaciones = _extractField('indicaciones');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Cliente', value: clienteNombre),
                const SizedBox(height: 8),
                _InfoRow(label: 'Origen', value: origenNombre),
                const SizedBox(height: 8),
                _InfoRow(label: 'Descripción', value: descripcion),
                const SizedBox(height: 8),
                _InfoRow(label: 'Indicaciones', value: indicaciones),
                const SizedBox(height: 8),
                if (destinoNombre.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _InfoRow(label: 'Destino', value: destinoNombre),
                  ),
                _InfoRow(label: 'Tipo de servicio', value: service.tipo),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
