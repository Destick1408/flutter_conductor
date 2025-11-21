import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- añadido
import 'dart:async';

final String _fallbackBaseUrl = 'http://10.0.2.2:8000';

String get baseUrl =>
    dotenv.env['API_BASE_URL'] ?? _fallbackBaseUrl; // fallback para emulador Android

class AuthApi {
  static String? accessToken;
  static int? currentUserId;

  // Hace login, guarda tokens y role. Devuelve true si ok.
  static Future<bool> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login/');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'username': username, 'password': password});

      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final access = data['access'] as String?;
        final refresh = data['refresh'] as String?;
        final role = data['role']?.toString();
        final prefs = await SharedPreferences.getInstance();
        if (access != null) {
          accessToken = access;
          await prefs.setString('access_token', access);
          await _cacheUserIdFromToken(access, prefs);
        }
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
          .timeout(const Duration(seconds: 5));
      print('AuthApi.logout response: ${resp.body}');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('role');
      await prefs.remove('current_user_id');
      accessToken = null;
      currentUserId = null;
    } catch (e) {
      print('AuthApi.logout error: $e');
    } finally {
      // Asegura que los tokens se borren aunque falle la petición
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('role');
      await prefs.remove('current_user_id');
      accessToken = null;
      currentUserId = null;
    }
  }

  // Devuelve headers con Authorization si hay access token guardado
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Acceso directo al token si lo necesitas
  static Future<String?> getAccessToken() async {
    if (accessToken != null) return accessToken;
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
    return accessToken;
  }

  static Future<int?> getCurrentUserId() async {
    if (currentUserId != null) return currentUserId;
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('current_user_id');
    return currentUserId;
  }

  static Future<void> _cacheUserIdFromToken(
      String token, SharedPreferences prefs) async {
    final payload = _decodeJwtPayload(token);
    final rawUserId = payload?['user_id'];
    if (rawUserId is int) {
      currentUserId = rawUserId;
      await prefs.setInt('current_user_id', rawUserId);
    } else if (rawUserId is String) {
      final parsed = int.tryParse(rawUserId);
      if (parsed != null) {
        currentUserId = parsed;
        await prefs.setInt('current_user_id', parsed);
      }
    }
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
