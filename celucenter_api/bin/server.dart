import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/config.dart';
import '../lib/middleware/cors.dart';
import '../lib/middleware/auth.dart';
import '../lib/middleware/admin.dart';
import '../lib/handlers/auth_handler.dart';
import '../lib/handlers/product_handler.dart';
import '../lib/handlers/order_handler.dart';
import '../lib/handlers/payment_handler.dart';
import '../lib/handlers/user_handler.dart';
import '../lib/handlers/email_handler.dart';
import '../lib/handlers/product_admin_handler.dart';
import '../lib/handlers/upload_handler.dart';

void main() async {
  final router = Router();

  // Health checks
  router.get('/health', (_) => Response.ok('OK'));
  router.get('/', (_) => Response.ok('CeluCenter API corriendo'));

  // Públicos
  router.mount('/api/auth/',      authRouter().call);
  router.mount('/api/productos',  productRouter().call);
  router.mount('/api/categorias', categoryRouter().call);
  router.post('/api/pagos/webhook', (Request req) =>
      paymentRouter().call(req.change(path: '/webhook')));

  // Protegidos [JWT]
  router.mount('/api/ordenes/',        _protected(orderRouter().call));
  router.mount('/api/pagos/',          _protected(paymentRouter().call));
  router.mount('/api/usuarios/',       _protected(userRouter().call));
  router.mount('/api/notificaciones/', _protected(emailRouter().call));

  // Admin [JWT + isAdmin]
  router.mount('/api/admin/productos', _admin(productAdminRouter().call));
  router.mount('/api/admin/upload/',   _admin(uploadRouter().call));
  router.mount('/api/admin/ordenes/',  _admin(orderAdminRouter().call));

  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Render inyecta PORT como variable de entorno del sistema operativo
  final port   = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('CeluCenter API corriendo en http://0.0.0.0:$port');
  print('Admin: ${AppConfig.adminEmail} / ${AppConfig.adminPassword}');
  server.autoCompress = true;
}

Handler _protected(Handler inner) =>
    Pipeline().addMiddleware(authMiddleware()).addHandler(inner);

Handler _admin(Handler inner) =>
    Pipeline()
        .addMiddleware(authMiddleware())
        .addMiddleware(adminMiddleware())
        .addHandler(inner);
