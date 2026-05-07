import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import '../config.dart';
import '../database.dart';

// ── JWT con HMAC-SHA256 ────────────────────────────────────────────────────
String generateToken(String userId) {
  final header  = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final exp     = DateTime.now().add(AppConfig.tokenExpiry)
      .millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(utf8.encode(
      '{"sub":"$userId","exp":$exp,"iat":'
      '${DateTime.now().millisecondsSinceEpoch ~/ 1000}}'));
  final data = '$header.$payload';
  return '$data.${_hmac(data)}';
}

Map<String, dynamic>? verifyToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final data     = '${parts[0]}.${parts[1]}';
    if (_hmac(data) != parts[2]) return null;
    final payload  = jsonDecode(utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])))) as Map<String,dynamic>;
    final exp      = payload['exp'] as int;
    if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) return null;
    return payload;
  } catch (_) { return null; }
}

String _hmac(String data) {
  final key  = utf8.encode(AppConfig.jwtSecret);
  final hmac = Hmac(sha256, key);
  return base64Url.encode(hmac.convert(utf8.encode(data)).bytes);
}

// ── Middleware JWT ─────────────────────────────────────────────────────────
Middleware authMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final auth = request.headers['authorization'] ?? '';
      if (!auth.startsWith('Bearer ')) {
        return Response(401,
            body: jsonEncode({'error': 'Token requerido'}),
            headers: {'Content-Type': 'application/json'});
      }
      final payload = verifyToken(auth.substring(7));
      if (payload == null) {
        return Response(401,
            body: jsonEncode({'error': 'Token inválido o expirado'}),
            headers: {'Content-Type': 'application/json'});
      }
      final userId = payload['sub'] as String;
      final user   = await Database.instance.findUserById(userId);
      if (user == null) {
        return Response(401,
            body: jsonEncode({'error': 'Usuario no encontrado'}),
            headers: {'Content-Type': 'application/json'});
      }
      return inner(request.change(headers: {'X-User-Id': userId}));
    };
  };
}

String? getUserId(Request request) => request.headers['x-user-id'];

String hashPassword(String password) {
  final salt  = AppConfig.jwtSecret.substring(0, 16);
  return sha256.convert(utf8.encode('$salt$password')).toString();
}

bool verifyPassword(String plain, String hash) =>
    hashPassword(plain) == hash;
