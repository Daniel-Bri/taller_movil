import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EmergenciaService {
  static final _baseUrl = kIsWeb
      ? 'http://localhost:8000/api/emergencias'
      : 'http://10.0.2.2:8000/api/emergencias';

  final _auth = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // CU05 - Reportar emergencia
  Future<Map<String, dynamic>> crearIncidente({
    required int vehiculoId,
    String? descripcion,
    String prioridad = 'media',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/'),          // barra final para evitar redirect 307
      headers: await _authHeaders(),
      body: jsonEncode({
        'vehiculo_id': vehiculoId,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'prioridad': prioridad,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    final detail = res.body.isNotEmpty
        ? (jsonDecode(res.body) as Map<String, dynamic>)['detail']
        : null;
    throw Exception(detail ?? 'Error al reportar emergencia (${res.statusCode})');
  }

  // CU06 - Enviar ubicación GPS
  Future<Map<String, dynamic>> actualizarUbicacion({
    required int incidenteId,
    required double latitud,
    required double longitud,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/$incidenteId/ubicacion'),
      headers: await _authHeaders(),
      body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    final detail = res.body.isNotEmpty
        ? (jsonDecode(res.body) as Map<String, dynamic>)['detail']
        : null;
    throw Exception(detail ?? 'Error al enviar ubicación (${res.statusCode})');
  }

  // Listar incidentes del usuario
  Future<List<Map<String, dynamic>>> listarMisIncidentes() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/mis-incidentes'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar incidentes (${res.statusCode})');
  }
}
