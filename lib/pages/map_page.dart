import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_conductor/api/auth.dart';
import 'package:flutter_conductor/widgets/custom_bottom_nav.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(-2.077552237110873, -79.8563168612131);
  final double _zoom = 16.0;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  int _lastUpdateMillis = 0;
  static const int _minUpdateIntervalMs = 100;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      await _positionStream?.cancel();
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 1,
            ),
          ).listen((Position pos) {
            if (!mounted) return;

            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastUpdateMillis < _minUpdateIntervalMs) return;
            _lastUpdateMillis = now;

            final LatLng newLatLng = LatLng(pos.latitude, pos.longitude);
            setState(() {
              _currentPosition = newLatLng;
            });
            _mapController.move(newLatLng, _zoom);
          });
    } catch (e) {
      // manejar error si hace falta
    }
  }

  Future<void> _locateOnce() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng newLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = newLatLng;
      });
      _mapController.move(newLatLng, _zoom);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  Future<void> _onLogoutPressed() async {
    try {
      await AuthApi.logout(); // notifica al backend y borra tokens localmente
    } catch (e) {
      // opcional: log o mostrar error
      print('Logout error: $e');
    }
    if (!mounted) return;
    // Lleva al login y limpia la pila para que no se pueda volver atrás
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ivancar'),
        actions: [
          IconButton(
            onPressed: _onLogoutPressed,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _currentPosition ?? _center,
          zoom: _zoom,
          interactiveFlags: InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.flutter_conductor',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentPosition ?? _center,
                width: 48,
                height: 48,
                builder: (ctx) =>
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'locate_me',
            onPressed: _locateOnce,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
      bottomNavigationBar: const SimpleBottomNav(),
    );
  }
}
