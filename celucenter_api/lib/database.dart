import 'models/product.dart';
import 'models/user.dart';
import 'models/order.dart';
import 'config.dart';
import 'middleware/auth.dart';

class Database {
  Database._();
  static final Database instance = Database._();

  // ── Usuarios ───────────────────────────────────────────────────────────────
  final Map<String, User> _users = {};

  void _seedAdmin() {
    if (_users.values.any((u) => u.isAdmin)) return;
    final admin = User(
      id:           'admin_001',
      name:         AppConfig.adminName,
      email:        AppConfig.adminEmail,
      passwordHash: hashPassword(AppConfig.adminPassword),
      isAdmin:      true,
      createdAt:    DateTime.now(),
    );
    _users[admin.id] = admin;
  }

  User? findUserByEmail(String email) {
    _seedAdmin();
    return _users.values.where((u) => u.email == email).firstOrNull;
  }

  User? findUserById(String id) {
    _seedAdmin();
    return _users[id];
  }

  void saveUser(User user) => _users[user.id] = user;

  bool emailExists(String email) {
    _seedAdmin();
    return _users.values.any((u) => u.email == email);
  }

  // ── Productos ──────────────────────────────────────────────────────────────
  final List<Product> _products = [
    Product(id: 'p1', brand: 'Samsung', name: 'Galaxy S25 Ultra 256GB',
        price: 3899000, emoji: '📱', category: 'Smartphones',
        badge: 'Nuevo', stock: 15,
        description: 'El smartphone más avanzado de Samsung con S Pen integrado.',
        specs: {'Pantalla': '6.8" AMOLED 120Hz', 'Procesador': 'Snapdragon 8 Elite',
                'RAM': '12 GB', 'Almacenamiento': '256 GB', 'Batería': '5000 mAh'}),
    Product(id: 'p2', brand: 'Apple', name: 'MacBook Air M3 13" 8GB RAM',
        price: 6499000, originalPrice: 7900000, emoji: '💻',
        category: 'Computadoras', badge: '-18%', badgeIsRed: true, stock: 8,
        description: 'La laptop más delgada de Apple con chip M3.',
        specs: {'Procesador': 'Apple M3', 'RAM': '8 GB', 'SSD': '256 GB',
                'Pantalla': '13.6" Retina', 'Batería': '18 horas'}),
    Product(id: 'p3', brand: 'Sony', name: 'WH-1000XM5 Noise Cancelling',
        price: 1249000, emoji: '🎧', category: 'Audio', stock: 20,
        description: 'Los mejores audífonos con cancelación de ruido.',
        specs: {'Tipo': 'Over-ear', 'Batería': '30 horas', 'Bluetooth': '5.2'}),
    Product(id: 'p4', brand: 'LG', name: 'Monitor UltraWide 34" 144Hz',
        price: 2190000, emoji: '🖥️', category: 'Monitores',
        badge: 'Stock bajo', stock: 3,
        description: 'Monitor curvo ultrawide para gaming y productividad.',
        specs: {'Tamaño': '34"', 'Resolución': '3440x1440', 'Hz': '144'}),
    Product(id: 'p5', brand: 'Logitech', name: 'MX Master 3S',
        price: 389000, emoji: '🖱️', category: 'Accesorios', stock: 30,
        description: 'El mouse más avanzado para profesionales.',
        specs: {'DPI': '8000', 'Batería': '70 días', 'Conexión': 'Bluetooth'}),
    Product(id: 'p6', brand: 'Apple', name: 'iPhone 16 Pro 128GB',
        price: 5299000, emoji: '📱', category: 'Smartphones',
        badge: 'Nuevo', stock: 12,
        description: 'iPhone con chip A18 Pro y cámara de 48MP.',
        specs: {'Pantalla': '6.3" 120Hz', 'Chip': 'A18 Pro', 'RAM': '8 GB'}),
    Product(id: 'p7', brand: 'Xiaomi', name: 'Redmi Note 14 Pro 256GB',
        price: 1099000, originalPrice: 1350000, emoji: '📱',
        category: 'Smartphones', badge: '-19%', badgeIsRed: true, stock: 25,
        description: 'El mejor smartphone de gama media con AMOLED 144Hz.',
        specs: {'Pantalla': '6.67" AMOLED', 'RAM': '8 GB', 'Carga': '90W'}),
    Product(id: 'p8', brand: 'Samsung', name: 'Galaxy Tab S9 FE 128GB',
        price: 1590000, emoji: '📟', category: 'Accesorios', stock: 10,
        description: 'Tablet con S Pen incluido.',
        specs: {'Pantalla': '10.9"', 'RAM': '6 GB', 'Batería': '8000 mAh'}),
  ];

  List<Product> getProducts({String? category, String? query, String? sortBy}) {
    var list = List<Product>.from(_products);
    if (category != null && category != 'Todos') {
      list = list.where((p) => p.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q)).toList();
    }
    switch (sortBy) {
      case 'precio_asc':  list.sort((a, b) => a.price.compareTo(b.price));
      case 'precio_desc': list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  Product? findProductById(String id) =>
      _products.where((p) => p.id == id).firstOrNull;

  void addProduct(Product product) => _products.add(product);

  bool updateProduct(String id, Map<String, dynamic> data) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx < 0) return false;
    final p = _products[idx];
    _products[idx] = Product(
      id:            p.id,
      brand:         data['brand']       as String? ?? p.brand,
      name:          data['name']        as String? ?? p.name,
      price:         data['price']       as int?    ?? p.price,
      originalPrice: data['originalPrice'] as int?  ?? p.originalPrice,
      emoji:         data['emoji']       as String? ?? p.emoji,
      category:      data['category']   as String? ?? p.category,
      badge:         data['badge']       as String? ?? p.badge,
      badgeIsRed:    data['badgeIsRed']  as bool?   ?? p.badgeIsRed,
      stock:         data['stock']       as int?    ?? p.stock,
      description:   data['description'] as String? ?? p.description,
      specs:         (data['specs'] as Map<String, dynamic>?)
                        ?.map((k, v) => MapEntry(k, v.toString()))
                     ?? p.specs,
      imageUrl:      data['imageUrl']   as String? ?? p.imageUrl,
    );
    return true;
  }

  bool deleteProduct(String id) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx < 0) return false;
    _products.removeAt(idx);
    return true;
  }

  List<Map<String, dynamic>> getCategories() {
    final cats = <String, int>{};
    for (final p in _products) {
      cats[p.category] = (cats[p.category] ?? 0) + 1;
    }
    return cats.entries
        .map((e) => {'name': e.key, 'count': e.value})
        .toList();
  }

  // ── Órdenes ────────────────────────────────────────────────────────────────
  final List<Order> _orders = [];

  void saveOrder(Order order) => _orders.add(order);

  List<Order> getOrdersByUser(String userId) =>
      _orders.where((o) => o.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Order> getAllOrders() =>
      List<Order>.from(_orders)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Order? findOrderById(String id) =>
      _orders.where((o) => o.id == id).firstOrNull;

  void updateOrderStatus(String id, OrderStatus status) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx < 0) return;
    final o = _orders[idx];
    _orders[idx] = Order(
      id: o.id, userId: o.userId, items: o.items,
      name: o.name, phone: o.phone, address: o.address,
      city: o.city, notes: o.notes, status: status,
      createdAt: o.createdAt,
    );
  }
}
