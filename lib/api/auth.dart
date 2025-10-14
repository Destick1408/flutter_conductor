import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- añadido
import 'dart:async';

String get baseUrl =>
    dotenv.env['API_BASE_URL'] ??
    'http://10.0.2.2:8000'; // fallback para emulador Android

class AuthApi {
  // Hace login, guarda tokens y role. Devuelve true si ok.
  static Future<bool> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login/');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'username': username, 'password': password});

      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final access = data['access'] as String?;
        final refresh = data['refresh'] as String?;
        final role = data['role']?.toString();
        final prefs = await SharedPreferences.getInstance();
        if (access != null) await prefs.setString('access_token', access);
        if (refresh != null) await prefs.setString('refresh_token', refresh);
        if (role != null) await prefs.setString('role', role);
        return access != null;
      } else {
        return false;
      }
    } catch (e, st) {
      // evita que el error detenga la UI y deja un log para depuración
      print('AuthApi.login error: $e\n$st');
      return false;
    }
  }

  // Borra tokens (logout)
  static Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/logout/');
      final headers = await getAuthHeaders();
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      final resp = await http
          .post(url, headers: headers, body: jsonEncode({'refresh': refresh}))
          .timeout(const Duration(seconds: 10));
      print('AuthApi.logout response: ${resp.body}');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('role');
    } catch (e) {
      print('AuthApi.logout error: $e');
    } finally {
      // Asegura que los tokens se borren aunque falle la petición
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('role');
    }
  }

  // Devuelve headers con Authorization si hay access token guardado
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access_token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }
    return headers;
  }

  // Acceso directo al token si lo necesitas
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
