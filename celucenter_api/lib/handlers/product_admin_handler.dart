import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';
import '../models/product.dart';

Router productAdminRouter() {
  final router = Router();

  router.post('/', (Request req) async {
    final body  = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name  = body['name']     as String? ?? '';
    final brand = body['brand']    as String? ?? '';
    final price = body['price']    as int?    ?? 0;
    final cat   = body['category'] as String? ?? '';

    if (name.isEmpty || brand.isEmpty || price <= 0 || cat.isEmpty) {
      return _json({'error': 'Nombre, marca, precio y categoría son requeridos'}, 400);
    }

    final product = Product(
      id:           _uuid(),
      brand:        brand, name: name, price: price,
      originalPrice:body['originalPrice'] as int?,
      emoji:        body['emoji']        as String? ?? '📦',
      category:     cat,
      badge:        body['badge']        as String?,
      badgeIsRed:   body['badgeIsRed']   as bool?  ?? false,
      stock:        body['stock']        as int?   ?? 0,
      description:  body['description']  as String? ?? '',
      specs:        (body['specs'] as Map<String,dynamic>?)
                      ?.map((k,v) => MapEntry(k, v.toString())) ?? {},
      imageUrl:     body['imageUrl'] as String?,
    );

    await Database.instance.addProduct(product);
    return _json(product.toJson(), 201);
  });

  router.put('/<id>', (Request req, String id) async {
    final body    = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final updated = await Database.instance.updateProduct(id, body);
    if (!updated) return _json({'error': 'Producto no encontrado'}, 404);
    final product = await Database.instance.findProductById(id);
    return _json(product!.toJson());
  });

  router.put('/<id>/stock', (Request req, String id) async {
    final body  = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final stock = body['stock'] as int?;
    if (stock == null || stock < 0) {
      return _json({'error': 'Stock inválido'}, 400);
    }
    final updated = await Database.instance.updateProduct(id, {'stock': stock});
    if (!updated) return _json({'error': 'Producto no encontrado'}, 404);
    return _json({'message': 'Stock actualizado', 'stock': stock});
  });

  router.delete('/<id>', (Request req, String id) async {
    await Database.instance.deleteProduct(id);
    return _json({'message': 'Producto eliminado'});
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
  return 'prod_${now}_${(now * 7654321).toRadixString(16).substring(0, 8)}';
}
