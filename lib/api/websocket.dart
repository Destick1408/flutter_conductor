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

  // Conectar al WebSocket con autenticación
  static Future<WebSocketChannel> connect(String endpoint) async {
    final token = await AuthApi.getAccessToken();

    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    // Construir URL con el token como parámetro de query
    final url = Uri.parse('$_baseWsUrl/$endpoint?token=$token');

    _channel = WebSocketChannel.connect(url);
    _streamController = StreamController<dynamic>.broadcast();

    _channel?.stream.listen(
      (event) {
        debugPrint('WebSocket message received: $event');
        _streamController?.add(event);
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
        _streamController?.addError(error);
      },
      onDone: () {
        debugPrint('WebSocket connection closed');
        _streamController?.close();
        _channel = null;
      },
    );

    return _channel!;
  }

  // Enviar mensaje (convertir a JSON)
  static void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel?.sink.add(jsonEncode(message));
    } else {
      debugPrint('WebSocket no está conectado');
    }
  }

  // Método de instancia corregido a estático
  static void enviarUbicacion(Position position, String estado) {
    final mensaje = {
      'type': 'actualizar_ubicacion',
      'latitud': position.latitude,
      'longitud': position.longitude,
      'estado': estado,
    };
    send(mensaje);
  }

  // Escuchar mensajes desde el StreamController
  static Stream<dynamic>? get stream => _streamController?.stream;

  // Cerrar conexión
  static void close() {
    _channel?.sink.close();
    _streamController?.close();
    _channel = null;
    _streamController = null;
  }

  // Verificar si está conectado
  static bool get isConnected => _channel != null;
}
