import '../models/user.dart';
import 'package:flutter_conductor/api/auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PerfilApi {
  static Future<User?> fetchUserProfile() async {
    try {
      final url = Uri.parse('$baseUrl/api/perfil/');
      final headers = await AuthApi.getAuthHeaders();
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        return User.fromJson(data);
      } else {
        return null;
      }
    } catch (e, st) {
      print('PerfilApi.fetchUserProfile error: $e\n$st');
      return null;
    }
  }
}
