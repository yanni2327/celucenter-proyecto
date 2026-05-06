import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';
import '../middleware/auth.dart';
import '../models/user.dart';

Router authRouter() {
  final router = Router();

  // POST /api/auth/register
  router.post('/register', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final name     = (body['name']     as String?)?.trim() ?? '';
    final email    = (body['email']    as String?)?.trim().toLowerCase() ?? '';
    final password = (body['password'] as String?) ?? '';
    final phone    = (body['phone']    as String?);

    // Validaciones básicas
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return _json({'error': 'Nombre, email y contraseña son requeridos'}, 400);
    }
    if (password.length < 8) {
      return _json({'error': 'La contraseña debe tener al menos 8 caracteres'}, 400);
    }
    if (Database.instance.emailExists(email)) {
      return _json({'error': 'Ya existe una cuenta con ese correo electrónico'}, 409);
    }

    final user = User(
      id:           _uuid(),
      name:         name,
      email:        email,
      passwordHash: hashPassword(password),
      phone:        phone,
      createdAt:    DateTime.now(),
    );
    Database.instance.saveUser(user);

    final token = generateToken(user.id);
    return _json({'userId': user.id, 'token': token, 'user': user.toJson()}, 201);
  });

  // POST /api/auth/login
  router.post('/login', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final email    = (body['email']    as String?)?.trim().toLowerCase() ?? '';
    final password = (body['password'] as String?) ?? '';

    final user = Database.instance.findUserByEmail(email);

    // Mensaje genérico — no revelar si el usuario existe
    if (user == null || !verifyPassword(password, user.passwordHash)) {
      return _json({'error': 'Usuario o contraseña incorrectos'}, 401);
    }

    final token = generateToken(user.id);
    return _json({'token': token, 'user': user.toJson()});
  });

  return router;
}

// ── Helpers ────────────────────────────────────────────────────────────────
Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

String _uuid() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return 'u_${now}_${(now * 1234567).toRadixString(16).substring(0, 8)}';
}
