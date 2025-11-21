import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message.dart';

class ChatWsService {
  final int conductorId;
  final String token;
  final Uri _uri;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  ChatWsService._(this.conductorId, this.token, this._uri);

  factory ChatWsService.forConductor({required int conductorId, required String token}) {
    final base = _resolveBaseWsUrl();
    final uri = Uri.parse('$base/ws/chat/chat_conductor_$conductorId/?token=$token');
    return ChatWsService._(conductorId, token, uri);
  }

  Stream<ChatMessage> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_channel != null) return;
    try {
      _channel = WebSocketChannel.connect(_uri);
      _subscription = _channel!.stream.listen(
        _onData,
        onError: (error) {
          debugPrint('ChatWsService error: $error');
        },
        onDone: () {
          debugPrint('ChatWsService connection closed');
        },
      );
    } catch (e) {
      debugPrint('ChatWsService connect error: $e');
      rethrow;
    }
  }

  void _onData(dynamic data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'];
      if (type == 'chat_init') {
        final messages = decoded['messages'];
        if (messages is List) {
          for (final item in messages) {
            if (item is Map<String, dynamic>) {
              _messageController.add(
                ChatMessage.fromJson(item, conductorId: conductorId),
              );
            }
          }
        }
      } else if (type == 'chat_message') {
        final payload = decoded['message'] ?? decoded;
        if (payload is Map<String, dynamic>) {
          _messageController.add(
            ChatMessage.fromJson(payload, conductorId: conductorId),
          );
        }
      }
    } catch (e) {
      debugPrint('ChatWsService parse error: $e');
    }
  }

  void sendMessage(String content) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({'type': 'chat_message', 'message': content}));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  static String _resolveBaseWsUrl() {
    final wsEnv = dotenv.env['WS_BASE_URL'] ?? dotenv.env['WEBSOCKET_URL'];
    if (wsEnv != null && wsEnv.isNotEmpty) {
      return wsEnv.endsWith('/') ? wsEnv.substring(0, wsEnv.length - 1) : wsEnv;
    }
    final apiBase = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
    if (apiBase.startsWith('https://')) {
      return apiBase.replaceFirst('https://', 'wss://');
    }
    if (apiBase.startsWith('http://')) {
      return apiBase.replaceFirst('http://', 'ws://');
    }
    return 'ws://10.0.2.2:8000';
  }
}
