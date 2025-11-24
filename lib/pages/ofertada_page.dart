import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../api/ofertas_api.dart';
import '../models/service.dart';
import '../services/current_service_session.dart';

class OfertadaPage extends StatefulWidget {
  const OfertadaPage({super.key});

  @override
  State<OfertadaPage> createState() => _OfertadaPageState();
}

class _OfertadaPageState extends State<OfertadaPage> {
  final OfertasApi _api = OfertasApi();
  final List<Service> _ofertas = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  int? _acceptingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      final fetched = await _api.fetchOfertasSolicitadas();
      if (!mounted) return;
      setState(() {
        _ofertas
          ..clear()
          ..addAll(fetched);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al cargar ofertas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOferta(Service oferta) async {
    setState(() => _acceptingId = oferta.id);
    try {
      final accepted = await _api.aceptarOferta(oferta.id);
      debugPrint('Oferta aceptada: ${accepted.id}');
      if (!mounted) return;
      CurrentServiceSession.instance.setService(
        oferta,
      ); // IMPORTANTE, se debe dejar oferta y no el accepted
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo aceptar la oferta: $e')),
      );
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  double _distanceFor(Service oferta) {
    if (_currentPosition == null) return double.infinity;
    final lat = double.tryParse(oferta.origen?.latitud ?? '');
    final lng = double.tryParse(oferta.origen?.longitud ?? '');
    if (lat == null || lng == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters == double.infinity) return 'Distancia no disponible';
    if (distanceMeters >= 1000) {
      final km = (distanceMeters / 1000);
      return '${km.toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Service>.from(_ofertas);
    sorted.sort((a, b) => _distanceFor(a).compareTo(_distanceFor(b)));

    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas de servicios')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : _buildList(sorted),
      ),
    );
  }

  Widget _buildList(List<Service> sorted) {
    if (sorted.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay ofertas disponibles en este momento'),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final oferta = sorted[index];
        final distance = _distanceFor(oferta);
        final distanceText = _formatDistance(distance);
        return ListTile(
          leading: const Icon(Icons.local_offer),
          title: Text(oferta.origen?.direccion ?? 'Origen no disponible'),
          subtitle: Text('Tipo: ${oferta.tipo} • Distancia: $distanceText'),
          trailing: _acceptingId == oferta.id
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _acceptingId == null ? () => _acceptOferta(oferta) : null,
        );
      },
    );
  }
}
