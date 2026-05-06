import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';
import '../middleware/auth.dart';
import '../models/user.dart';

Router userRouter() {
  final router = Router();

  // GET /api/usuarios/perfil
  router.get('/perfil', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);
    final user = Database.instance.findUserById(userId);
    if (user == null) return _json({'error': 'Usuario no encontrado'}, 404);
    return _json(user.toJson());
  });

  // PUT /api/usuarios/perfil
  router.put('/perfil', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);
    final user = Database.instance.findUserById(userId);
    if (user == null) return _json({'error': 'Usuario no encontrado'}, 404);

    final body  = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name  = (body['name']  as String?)?.trim() ?? user.name;
    final phone = (body['phone'] as String?) ?? user.phone;

    final updated = User(
      id:           user.id,
      name:         name,
      email:        user.email,
      passwordHash: user.passwordHash,
      phone:        phone,
      isAdmin:      user.isAdmin,
      createdAt:    user.createdAt,
    );
    Database.instance.saveUser(updated);
    return _json(updated.toJson());
  });

  return router;
}

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
