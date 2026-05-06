import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import '../config.dart';
import '../database.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JWT simplificado con HMAC-SHA256
//  En producción usar dart_jsonwebtoken o jose
// ─────────────────────────────────────────────────────────────────────────────
String generateToken(String userId) {
  final header  = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final exp     = DateTime.now().add(AppConfig.tokenExpiry).millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(utf8.encode(
      '{"sub":"$userId","exp":$exp,"iat":${DateTime.now().millisecondsSinceEpoch ~/ 1000}}'));

  final data = '$header.$payload';
  final sig  = _hmac(data);
  return '$data.$sig';
}

Map<String, dynamic>? verifyToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final data     = '${parts[0]}.${parts[1]}';
    final expected = _hmac(data);
    if (expected != parts[2]) return null;

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;

    final exp = payload['exp'] as int;
    if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) return null;

    return payload;
  } catch (_) {
    return null;
  }
}

String _hmac(String data) {
  final key   = utf8.encode(AppConfig.jwtSecret);
  final bytes = utf8.encode(data);
  final hmac  = Hmac(sha256, key);
  return base64Url.encode(hmac.convert(bytes).bytes);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Middleware que verifica el JWT en el header Authorization
// ─────────────────────────────────────────────────────────────────────────────
Middleware authMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final auth = request.headers['authorization'] ?? '';
      if (!auth.startsWith('Bearer ')) {
        return Response(401,
            body: jsonEncode({'error': 'Token requerido'}),
            headers: {'Content-Type': 'application/json'});
      }

      final token   = auth.substring(7);
      final payload = verifyToken(token);
      if (payload == null) {
        return Response(401,
            body: jsonEncode({'error': 'Token inválido o expirado'}),
            headers: {'Content-Type': 'application/json'});
      }

      final userId = payload['sub'] as String;
      final user   = Database.instance.findUserById(userId);
      if (user == null) {
        return Response(401,
            body: jsonEncode({'error': 'Usuario no encontrado'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Pasar userId en un header interno para los handlers
      return inner(request.change(headers: {'X-User-Id': userId}));
    };
  };
}

// Helper para obtener userId en los handlers
String? getUserId(Request request) => request.headers['x-user-id'];

// Hash de contraseña con SHA-256 + salt
String hashPassword(String password) {
  final salt  = AppConfig.jwtSecret.substring(0, 16);
  final bytes = utf8.encode('$salt$password');
  return sha256.convert(bytes).toString();
}

bool verifyPassword(String plain, String hash) =>
    hashPassword(plain) == hash;
