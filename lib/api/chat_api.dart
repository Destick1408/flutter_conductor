import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

class ChatApi {
  final int conductorId;
  final String token;
  final String _baseUrl;

  ChatApi({required this.conductorId, required this.token})
    : _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  Future<List<ChatMessage>> fetchMessages() async {
    final url = Uri.parse('$_baseUrl/api/chat/mis-mensajes/');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    final list = _extractMessageList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ChatMessage.fromJson(e, userId: conductorId))
        .toList();
  }

  Future<ChatMessage> sendMessage(String content) async {
    final url = Uri.parse('$_baseUrl/api/chat/enviar/');
    final body = jsonEncode({
      'text': content, // <- NOMBRE CORRECTO QUE ESPERA EL BACKEND
      // no hace falta enviar conductorId si es Conductor
    });

    final resp = await http.post(url, headers: _headers(), body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    // La vista devuelve el mensaje serializado con ChatMessageSerializer
    if (data is Map<String, dynamic>) {
      return ChatMessage.fromJson(data, userId: conductorId);
    }

    return ChatMessage(
      content: content,
      senderId: conductorId,
      isMine: true,
      createdAt: DateTime.now(),
    );
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _extractMessageList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['results'] is List) return data['results'] as List<dynamic>;
      if (data['messages'] is List) return data['messages'] as List<dynamic>;
    }
    return const [];
  }
}
