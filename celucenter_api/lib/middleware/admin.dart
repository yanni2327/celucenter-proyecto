import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'auth.dart';
import '../database.dart';

/// Middleware que verifica que el usuario sea administrador.
/// Debe usarse DESPUÉS de authMiddleware().
Middleware adminMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final userId = getUserId(request);
      if (userId == null) {
        return Response(401,
            body: jsonEncode({'error': 'No autenticado'}),
            headers: {'Content-Type': 'application/json'});
      }

      final user = Database.instance.findUserById(userId);
      if (user == null || !user.isAdmin) {
        return Response(403,
            body: jsonEncode({'error': 'Acceso denegado. Se requiere rol de administrador.'}),
            headers: {'Content-Type': 'application/json'});
      }

      return inner(request);
    };
  };
}
