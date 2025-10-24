import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_conductor/api/auth.dart';
import 'package:flutter_conductor/api/websocket.dart';
import 'package:flutter_conductor/api/perfil.dart';
import 'package:flutter_conductor/models/user.dart';
import 'package:flutter_conductor/widgets/custom_bottom_nav.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_conductor/widgets/drawer_profile.dart';

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
  StreamSubscription<dynamic>? _webSocketSubscription;
  int _lastUpdateMillis = 0;
  static const int _minUpdateIntervalMs = 100;
  User? _user;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _connectWebSocket();
    _startLocationUpdates();
  }

  Future<void> _loadProfile() async {
    _user = await PerfilApi.fetchUserProfile();
    debugPrint('Usuario cargado: ${_user?.username}');
    if (!mounted) return;
    setState(() {});
  }

  // Conectar al WebSocket
  Future<void> _connectWebSocket() async {
    try {
      await WebSocketApi.connect('ws/conductor/');

      // Escuchar mensajes del servidor
      _webSocketSubscription = WebSocketApi.stream?.listen(
        (message) {
          debugPrint('Mensaje del servidor: $message');
          // Aquí puedes procesar mensajes del servidor si es necesario
        },
        onError: (error) {
          debugPrint('Error en WebSocket: $error');
          setState(() => _isConnected = false);
        },
        onDone: () {
          debugPrint('WebSocket desconectado');
          setState(() => _isConnected = false);
        },
      );

      setState(() => _isConnected = true);
      debugPrint('WebSocket conectado exitosamente');
    } catch (e) {
      debugPrint('Error al conectar WebSocket: $e');
      setState(() => _isConnected = false);
    }
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
              distanceFilter: 5, // Enviar cada 5 metros de cambio
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

            // Enviar ubicación por WebSocket en tiempo real
            if (_isConnected) {
              WebSocketApi.enviarUbicacion(pos);
            }
          });
    } catch (e) {
      debugPrint('Error al iniciar actualizaciones de ubicación: $e');
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

      // Enviar ubicación actual por WebSocket
      if (_isConnected) {
        WebSocketApi.enviarUbicacion(pos);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  Future<void> _sendDisconnect() async {
    try {
      if (_currentPosition != null && _isConnected) {
        final pos = await Geolocator.getCurrentPosition();
        WebSocketApi.enviarUbicacion(pos);

        // Esperar un momento para que el mensaje se envíe
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error al enviar desconexión: $e');
    }
  }

  Future<void> _onLogoutPressed() async {
    try {
      // Enviar estado de desconexión
      await _sendDisconnect();

      // Cerrar WebSocket
      WebSocketApi.close();

      // Cerrar sesión
      await AuthApi.logout();
    } catch (e) {
      debugPrint('Error en logout: $e');
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void dispose() {
    _sendDisconnect();
    _positionStream?.cancel();
    _webSocketSubscription?.cancel();
    WebSocketApi.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Ivancar'),
            const SizedBox(width: 8),
            // Indicador de conexión WebSocket
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _onLogoutPressed,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerProfile(user: _user),
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
