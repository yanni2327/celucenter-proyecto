import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

Router productRouter() {
  final router = Router();

  // GET /api/productos?categoria=&q=&orden=
  router.get('/', (Request req) async {
    final params   = req.requestedUri.queryParameters;
    final category = params['categoria'];
    final query    = params['q'];
    final sortBy   = params['orden'];

    final products = Database.instance
        .getProducts(category: category, query: query, sortBy: sortBy);

    return _json({'data': products.map((p) => p.toJson()).toList(),
                  'total': products.length});
  });

  // GET /api/productos/:id
  router.get('/<id>', (Request req, String id) async {
    final product = Database.instance.findProductById(id);
    if (product == null) {
      return _json({'error': 'Producto no encontrado'}, 404);
    }
    return _json(product.toJson());
  });

  return router;
}

Router categoryRouter() {
  final router = Router();

  // GET /api/categorias
  router.get('/', (Request req) async {
    final cats = Database.instance.getCategories();
    return _json({'data': cats});
  });

  return router;
}

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
