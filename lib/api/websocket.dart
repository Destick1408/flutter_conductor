import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import '../api/auth.dart';

final String _baseWsUrl = dotenv.env['WEBSOCKET_URL'] ?? 'ws://10.0.2.2:8000';

class WebSocketApi {
  static WebSocketChannel? _channel;
  static StreamController<dynamic>? _streamController;

  // Notificador de conexión
  static final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(
    false,
  );

  // Reconexión automática
  static bool _manualDisconnect = false;
  static int _reconnectAttempts = 0;
  static Timer? _reconnectTimer;
  static String _lastEndpoint = '';
  static const int _maxReconnectAttempts = 20;

  // Conectar al WebSocket
  static Future<bool> connect(String endpoint) async {
    _lastEndpoint = endpoint;
    _manualDisconnect = false;
    if (_channel != null) {
      debugPrint('⚠️ Ya está conectado al WebSocket');
      connectionStatus.value = true;
      return true;
    }
    try {
      await WakelockPlus.enable();
      debugPrint('🔓 Wakelock activado');
    } catch (e) {
      debugPrint('⚠️ Error al activar wakelock: $e');
    }
    try {
      final token = await AuthApi.getAccessToken();

      if (token == null) {
        debugPrint('❌ No hay token de autenticación');
        return false;
      }
      final url = Uri.parse('$_baseWsUrl/$endpoint?token=$token');
      debugPrint('🔌 Conectando a: $url');
      try {
        _channel = WebSocketChannel.connect(url);
        debugPrint('✅ Conectado exitosamente al websocket');
      } catch (e) {
        debugPrint('❌ Error al conectar: $e');
        return false;
      }

      _streamController = StreamController<dynamic>.broadcast();

      _channel?.stream.listen(
        (event) {
          debugPrint('📩 Mensaje recibido: $event');
          try {
            final data = jsonDecode(event);
            if (data['type'] == 'ping') {
              send({'type': 'pong'});
              debugPrint('🏓 Pong enviado hora: ${DateTime.now()}');
              return;
            }
          } catch (e) {
            debugPrint('⚠️ Error al procesar ping/pong: $e');
          }
          _streamController?.add(event);
        },
        onError: (error) {
          debugPrint('⚠️ WebSocket error: $error');
          _streamController?.addError(error);
          connectionStatus.value = false;
        },
        onDone: () {
          debugPrint('🔌 WebSocket cerrado');
          _streamController?.close();
          _channel = null;
          connectionStatus.value = false;
          _attemptReconnect();
        },
      );

      debugPrint('✅ Conectado exitosamente');
      _reconnectAttempts = 0; // reset al conectar bien
      connectionStatus.value = true;
      return true;
    } catch (e) {
      debugPrint('❌ Error al conectar: $e');
      return false;
    }
  }

  // Reconexión automática
  static void _attemptReconnect() {
    if (_manualDisconnect) {
      debugPrint('ℹ️ Cierre manual: no reconectar');
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Máximos intentos de reconexión alcanzados');
      return;
    }
    _reconnectAttempts++;
    final delayMs = _computeBackoff(_reconnectAttempts);
    debugPrint('🔄 Intento de reconexión #$_reconnectAttempts en ${delayMs}ms');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      final ok = await connect(_lastEndpoint);
      if (ok) {
        debugPrint('✅ Reconectado');
        _reconnectAttempts = 0;
      } else {
        _attemptReconnect();
      }
    });
  }

  static int _computeBackoff(int attempt) {
    final ms = (1000 * (1 << (attempt - 1)));
    return ms > 8000 ? 8000 : ms;
  }

  // Desconectar manualmente (solo se usa al cerrar la app)
  static void disconnect() {
    debugPrint('🛑 Desconectando WebSocket');
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _streamController?.close();
    _channel = null;
    _streamController = null;
    connectionStatus.value = false;
    WakelockPlus.disable()
        .then((_) {
          debugPrint('🔒 Wakelock desactivado');
        })
        .catchError((e) {
          debugPrint('⚠️ Error al desactivar wakelock: $e');
        });
  }

  // Enviar mensaje
  static void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel?.sink.add(jsonEncode(message));
      debugPrint('📤 Mensaje enviado: ${jsonEncode(message)}');
    } else {
      debugPrint('⚠️ WebSocket no está conectado');
    }
  }

  // Enviar ubicación
  static void enviarUbicacion(Position position) {
    final mensaje = {
      'type': 'actualizar_ubicacion',
      'latitud': position.latitude,
      'longitud': position.longitude,
    };
    try {
      send(mensaje);
    } catch (e) {
      debugPrint('❌ Error al enviar ubicación: $e');
    }
  }

  // Stream de mensajes
  static Stream<dynamic>? get stream => _streamController?.stream;

  // Verificar si está conectado
  static bool get isConnected => _channel != null;

  // Cerrar (alias de disconnect)
  static void close() => disconnect();
}
