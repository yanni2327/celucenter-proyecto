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

  router.post('/sesion', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final body    = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ordenId = body['ordenId'] as String? ?? '';

    final order = await Database.instance.findOrderById(ordenId);
    if (order == null) return _json({'error': 'Orden no encontrada'}, 404);
    if (order.userId != userId) return _json({'error': 'Sin permiso'}, 403);

    final redirectUrl = 'https://checkout.stripe.com/pay/simulado_${order.id}';
    return _json({
      'redirectUrl': redirectUrl,
      'ordenId':     order.id,
      'total':       order.total,
      'message':     'Modo desarrollo',
    });
  });

  router.post('/webhook', (Request req) async {
    final signature = req.headers['x-stripe-signature'] ??
                      req.headers['x-mercadopago-signature'] ?? '';
    final body      = await req.readAsString();

    if (!_verifySignature(body, signature)) {
      return _json({'error': 'Firma inválida'}, 401);
    }

    final payload = jsonDecode(body) as Map<String, dynamic>;
    final event   = payload['type'] as String? ?? '';
    final ordenId = (payload['data']?['orden_id']) as String? ?? '';

    if (event == 'payment_intent.succeeded' || event == 'payment.approved') {
      await Database.instance.updateOrderStatus(ordenId, OrderStatus.pagado);
    }

    return _json({'received': true});
  });

  return router;
}

bool _verifySignature(String payload, String signature) {
  if (signature.isEmpty) return false;
  final key      = utf8.encode(AppConfig.webhookSecret);
  final expected = Hmac(sha256, key).convert(utf8.encode(payload)).toString();
  return signature == expected || signature.contains(expected);
}

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
