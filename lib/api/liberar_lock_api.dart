import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../api/auth.dart';

final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

class LiberarLockApi {
  Future<void> liberarLock(int servicioId) async {
    final url = Uri.parse('$_baseUrl/api/serv/liberar-lock/');
    final headers = await AuthApi.getAuthHeaders();
    final resp = await http
        .post(url, headers: headers)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception('Error al liberar el lock del servicio');
    }
    return body['success'];
  }
}
