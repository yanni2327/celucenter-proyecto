import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';
import '../middleware/auth.dart';
import '../models/order.dart';

Router orderRouter() {
  final router = Router();

  // POST /api/ordenes  →  Crea un pedido (requiere auth)
  router.post('/', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final body  = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final items = (body['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
      final product   = Database.instance.findProductById(productId);
      if (product == null) {
        return _json({'error': 'Producto $productId no encontrado'}, 404);
      }
      final qty = (item['quantity'] as int?) ?? 1;
      if (product.stock < qty) {
        return _json({'error': 'Stock insuficiente para ${product.name}'}, 422);
      }
      orderItems.add(OrderItem(
        productId:    product.id,
        productName:  product.name,
        productEmoji: product.emoji,
        quantity:     qty,
        unitPrice:    product.price,
      ));
    }

    final order = Order(
      id:        _uuid(),
      userId:    userId,
      items:     orderItems,
      name:      name,
      phone:     phone,
      address:   addr,
      city:      city,
      notes:     notes,
      createdAt: DateTime.now(),
    );
    Database.instance.saveOrder(order);

    return _json({'ordenId': order.id, 'order': order.toJson()}, 201);
  });

  // GET /api/ordenes  →  Historial del usuario autenticado
  router.get('/', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final orders = Database.instance.getOrdersByUser(userId);
    return _json({'data': orders.map((o) => o.toJson()).toList()});
  });

  // GET /api/ordenes/:id
  router.get('/<id>', (Request req, String id) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final order = Database.instance.findOrderById(id);
    if (order == null) return _json({'error': 'Orden no encontrada'}, 404);
    if (order.userId != userId) return _json({'error': 'Sin permiso'}, 403);

    return _json(order.toJson());
  });

  return router;
}

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

String _uuid() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return 'ord_${now}_${(now * 9876543).toRadixString(16).substring(0, 8)}';
}

// Ruta solo para admin — GET /api/admin/ordenes/
Router orderAdminRouter() {
  final router = Router();

  router.get('/', (Request req) async {
    final orders = Database.instance.getAllOrders();
    return Response(200,
        body: jsonEncode({'data': orders.map((o) => o.toJson()).toList()}),
        headers: {'Content-Type': 'application/json'});
  });

  router.put('/<id>/estado', (Request req, String id) async {
    final body   = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final status = body['status'] as String? ?? '';
    final orderStatus = OrderStatus.values.where((s) => s.name == status).firstOrNull;
    if (orderStatus == null) {
      return Response(400,
          body: jsonEncode({'error': 'Estado inválido'}),
          headers: {'Content-Type': 'application/json'});
    }
    Database.instance.updateOrderStatus(id, orderStatus);
    return Response(200,
        body: jsonEncode({'message': 'Estado actualizado'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
