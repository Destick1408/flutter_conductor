import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart'; // usa baseUrl y AuthApi.getAuthHeaders()

class LocationApi {
  /// Envía la ubicación actual al backend. El backend infiere el conductor desde el token.
  static Future<bool> updateLocation({
    required String lastLatitud,
    required String lastLongitud,
    String estado = 'disponible', // o 'en_servicio' según tu estado
  }) async {
    final url = Uri.parse('$baseUrl/api/ubicacion/actualizar/');
    final headers = await AuthApi.getAuthHeaders();
    final body = jsonEncode({
      'last_latitud': lastLatitud,
      'last_longitud': lastLongitud,
      'estado': estado,
    });

    final resp = await http
        .post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }
}
