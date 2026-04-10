import 'dart:convert';
import 'package:http/http.dart' as http;

/// Excepción especial para token expirado — las páginas la atrapan y redirigen al login.
class TokenExpiradoException implements Exception {}

/// Lanza [TokenExpiradoException] si la respuesta es 401/403, o [Exception] con el mensaje del backend.
void verificarRespuesta(http.Response res, {int esperado = 200}) {
  if (res.statusCode == esperado) return;
  if (res.statusCode == 401 || res.statusCode == 403) throw TokenExpiradoException();
  try {
    final body = jsonDecode(res.body);
    throw Exception(body['detail'] ?? 'Error ${res.statusCode}');
  } catch (_) {
    throw Exception('Error ${res.statusCode}');
  }
}
