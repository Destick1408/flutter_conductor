import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../api/auth.dart';
import '../models/service.dart';

final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

class ConductorApi {
  // obtiene lista paginada y la convierte en List<Service>
  static Future<List<Service>> fetchServices() async {
    final url = Uri.parse('$_baseUrl/api/serv/conductor/');
    final headers = await AuthApi.getAuthHeaders();
    final resp = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return Service.listFromJson(body);
    } else {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }
  }

  static Future<String> cambiarEstadoLaboral(String estado) async {
    final url = Uri.parse('$_baseUrl/api/conductores/cambiar-estado/');
    final headers = await AuthApi.getAuthHeaders();
    final resp = await http
        .patch(url, headers: headers, body: jsonEncode({'estado': estado}))
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['estado'] as String? ?? estado;
    } else {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }
  }
}
