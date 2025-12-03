import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_conductor/api/auth.dart';

class ServiciosApi {
  final String _baseUrl;

  ServiciosApi() : _baseUrl = baseUrl;

  Future<Map<String, dynamic>> marcarEnSitio({
    required int id,
    required double lat,
    required double lng,
  }) {
    return _patchServicio(
      path: '/api/serv/en-sitio/$id/',
      accion: 'en_sitio',
      lat: lat,
      lng: lng,
    );
  }

  Future<Map<String, dynamic>> marcarAbordo({
    required int id,
    required double lat,
    required double lng,
  }) {
    return _patchServicio(
      path: '/api/serv/abordo/$id/',
      accion: 'abordo',
      lat: lat,
      lng: lng,
    );
  }

  Future<Map<String, dynamic>> finalizar({
    required int id,
    required double lat,
    required double lng,
  }) {
    return _finalizarServicio(id: id, lat: lat, lng: lng);
  }

  Future<Map<String, dynamic>> _finalizarServicio({
    required int id,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('$_baseUrl/api/serv/finalizar/$id/');

    final headers = await AuthApi.getAuthHeaders();

    final body = jsonEncode({
      'accion': 'finalizar',
      'latitud': lat,
      'longitud': lng,
    });

    final resp = await http.patch(url, headers: headers, body: body);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
  }

  Future<Map<String, dynamic>> _patchServicio({
    required String path,
    required String accion,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('$_baseUrl$path');

    final headers = await AuthApi.getAuthHeaders();

    final body = jsonEncode({
      'accion': accion,
      'latitud': lat,
      'longitud': lng,
    });

    final resp = await http.patch(url, headers: headers, body: body);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor');
    }

    return data;
  }

  Future<Map<String, dynamic>> servicioTracking({
    required int id,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('$_baseUrl/api/serv/servicio-tracking/');
    final headers = await AuthApi.getAuthHeaders();
    final body = jsonEncode({
      'servicio_id': id,
      'latitud': lat,
      'longitud': lng,
    });

    final resp = await http.post(url, headers: headers, body: body);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor');
    }
    return data;
  }
}
