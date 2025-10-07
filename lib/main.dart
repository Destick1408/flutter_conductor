import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';

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

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(
    -2.077552237110873,
    -79.8563168612131,
  ); // Ciudad de guayaquil por defecto
  double _zoom = 16.0;
  LatLng? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa (OpenStreetMap)')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _center,
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
                width: 100,
                height: 100,
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
          // FloatingActionButton(
          //   heroTag: 'zoom_in',
          //   child: const Icon(Icons.zoom_in),
          //   onPressed: () {
          //     setState(() {
          //       _zoom = (_zoom + 1).clamp(1.0, 19.0);
          //       _mapController.move(_mapController.center, _zoom);
          //     });
          //   },
          // ),
          // const SizedBox(height: 8),
          // FloatingActionButton(
          //   heroTag: 'zoom_out',
          //   child: const Icon(Icons.zoom_out),
          //   onPressed: () {
          //     setState(() {
          //       _zoom = (_zoom - 1).clamp(1.0, 19.0);
          //       _mapController.move(_mapController.center, _zoom);
          //     });
          //   },
          // ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'locate_me',
            child: const Icon(Icons.my_location),
            onPressed: () async {
              // Request permission and get location
              LocationPermission permission =
                  await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              if (permission == LocationPermission.deniedForever ||
                  permission == LocationPermission.denied) {
                // Permissions are denied, show a message
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permiso de ubicación denegado'),
                  ),
                );
                return;
              }

              try {
                final pos = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                setState(() {
                  _currentPosition = LatLng(pos.latitude, pos.longitude);
                  _mapController.move(_currentPosition!, _zoom);
                });
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al obtener ubicación: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
