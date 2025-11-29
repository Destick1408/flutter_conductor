import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_conductor/models/service.dart';
import 'package:flutter_conductor/api/ofertas_api.dart';
import 'package:flutter_conductor/services/current_service_session.dart';
import 'package:flutter_conductor/api/liberar_lock_api.dart';

class AssigningServiceTimer extends StatefulWidget {
  const AssigningServiceTimer({
    super.key,
    required this.service,
    this.initialSeconds = 15,
    required this.onAccepted,
    required this.onCancelled,
    required this.onTimeout,
  });

  final Service service;
  final int initialSeconds;
  final VoidCallback onAccepted;
  final VoidCallback onCancelled;
  final VoidCallback onTimeout;

  @override
  State<AssigningServiceTimer> createState() => _AssigningServiceTimerState();
}

class _AssigningServiceTimerState extends State<AssigningServiceTimer> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isClosing = false;
  final OfertasApi _api = OfertasApi();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _handleAccept() async {
    if (_isClosing || _remainingSeconds <= 0) return;
    _isClosing = true;
    try {
      await _api.aceptarOferta(widget.service.id);
      CurrentServiceSession.instance.setService(widget.service);
    } catch (e) {
      debugPrint('error al aceptar servicio automatico : $e');
    }
    if (!mounted) return; // Verifica que el widget sigue en pantalla
    widget.onAccepted();
    Navigator.of(context).pop();
  }

  void _handleReject({bool isTimeout = false}) async {
    if (_isClosing) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _isClosing = true;
    try {
      await LiberarLockApi().liberarLock(widget.service.id);
    } catch (e) {
      debugPrint('error al liberar lock del servicio automatico : $e');
    }

    if (!mounted) return;

    if (isTimeout) {
      widget.onTimeout();
    } else {
      widget.onCancelled();
    }
    Navigator.of(context).pop();
  }

  void _handleTimeout() {
    _handleReject(isTimeout: true);
  }

  String _formatTipo(String? tipo) {
    if (tipo == null || tipo.isEmpty) return 'Servicio';
    final normalized = tipo.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Servicio';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final origen = widget.service.origen?.direccion ?? '';
    final destino = widget.service.destino?.direccion ?? '';

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.55,
            widthFactor: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuevo servicio asignado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('$_remainingSeconds s'),
                          backgroundColor: Colors.blue.shade50,
                          labelStyle: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatTipo(widget.service.tipo),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            origen.isEmpty ? 'Origen no disponible' : origen,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (destino.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              destino,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleReject(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _remainingSeconds <= 0
                                ? null
                                : () => _handleAccept(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Aceptar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
