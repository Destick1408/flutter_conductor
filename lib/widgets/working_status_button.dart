import 'package:flutter/material.dart';

class WorkingStatusButton extends StatelessWidget {
  const WorkingStatusButton({
    super.key,
    required this.estadoLaboral,
    required this.onToggle,
  });

  final String estadoLaboral;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
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
