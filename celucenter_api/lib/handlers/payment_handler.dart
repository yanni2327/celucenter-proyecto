import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config.dart';
import '../database.dart';
import '../middleware/auth.dart';
import '../models/order.dart';

Router paymentRouter() {
  final router = Router();

  // POST /api/pagos/sesion  →  Crea sesión de pago (requiere auth)
  // En producción: llama a Stripe o MercadoPago y devuelve la URL de redirección.
  router.post('/sesion', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final body    = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ordenId = body['ordenId'] as String? ?? '';

    final order = Database.instance.findOrderById(ordenId);
    if (order == null) return _json({'error': 'Orden no encontrada'}, 404);
    if (order.userId != userId) return _json({'error': 'Sin permiso'}, 403);

    // ── Simulación de sesión de pago ──────────────────────────────────────
    // En producción: llamar a stripe.checkout.sessions.create(...)
    // y devolver session.url
    final redirectUrl =
        'https://checkout.stripe.com/pay/simulado_${order.id}';

    return _json({
      'redirectUrl': redirectUrl,
      'ordenId':     order.id,
      'total':       order.total,
      'message':     'Modo desarrollo: en producción redirigirías a Stripe/MercadoPago',
    });
  });

  // POST /api/pagos/webhook  →  Solo acepta POST desde la pasarela
  // Nginx filtra esta ruta para solo aceptar POST.
  router.post('/webhook', (Request req) async {
    final signature = req.headers['x-stripe-signature'] ??
                      req.headers['x-mercadopago-signature'] ?? '';
    final body      = await req.readAsString();

    // Verificar firma HMAC-SHA256
    if (!_verifyWebhookSignature(body, signature)) {
      return _json({'error': 'Firma inválida'}, 401);
    }

    final payload = jsonDecode(body) as Map<String, dynamic>;
    final event   = payload['type'] as String? ?? '';
    final ordenId = (payload['data']?['object']?['metadata']?['orden_id']
                    ?? payload['data']?['orden_id']) as String? ?? '';

    if (event == 'payment_intent.succeeded' || event == 'payment.approved') {
      Database.instance.updateOrderStatus(ordenId, OrderStatus.pagado);
      print('[Webhook] Pago confirmado para orden $ordenId');
    }

    // Responder 200 inmediatamente (buena práctica con pasarelas)
    return _json({'received': true});
  });

  return router;
}

bool _verifyWebhookSignature(String payload, String signature) {
  if (signature.isEmpty) return false;
  final key      = utf8.encode(AppConfig.webhookSecret);
  final bytes    = utf8.encode(payload);
  final expected = Hmac(sha256, key).convert(bytes).toString();
  return signature == expected || signature.contains(expected);
}

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
