import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_conductor/api/auth.dart';
import 'package:flutter_conductor/api/location.dart';
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
  int _lastUpdateMillis = 0;
  static const int _minUpdateIntervalMs = 100;
  User? _user;
  Timer? _locationTimer;
  bool _sending = false;

  bool _stopping = false; // evita nuevos envíos cuando hacemos logout
  bool _loggedOut = false; // true después de logout exitoso

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _loadProfile();
    _startPeriodicSender();
  }

  Future<void> _loadProfile() async {
    _user = await PerfilApi.fetchUserProfile();
    debugPrint('Usuario cargado: ${_user?.username}');
    if (!mounted) return;
    setState(() {});
  }

  void _startPeriodicSender() {
    _locationTimer?.cancel();

    Future<void> trySend() async {
      if (_stopping) return; // no iniciar si estamos deteniendo
      if (!mounted) return;
      if (_currentPosition == null) return;
      if (_sending) return; // ya hay un envío en curso
      _sending = true;
      try {
        final lat = _currentPosition!.latitude.toString();
        final lng = _currentPosition!.longitude.toString();
        final ok = await LocationApi.updateLocation(
          lastLatitud: lat,
          lastLongitud: lng,
          estado: 'disponible',
        );
        if (!ok) debugPrint('Location update failed');
      } catch (e) {
        debugPrint('Error sending location: $e');
      } finally {
        _sending = false;
      }
    }

    // enviar inmediatamente y luego cada 5s
    trySend();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => trySend(),
    );
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

  Future<void> _sendDisconnect() async {
    try {
      final lat = _currentPosition?.latitude.toString() ?? '';
      final lng = _currentPosition?.longitude.toString() ?? '';
      await LocationApi.updateLocation(
        lastLatitud: lat,
        lastLongitud: lng,
        estado: 'desconectado',
      );
    } catch (e) {
      debugPrint('Error sending disconnect: $e');
    }
  }

  Future<void> _onLogoutPressed() async {
    try {
      // evitar nuevos envíos
      _stopping = true;

      // cancelar periodic timer y stream (no perder la espera de un envío en curso)
      _locationTimer?.cancel();
      await _positionStream?.cancel();

      // esperar a que cualquier envío en vuelo termine (timeout por seguridad)
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (_sending && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // enviar desconexión (usa el token todavía hasta este punto)
      await _sendDisconnect();

      // ahora sí limpiar sesión en backend/local y marcar que cerramos
      await AuthApi.logout();
      _loggedOut = true;
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void dispose() {
    // Si ya hicimos logout, no intentamos enviar desconexión otra vez
    if (!_loggedOut) {
      _sendDisconnect(); // fire-and-forget como mejor esfuerzo
    }
    _positionStream?.cancel();
    _locationTimer?.cancel();
    super.dispose();
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
