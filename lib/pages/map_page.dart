import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_conductor/widgets/assigning_service_timer.dart';
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
  StreamSubscription<Position>? _backendPositionStream;
  StreamSubscription<dynamic>? _webSocketSubscription;
  // int _lastUpdateMillis = 0;
  // // Aumentado el intervalo mínimo para reducir frecuencia de rebuilds
  // static const int _minUpdateIntervalMs = 300;
  User? _user;
  String estadoLaboral = 'disponible';
  final _currentServiceSession = CurrentServiceSession.instance;
  final _conductorApi = ConductorApi();
  final _serviciosApi = ServiciosApi();
  bool _isShowingAssigningSheet = false;
  final ServiciosApi serviciosApi = ServiciosApi();

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
      if (servicio == null) {
        _currentServiceSession.setService(null);
        return;
      }
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
        _handleWebSocketMessage,
        onError: (error) {
          if (!mounted) return;
        },
        onDone: () {
          if (!mounted) return;
        },
      );
      debugPrint('WebSocket conectado exitosamente');
    } catch (e) {
      debugPrint('Error al conectar WebSocket: $e');
    }
  }

  // Función para enviar ubicación al backend
  void _enviarUbicacionBackend(Position pos) {
    final currentService = CurrentServiceSession.instance.currentService.value;
    if (currentService != null &&
        (currentService.estado == 'aceptado' ||
            currentService.estado == 'asignado' ||
            currentService.estado == 'en_sitio' ||
            currentService.estado == 'abordo')) {
      try {
        serviciosApi.servicioTracking(
          id: currentService.id,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      } catch (e) {
        debugPrint('Error al enviar ubicación a la API: $e');
      }
    }
  }

  // Actualiza el mapa cada 5m y envía al backend cada 300m
  Future<void> _startLocationUpdates() async {
    try {
      await _positionStream?.cancel();
      await _backendPositionStream?.cancel();

      // 1. Actualiza el mapa cada 5 metros
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5,
            ),
          ).listen((Position pos) {
            if (!mounted) return;
            final LatLng newLatLng = LatLng(pos.latitude, pos.longitude);
            _currentPosition = newLatLng;
            _positionNotifier.value = newLatLng;
            try {
              _mapController.move(newLatLng, _zoom);
            } catch (_) {}
          });

      // 2. Envía al backend cada 300 metros
      _backendPositionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 300,
            ),
          ).listen((Position pos) {
            if (!mounted) return;
            if (WebSocketApi.connectionStatus.value) {
              WebSocketApi.enviarUbicacion(pos);
            }
            _enviarUbicacionBackend(pos);
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
      if (WebSocketApi.connectionStatus.value) {
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
      if (_currentPosition != null && WebSocketApi.connectionStatus.value) {
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
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
    _sendDisconnect();
    _positionStream?.cancel();
    _backendPositionStream?.cancel();
    _webSocketSubscription?.cancel();
    _positionNotifier.dispose();
    WebSocketApi.close();
    super.dispose();
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      dynamic data = message;
      if (message is String) {
        data = jsonDecode(message);
      }

      debugPrint('🔔 WebSocket data: $data');

      if (data is Map<String, dynamic>) {
        final type = data['type'] as String?;
        final accion = data['accion'] as String?;

        if (type == 'servicio_notificacion' &&
            accion == 'servicio_automatico') {
          final servicioData = data['servicio'];
          if (servicioData is Map<String, dynamic>) {
            final service = Service.fromJson(servicioData);
            _showAssigningService(service);
          }
        }
      }
    } catch (e) {
      debugPrint('Error al manejar mensaje WebSocket: $e');
    }
  }

  Future<void> _showAssigningService(Service service) async {
    if (!mounted) return;

    // NUEVO: si ya hay un modal abierto, ignoro la nueva notificación
    if (_isShowingAssigningSheet) {
      debugPrint('⚠️ Ya hay un servicio en pantalla, se ignora ${service.id}');
      return;
    }

    _isShowingAssigningSheet = true; // NUEVO
    try {
      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => AssigningServiceTimer(
          service: service,
          onAccepted: () {
            _currentServiceSession.setService(service);
            if (!mounted) return;
            setState(() {
              estadoLaboral = 'ocupado';
            });
          },
          onCancelled: () {
            // opcional: volver a disponible si quieres
          },
          onTimeout: () {
            // opcional: volver a disponible si quieres
          },
        ),
      );
    } finally {
      _isShowingAssigningSheet = false; // NUEVO
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Ivancar'),
            const SizedBox(width: 8),
            // Indicador de conexión WebSocket reactivo
            ValueListenableBuilder<bool>(
              valueListenable: WebSocketApi.connectionStatus,
              builder: (context, connected, _) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? Colors.green : Colors.red,
                  ),
                );
              },
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
            onServiceAction: currentService != null
                ? () => _onServiceAction(currentService)
                : null,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SimpleBottomNav(),
    );
  }
}
