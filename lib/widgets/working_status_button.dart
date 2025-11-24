import 'package:flutter/material.dart';

import 'package:flutter_conductor/models/service.dart';

class WorkingStatusButton extends StatelessWidget {
  const WorkingStatusButton({
    super.key,
    required this.estadoLaboral,
    required this.onToggle,
    this.currentService,
    this.onServiceAction,
  });

  final String estadoLaboral;
  final VoidCallback onToggle;
  final Service? currentService;
  final VoidCallback? onServiceAction;

  @override
  Widget build(BuildContext context) {
    final service = currentService;
    if (service != null &&
        service.estado != 'finalizado' &&
        onServiceAction != null) {
      Color color;
      String label;
      switch (service.estado) {
        case 'en_sitio':
          color = Colors.orange;
          label = 'ABORDO';
          break;
        case 'abordo':
          color = Colors.black;
          label = 'FINALIZAR';
          break;
        default:
          color = Colors.blue;
          label = 'EN SITIO';
          break;
      }

      return FloatingActionButton.large(
        shape: const CircleBorder(),
        heroTag: 'estado_servicio',
        backgroundColor: color,
        onPressed: onServiceAction,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      );
    }

    final bool isDisponible = estadoLaboral.toLowerCase() == 'disponible';
    return FloatingActionButton.large(
      shape: const CircleBorder(),
      backgroundColor: isDisponible ? Colors.green : Colors.red,
      heroTag: 'estado_laboral',
      onPressed: onToggle,
      child: Text(
        (isDisponible ? 'conectado' : 'ocupado').toUpperCase(),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
