import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class VehiculoService {
  static const _baseUrl = 'http://10.0.2.2:8000/api/acceso';
  final _auth = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── CU03 - Registrar Vehículo ─────────────────────────────
  Future<Map<String, dynamic>> registrarVehiculo({
    required String placa,
    required String marca,
    required String modelo,
    required int anio,
    required String color,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/vehiculos'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'placa': placa,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'color': color,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    final err = jsonDecode(res.body);
    throw Exception(err['detail'] ?? 'Error al registrar vehículo');
  }

  // ── CU04 - Listar Vehículos ───────────────────────────────
  Future<List<Map<String, dynamic>>> listarVehiculos() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/vehiculos'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar vehículos');
  }

  // ── Eliminar Vehículo ────────────────────────────────────
  Future<void> eliminarVehiculo(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/vehiculos/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Error al eliminar vehículo');
    }
  }

  // ── CU12 - Registrar Taller ───────────────────────────────
  Future<Map<String, dynamic>> registrarTaller({
    required String nombre,
    required String direccion,
    String? telefono,
    String? emailComercial,
    double? latitud,
    double? longitud,
  }) async {
    final body = <String, dynamic>{
      'nombre': nombre,
      'direccion': direccion,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      if (emailComercial != null && emailComercial.isNotEmpty) 'email_comercial': emailComercial,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/talleres'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    final err = jsonDecode(res.body);
    throw Exception(err['detail'] ?? 'Error al registrar taller');
  }
}
