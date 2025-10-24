import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import '../api/auth.dart';

final String _baseWsUrl = dotenv.env['WEBSOCKET_URL'] ?? 'ws://10.0.2.2:8000';

class WebSocketApi {
  static WebSocketChannel? _channel;
  static StreamController<dynamic>? _streamController;

  // Conectar al WebSocket
  static Future<bool> connect(String endpoint) async {
    try {
      final token = await AuthApi.getAccessToken();

      if (token == null) {
        debugPrint('❌ No hay token de autenticación');
        return false;
      }

      final url = Uri.parse('$_baseWsUrl/$endpoint?token=$token');
      debugPrint('🔌 Conectando a: $url');

      _channel = WebSocketChannel.connect(url);
      _streamController = StreamController<dynamic>.broadcast();

      _channel?.stream.listen(
        (event) {
          debugPrint('📩 Mensaje recibido: $event');

          // Manejar ping/pong
          try {
            final data = jsonDecode(event);
            if (data['type'] == 'ping') {
              send({'type': 'pong'});
              debugPrint('🏓 Pong enviado');
              return;
            }
          } catch (_) {}

          _streamController?.add(event);
        },
        onError: (error) {
          debugPrint('⚠️ WebSocket error: $error');
          _streamController?.addError(error);
        },
        onDone: () {
          debugPrint('🔌 WebSocket cerrado');
          _streamController?.close();
          _channel = null;
        },
      );

      debugPrint('✅ Conectado exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error al conectar: $e');
      return false;
    }
  }

  // Desconectar manualmente
  static void disconnect() {
    debugPrint('🛑 Desconectando WebSocket');
    _channel?.sink.close();
    _streamController?.close();
    _channel = null;
    _streamController = null;
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
    send(mensaje);
  }

  // Stream de mensajes
  static Stream<dynamic>? get stream => _streamController?.stream;

  // Verificar si está conectado
  static bool get isConnected => _channel != null;

  // Cerrar (alias de disconnect)
  static void close() => disconnect();
}
