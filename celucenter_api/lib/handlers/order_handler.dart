import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';
import '../middleware/auth.dart';
import '../models/order.dart';

Router orderRouter() {
  final router = Router();

  router.post('/', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final body  = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final items = (body['items'] as List?)?.cast<Map<String,dynamic>>() ?? [];
    final name  = body['name']    as String? ?? '';
    final phone = body['phone']   as String? ?? '';
    final addr  = body['address'] as String? ?? '';
    final city  = body['city']    as String? ?? '';
    final notes = body['notes']   as String?;

    if (items.isEmpty || name.isEmpty || phone.isEmpty ||
        addr.isEmpty   || city.isEmpty) {
      return _json({'error': 'Faltan datos del pedido'}, 400);
    }

    final orderItems = <OrderItem>[];
    for (final item in items) {
      final productId = item['productId'] as String? ?? '';
      final product   = await Database.instance.findProductById(productId);
      if (product == null) {
        return _json({'error': 'Producto $productId no encontrado'}, 404);
      }
      final qty = (item['quantity'] as int?) ?? 1;
      orderItems.add(OrderItem(
        productId: product.id, productName: product.name,
        productEmoji: product.emoji, quantity: qty, unitPrice: product.price,
      ));
    }

    final order = Order(
      id: _uuid(), userId: userId, items: orderItems,
      name: name, phone: phone, address: addr, city: city,
      notes: notes, createdAt: DateTime.now(),
    );
    await Database.instance.saveOrder(order);
    return _json({'ordenId': order.id, 'order': order.toJson()}, 201);
  });

  router.get('/', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);
    final orders = await Database.instance.getOrdersByUser(userId);
    return _json({'data': orders.map((o) => o.toJson()).toList()});
  });

  router.get('/<id>', (Request req, String id) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);
    final order = await Database.instance.findOrderById(id);
    if (order == null) return _json({'error': 'Orden no encontrada'}, 404);
    if (order.userId != userId) return _json({'error': 'Sin permiso'}, 403);
    return _json(order.toJson());
  });

  return router;
}

Router orderAdminRouter() {
  final router = Router();

  router.get('/', (Request req) async {
    final orders = await Database.instance.getAllOrders();
    return _json({'data': orders.map((o) => o.toJson()).toList()});
  });

  router.put('/<id>/estado', (Request req, String id) async {
    final body        = jsonDecode(await req.readAsString()) as Map<String,dynamic>;
    final status      = body['status'] as String? ?? '';
    final orderStatus = OrderStatus.values
        .where((s) => s.name == status).firstOrNull;
    if (orderStatus == null) return _json({'error': 'Estado inválido'}, 400);
    await Database.instance.updateOrderStatus(id, orderStatus);
    return _json({'message': 'Estado actualizado'});
  });

  return router;
}

Response _json(dynamic data, [int status = 200]) => Response(
      status, body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'});

String _uuid() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return 'ord_${now}_${(now * 9876543).toRadixString(16).substring(0, 8)}';
}
