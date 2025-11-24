import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_conductor/api/auth.dart';
import 'package:flutter_conductor/api/conductor.dart';
import 'package:flutter_conductor/api/servicios_api.dart';
import 'package:flutter_conductor/api/websocket.dart';
import 'package:flutter_conductor/api/perfil.dart';
import 'package:flutter_conductor/models/service.dart';
import 'package:flutter_conductor/models/user.dart';
import 'package:flutter_conductor/services/permission_service.dart';
import 'package:flutter_conductor/services/current_service_session.dart';
import 'package:flutter_conductor/widgets/custom_bottom_nav.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_conductor/widgets/drawer_profile.dart';
import 'package:flutter_conductor/widgets/working_status_button.dart';

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
  // Aumentado el intervalo mínimo para reducir frecuencia de rebuilds
  static const int _minUpdateIntervalMs = 300;
  User? _user;
  bool _isConnected = false;
  String estadoLaboral = 'disponible';
  final _currentServiceSession = CurrentServiceSession.instance;
  final _conductorApi = ConductorApi();
  final _serviciosApi = ServiciosApi();

  // Nuevo: notifier para la posición (evita setState frecuente)
  final ValueNotifier<LatLng?> _positionNotifier = ValueNotifier<LatLng?>(null);

  @override
  void initState() {
    super.initState();
    _initializeApp(); // 🔥 UN SOLO punto de entrada
  }

  // 🔥 NUEVO: Inicializar todo en el orden correcto
  Future<void> _initializeApp() async {
    // 1. Pedir permisos PRIMERO
    final permissionsGranted = await PermissionService.requestAllPermissions();

    if (!permissionsGranted) {
      if (mounted) {
        await PermissionService.showPermissionDeniedDialog(context);
      }
      return;
    }

    // 2. Mostrar estado de permisos
    final status = await PermissionService.checkPermissionsStatus();
    debugPrint('📊 Estado de permisos: $status');

    // 3. Cargar perfil
    await _loadProfile();

    // 3.1 Restaurar servicio activo si existe
    await _restoreActiveService();

    // 4. Conectar WebSocket
    await _connectWebSocket();

    // 5. Iniciar seguimiento de ubicación
    await _startLocationUpdates();

    // 6. Optimización de batería (opcional)
    await PermissionService.requestBatteryOptimization();
  }

  Future<void> _loadProfile() async {
    _user = await PerfilApi.fetchUserProfile();
    debugPrint('Usuario cargado: ${_user?.username}');
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _restoreActiveService() async {
    try {
      final servicio = await _conductorApi.fetchServicioActivo();
      if (servicio == null) return;
      _currentServiceSession.setService(servicio);
      if (!mounted) return;
      setState(() {
        estadoLaboral = 'ocupado';
      });
    } catch (e) {
      debugPrint('No se pudo restaurar el servicio activo: $e');
    }
  }

  // Conectar al WebSocket
  Future<void> _connectWebSocket() async {
    try {
      await WebSocketApi.connect('ws/conductor/');

      // Escuchar mensajes del servidor
      _webSocketSubscription = WebSocketApi.stream?.listen(
        (message) {
          // Aquí puedes procesar mensajes del servidor si es necesario
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isConnected = false);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isConnected = false);
        },
      );

      if (!mounted) return;
      setState(() => _isConnected = true);
      debugPrint('WebSocket conectado exitosamente');
    } catch (e) {
      debugPrint('Error al conectar WebSocket: $e');
      if (!mounted) return;
      setState(() => _isConnected = false);
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      // Ya no necesitas pedir permisos aquí, ya se pidieron en _initializeApp
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

            // Evitar setState: actualizar variables y notifier
            _currentPosition = newLatLng;
            _positionNotifier.value = newLatLng;

            // Mover el mapa directamente; no requiere setState
            try {
              _mapController.move(newLatLng, _zoom);
            } catch (_) {}

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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      final LatLng newLatLng = LatLng(pos.latitude, pos.longitude);

      // No usamos setState para evitar rebuilds innecesarios
      _currentPosition = newLatLng;
      _positionNotifier.value = newLatLng;
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
      // Evitar llamar a getCurrentPosition en dispose; usar última posición conocida
      if (_currentPosition != null && _isConnected) {
        // Construimos un Position rápido con los valores mínimos necesarios
        final pos = Position(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        WebSocketApi.enviarUbicacion(pos);

        // Esperar un momento para que el mensaje se envíe
        await Future.delayed(const Duration(milliseconds: 300));
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

  Future<void> _toggleEstadoLaboral() async {
    final nuevoEstado = estadoLaboral.toLowerCase() == 'disponible'
        ? 'ocupado'
        : 'disponible';
    try {
      final estadoBackend = await ConductorApi.cambiarEstadoLaboral(
        nuevoEstado,
      );
      if (!mounted) return;
      setState(() {
        estadoLaboral = estadoBackend;
      });
      if (!mounted) return;
      debugPrint('Estado laboral cambiado a: $estadoBackend');
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error al cambiar estado laboral: $e');
    }
  }

  Future<void> _onServiceAction(Service service) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      Map<String, dynamic> data;
      String nuevoEstado;

      switch (service.estado) {
        case 'en_sitio':
          data = await _serviciosApi.marcarAbordo(
            id: service.id,
            lat: pos.latitude,
            lng: pos.longitude,
          );
          nuevoEstado = 'abordo';
          break;
        case 'abordo':
          data = await _serviciosApi.finalizar(
            id: service.id,
            lat: pos.latitude,
            lng: pos.longitude,
          );
          if (!mounted) return;
          final valor = data['valor'] as String? ?? '0.00';
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.5,
              child: _buildResumenCobro(service, valor),
            ),
          );
          if (!mounted) return;
          _currentServiceSession.setService(null);
          if (!mounted) return;
          setState(() {
            estadoLaboral = 'disponible';
          });
          return;
        case 'aceptado':
        case 'asignado':
        default:
          data = await _serviciosApi.marcarEnSitio(
            id: service.id,
            lat: pos.latitude,
            lng: pos.longitude,
          );
          nuevoEstado = 'en_sitio';
      }

      final updated = service.copyWith(estado: nuevoEstado, raw: data);
      _currentServiceSession.setService(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar servicio: $e')),
      );
    }
  }

  Widget _buildResumenCobro(Service service, String valor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Valor a cobrar: \$$valor',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CERRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // No await aquí (dispose se ejecuta rápido); _sendDisconnect ya usa la última posición
    _sendDisconnect();
    _positionStream?.cancel();
    _webSocketSubscription?.cancel();
    _positionNotifier.dispose();
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
      drawer: SafeArea(child: DrawerProfile(user: _user)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _center,
              initialZoom: _zoom,
              interactionOptions:
                  const InteractionOptions(), // reemplaza interactiveFlags
              keepAlive: true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_conductor',
              ),

              // Reemplazado MarkerLayer por ValueListenableBuilder para evitar rebuild del Scaffold completo
              ValueListenableBuilder<LatLng?>(
                valueListenable: _positionNotifier,
                builder: (context, pos, _) {
                  final markerPoint = pos ?? _currentPosition ?? _center;
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: markerPoint,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'locate_me',
                  onPressed: _locateOnce,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<Service?>(
        valueListenable: CurrentServiceSession.instance.currentService,
        builder: (context, currentService, _) {
          return WorkingStatusButton(
            estadoLaboral: estadoLaboral,
            onToggle: _toggleEstadoLaboral,
            currentService: currentService,
            onServiceAction: currentService == null ? null : _onServiceAction,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SimpleBottomNav(),
    );
  }
}
