import 'package:flutter/material.dart';
import '../models/service.dart';

class ServiceDetailPage extends StatelessWidget {
  final Service service;
  const ServiceDetailPage({super.key, required this.service});

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  String _safe(Map m, String path) {
    try {
      final parts = path.split('.');
      dynamic cur = m;
      for (final p in parts) {
        if (cur == null) return '';
        cur = cur[p];
      }
      return cur?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = service.raw;
    return Scaffold(
      appBar: AppBar(title: Text('Servicio #${service.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Resumen', [
              Text('Estado: ${service.estado}'),
              Text('Fecha solicitud: ${service.fechaSolicitud}'),
              Text('Cliente: ${service.clienteNombre}'),
            ]),
            _section('Origen', [
              Text('Dirección: ${service.origenDireccion}'),
              Text(
                'Lat: ${_safe(raw, 'origen.latitud')}  Lng: ${_safe(raw, 'origen.longitud')}',
              ),
            ]),
            _section('Cliente', [
              Text('nombre: ${_safe(raw, 'cliente.nombre')}'),
              Text('telefono: ${_safe(raw, 'cliente.telefono')}'),
            ]),
            _section('Destino', [
              Text('Dirección: ${service.destinoDireccion}'),
              Text(
                'Lat: ${_safe(raw, 'destino.latitud')}  Lng: ${_safe(raw, 'destino.longitud')}',
              ),
            ]),
            _section('Conductor', [
              Text(
                'Nombre: ${_safe(raw, 'conductor.usuario.first_name')} ${_safe(raw, 'conductor.usuario.last_name')}',
              ),
              Text('Licencia: ${_safe(raw, 'conductor.licencia')}'),
              Text('Role: ${_safe(raw, 'conductor.usuario.role')}'),
            ]),
            _section('Vehículo', [
              Text('unidad: ${_safe(raw, 'vehiculo.unidad')}'),
              Text('placa: ${_safe(raw, 'vehiculo.placa')}'),
              Text(
                'marca: ${_safe(raw, 'vehiculo.marca')} ${_safe(raw, 'vehiculo.modelo')}',
              ),
            ]),
            _section('Observaciones', [Text(_safe(raw, 'observaciones'))]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
