import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/service.dart';
import 'auth.dart';
import '../services/current_service_session.dart';

class OfertasApi {
  final String _baseUrl;

  OfertasApi() : _baseUrl = baseUrl;

  Future<List<Service>> fetchOfertasSolicitadas() async {
    final token = await AuthApi.getAccessToken();
    final url = Uri.parse('$_baseUrl/api/serv/ofertas/');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) return const [];

    final ofertas = Service.listFromPaginatedJson(data);
    return ofertas.where((o) => o.estado == 'solicitado').toList();
  }

  Future<Service> aceptarOferta(int id) async {
    final token = await AuthApi.getAccessToken();
    final url = Uri.parse('$_baseUrl/api/serv/aceptar-servicio/$id/');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({'accion': 'aceptado'}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida al aceptar la oferta');
    }

    final servicioAceptado = Service.fromJson(data);

    // Guardar automáticamente en CurrentServiceSession
    CurrentServiceSession.instance.setService(servicioAceptado);

    return servicioAceptado;
  }
}
