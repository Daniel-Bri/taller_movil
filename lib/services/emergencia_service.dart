import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EmergenciaService {
  static const _baseUrl = 'http://10.0.2.2:8000/api/emergencias';
  final _auth = AuthService();

  Future<Map<String, dynamic>> reportar({
    required int vehiculoId,
    String? descripcion,
    String prioridad = 'media',
  }) async {
    final token = await _auth.getToken();
    final res = await http.post(
      Uri.parse('$_baseUrl/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vehiculo_id': vehiculoId,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'prioridad': prioridad,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['detail'] ?? 'Error al reportar emergencia');
  }

  Future<Map<String, dynamic>> enviarUbicacion({
    required int incidenteId,
    required double latitud,
    required double longitud,
  }) async {
    final token = await _auth.getToken();
    final res = await http.patch(
      Uri.parse('$_baseUrl/$incidenteId/ubicacion'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['detail'] ?? 'Error al enviar ubicación');
  }

  Future<List<Map<String, dynamic>>> listarMisIncidentes() async {
    final token = await _auth.getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/mis-incidentes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al obtener incidentes');
  }
}
