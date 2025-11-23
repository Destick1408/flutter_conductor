import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth.dart';

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
    return _patchServicio(
      path: '/api/serv/finalizar/$id/',
      accion: 'finalizar',
      lat: lat,
      lng: lng,
    );
  }

  Future<Map<String, dynamic>> _patchServicio({
    required String path,
    required String accion,
    required double lat,
    required double lng,
  }) async {
    final token = await AuthApi.getAccessToken();
    final url = Uri.parse('$_baseUrl$path');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

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
}
