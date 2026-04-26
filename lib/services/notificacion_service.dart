import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'api_helper.dart';

class NotificacionService {
  static final _base = kIsWeb
      ? 'http://localhost:8000/api/comunicacion'
      : 'http://10.0.2.2:8000/api/comunicacion';

  final _auth = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> listarMias() async {
    final res = await http.get(
      Uri.parse('$_base/notificaciones/mias'),
      headers: await _headers(),
    );
    verificarRespuesta(res);
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> marcarLeida(int id) async {
    final res = await http.patch(
      Uri.parse('$_base/notificaciones/$id/leida'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    verificarRespuesta(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
