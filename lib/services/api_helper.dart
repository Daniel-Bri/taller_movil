import 'dart:convert';
import 'package:http/http.dart' as http;

/// Excepción especial para token expirado — las páginas la atrapan y redirigen al login.
class TokenExpiradoException implements Exception {}

/// Lanza [TokenExpiradoException] si la respuesta es 401/403, o [Exception] con el mensaje del backend.
void verificarRespuesta(http.Response res, {int esperado = 200}) {
  if (res.statusCode == esperado) return;
  if (res.statusCode == 401 || res.statusCode == 403) throw TokenExpiradoException();
  Object? detail;
  try {
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      detail = body['detail'] ?? body['message'] ?? body['msg'];
    } else if (body is String) {
      detail = body;
    }
  } catch (_) {}
  throw Exception(detail?.toString() ?? 'Error ${res.statusCode}');
}
