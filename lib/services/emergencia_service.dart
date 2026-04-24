import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:taller_movil/core/config/app_config.dart';
import 'auth_service.dart';
import 'api_helper.dart';

MediaType _fotoMediaType(String? mimeType, String filename) {
  if (mimeType != null && mimeType.isNotEmpty) {
    try {
      return MediaType.parse(mimeType);
    } catch (_) {}
  }
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

class EmergenciaService {
  static final _baseUrl = '${AppConfig.baseUrl}/api/emergencias';
  static String get apiOrigin => AppConfig.baseUrl;

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

  /// CU07 – Subir una foto (multipart, campo `file`). Usa bytes para compatibilidad con Flutter Web.
  Future<Map<String, dynamic>> subirFoto({
    required int incidenteId,
    required Uint8List bytes,
    String filename = 'foto.jpg',
    String? mimeType,
  }) async {
    final token = await _auth.getToken();
    final uri = Uri.parse('$_baseUrl/$incidenteId/fotos');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    var fn = filename.trim();
    if (fn.isEmpty) fn = 'foto.jpg';
    final ct = _fotoMediaType(mimeType, fn);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fn,
        contentType: ct,
      ),
    );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw TokenExpiradoException();
    }
    final detail = res.body.isNotEmpty
        ? (jsonDecode(res.body) as Map<String, dynamic>)['detail']
        : null;
    throw Exception(detail ?? 'Error al subir la foto (${res.statusCode})');
  }

  /// CU09 – Actualizar descripción (opcional tras crear el incidente).
  Future<Map<String, dynamic>> actualizarDescripcion({
    required int incidenteId,
    required String descripcion,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/$incidenteId/descripcion'),
      headers: await _authHeaders(),
      body: jsonEncode({'descripcion': descripcion}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw TokenExpiradoException();
    }
    final detail = res.body.isNotEmpty
        ? (jsonDecode(res.body) as Map<String, dynamic>)['detail']
        : null;
    throw Exception(detail ?? 'Error al guardar descripción (${res.statusCode})');
  }

  /// CU10 – Incidente + asignación + URLs de fotos.
  Future<List<Map<String, dynamic>>> listarMisSolicitudes() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/mis-solicitudes'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw TokenExpiradoException();
    }
    throw Exception('Error al cargar solicitudes (${res.statusCode})');
  }
}
