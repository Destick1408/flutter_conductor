import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_conductor/widgets/custom_bottom_nav.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MapApp());
}

class MapApp extends StatelessWidget {
  const MapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa con OpenStreetMap',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  // Controller para manipular la vista del mapa
  final MapController _mapController = MapController();

  // Centro por defecto (Guayaquil)
  final LatLng _center = LatLng(-2.077552237110873, -79.8563168612131);

  double _zoom = 16.0;
  LatLng? _currentPosition; // última posición conocida

  // Stream para actualizaciones continuas de posición
  StreamSubscription<Position>? _positionStream;

  // Si true, la cámara se recentrará automáticamente cuando llegue nueva posición
  bool _followUser = true;

  // Throttling para no redibujar demasiado frecuentemente
  int _lastUpdateMillis = 0;
  static const int _minUpdateIntervalMs = 100; // 10 updates por segundo máximo

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

  // Inicia el stream de ubicación (pide permisos si hace falta)
  Future<void> _startLocationUpdates() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // No hay permiso; el usuario debe habilitarlo en ajustes
        return;
      }

      // Cancelar suscripción previa si existe
      await _positionStream?.cancel();

      // Escuchar actualizaciones del GPS
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy:
                  LocationAccuracy.bestForNavigation, // o LocationAccuracy.best
              distanceFilter: 1, // aprox cada 1 metro
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

            if (_followUser) {
              // Centrar la cámara en la nueva posición
              _mapController.move(newLatLng, _zoom);
            }
          });
    } catch (e) {
      // Opcional: log o mostrar mensaje
    }
  }

  // Obtener la ubicación puntual y centrar (botón 'locate me')
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

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa (OpenStreetMap)'),
        actions: [
          // Toggle para activar/desactivar seguir al usuario
          IconButton(
            icon: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              setState(() {
                _followUser = !_followUser;
              });
            },
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
          // Botón para localizar una vez (centrar en la posición actual)
          FloatingActionButton(
            heroTag: 'locate_me',
            onPressed: _locateOnce,
            child: const Icon(Icons.my_location),
          ),
          // (El toggle de 'seguir usuario' está en el AppBar)
        ],
      ),
      bottomNavigationBar: SimpleBottomNav(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
