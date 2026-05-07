import 'dart:io';
import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'models/order.dart';
import 'config.dart';
import 'middleware/auth.dart';

/// Base de datos PostgreSQL (Neon serverless).
/// Conexión configurada via variable de entorno DATABASE_URL.
class Database {
  Database._();
  static final Database instance = Database._();

  PostgreSQLConnection? _conn;

  Future<PostgreSQLConnection> get _db async {
    if (_conn != null && !_conn!.isClosed) return _conn!;
    _conn = await _connect();
    return _conn!;
  }

  Future<PostgreSQLConnection> _connect() async {
    final url = Platform.environment['DATABASE_URL'] ?? AppConfig.databaseUrl;
    final uri = Uri.parse(url);

    final conn = PostgreSQLConnection(
      uri.host,
      uri.port.isNaN || uri.port == 0 ? 5432 : uri.port,
      uri.pathSegments.last,
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').last,
      useSSL:   true,
    );

    await conn.open();
    print('[DB] Conectado a PostgreSQL: ${uri.host}');
    return conn;
  }

  Future<void> init() async {
    final db = await _db;
    await _createTables(db);
    await _seedData(db);
    print('[DB] Base de datos lista');
  }

  Future<void> _createTables(PostgreSQLConnection db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone TEXT,
        is_admin BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        brand TEXT NOT NULL,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        original_price INTEGER,
        emoji TEXT,
        category TEXT NOT NULL,
        badge TEXT,
        badge_is_red BOOLEAN DEFAULT FALSE,
        stock INTEGER DEFAULT 0,
        description TEXT,
        specs JSONB DEFAULT '{}',
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'pendiente',
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        product_emoji TEXT,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedData(PostgreSQLConnection db) async {
    // Admin
    final adminExists = await db.query(
        'SELECT id FROM users WHERE email = @email',
        substitutionValues: {'email': AppConfig.adminEmail});
    if (adminExists.isEmpty) {
      await db.execute('''
        INSERT INTO users (id, name, email, password_hash, is_admin)
        VALUES (@id, @name, @email, @hash, true)
      ''', substitutionValues: {
        'id':   'admin_001',
        'name': AppConfig.adminName,
        'email':AppConfig.adminEmail,
        'hash': hashPassword(AppConfig.adminPassword),
      });
      print('[DB] Admin creado');
    }

    // Productos
    final prodExists = await db.query('SELECT id FROM products LIMIT 1');
    if (prodExists.isNotEmpty) return;

    final products = [
      {'id':'p1','brand':'Samsung','name':'Galaxy S25 Ultra 256GB','price':3899000,
       'original_price':null,'emoji':'📱','category':'Smartphones','badge':'Nuevo',
       'badge_is_red':false,'stock':15,
       'description':'El smartphone más avanzado de Samsung con S Pen integrado.',
       'specs':{'Pantalla':'6.8" AMOLED 120Hz','Procesador':'Snapdragon 8 Elite','RAM':'12 GB','Batería':'5000 mAh'}},
      {'id':'p2','brand':'Apple','name':'MacBook Air M3 13"','price':6499000,
       'original_price':7900000,'emoji':'💻','category':'Computadoras','badge':'-18%',
       'badge_is_red':true,'stock':8,
       'description':'La laptop más delgada de Apple con chip M3.',
       'specs':{'Procesador':'Apple M3','RAM':'8 GB','SSD':'256 GB','Batería':'18 horas'}},
      {'id':'p3','brand':'Sony','name':'WH-1000XM5','price':1249000,
       'original_price':null,'emoji':'🎧','category':'Audio','badge':null,
       'badge_is_red':false,'stock':20,
       'description':'Los mejores audífonos con cancelación de ruido.',
       'specs':{'Tipo':'Over-ear','Batería':'30 horas','Bluetooth':'5.2'}},
      {'id':'p4','brand':'LG','name':'Monitor UltraWide 34" 144Hz','price':2190000,
       'original_price':null,'emoji':'🖥️','category':'Monitores','badge':'Stock bajo',
       'badge_is_red':false,'stock':3,
       'description':'Monitor curvo ultrawide para gaming y productividad.',
       'specs':{'Tamaño':'34"','Resolución':'3440x1440','Hz':'144'}},
      {'id':'p5','brand':'Logitech','name':'MX Master 3S','price':389000,
       'original_price':null,'emoji':'🖱️','category':'Accesorios','badge':null,
       'badge_is_red':false,'stock':30,
       'description':'El mouse más avanzado para profesionales.',
       'specs':{'DPI':'8000','Batería':'70 días','Conexión':'Bluetooth'}},
      {'id':'p6','brand':'Apple','name':'iPhone 16 Pro 128GB','price':5299000,
       'original_price':null,'emoji':'📱','category':'Smartphones','badge':'Nuevo',
       'badge_is_red':false,'stock':12,
       'description':'iPhone con chip A18 Pro y cámara de 48MP.',
       'specs':{'Pantalla':'6.3" 120Hz','Chip':'A18 Pro','RAM':'8 GB'}},
      {'id':'p7','brand':'Xiaomi','name':'Redmi Note 14 Pro 256GB','price':1099000,
       'original_price':1350000,'emoji':'📱','category':'Smartphones','badge':'-19%',
       'badge_is_red':true,'stock':25,
       'description':'El mejor smartphone de gama media con AMOLED 144Hz.',
       'specs':{'Pantalla':'6.67" AMOLED','RAM':'8 GB','Carga':'90W'}},
      {'id':'p8','brand':'Samsung','name':'Galaxy Tab S9 FE 128GB','price':1590000,
       'original_price':null,'emoji':'📟','category':'Accesorios','badge':null,
       'badge_is_red':false,'stock':10,
       'description':'Tablet con S Pen incluido.',
       'specs':{'Pantalla':'10.9"','RAM':'6 GB','Batería':'8000 mAh'}},
    ];

    for (final p in products) {
      await db.execute('''
        INSERT INTO products
        (id,brand,name,price,original_price,emoji,category,badge,
         badge_is_red,stock,description,specs)
        VALUES (@id,@brand,@name,@price,@op,@emoji,@cat,@badge,
                @br,@stock,@desc,@specs)
      ''', substitutionValues: {
        'id':   p['id'], 'brand': p['brand'], 'name': p['name'],
        'price':p['price'], 'op':  p['original_price'],
        'emoji':p['emoji'], 'cat': p['category'], 'badge':p['badge'],
        'br':   p['badge_is_red'], 'stock': p['stock'],
        'desc': p['description'],
        'specs':jsonEncode(p['specs']),
      });
    }
    print('[DB] 8 productos insertados');
  }

  // ── Usuarios ───────────────────────────────────────────────────────────────
  Future<User?> findUserByEmail(String email) async {
    final rows = await (await _db).query(
        'SELECT * FROM users WHERE email = @email',
        substitutionValues: {'email': email});
    return rows.isEmpty ? null : _rowToUser(rows.first.toColumnMap());
  }

  Future<User?> findUserById(String id) async {
    final rows = await (await _db).query(
        'SELECT * FROM users WHERE id = @id',
        substitutionValues: {'id': id});
    return rows.isEmpty ? null : _rowToUser(rows.first.toColumnMap());
  }

  Future<void> saveUser(User user) async {
    await (await _db).execute('''
      INSERT INTO users (id,name,email,password_hash,phone,is_admin,created_at)
      VALUES (@id,@name,@email,@hash,@phone,@admin,@created)
      ON CONFLICT (id) DO UPDATE SET
        name=EXCLUDED.name, phone=EXCLUDED.phone
    ''', substitutionValues: {
      'id':user.id,'name':user.name,'email':user.email,
      'hash':user.passwordHash,'phone':user.phone,
      'admin':user.isAdmin,
      'created':user.createdAt.toIso8601String(),
    });
  }

  Future<bool> emailExists(String email) async {
    final rows = await (await _db).query(
        'SELECT id FROM users WHERE email = @email',
        substitutionValues: {'email': email});
    return rows.isNotEmpty;
  }

  User _rowToUser(Map<String, dynamic> row) => User(
    id:           row['id'] as String,
    name:         row['name'] as String,
    email:        row['email'] as String,
    passwordHash: row['password_hash'] as String,
    phone:        row['phone'] as String?,
    isAdmin:      row['is_admin'] as bool? ?? false,
    createdAt:    (row['created_at'] as DateTime?) ?? DateTime.now(),
  );

  // ── Productos ──────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts({
      String? category, String? query, String? sortBy}) async {
    var sql = 'SELECT * FROM products WHERE 1=1';
    final params = <String, dynamic>{};

    if (category != null && category != 'Todos') {
      sql += ' AND category = @cat';
      params['cat'] = category;
    }
    if (query != null && query.isNotEmpty) {
      sql += ' AND (LOWER(name) LIKE @q OR LOWER(brand) LIKE @q)';
      params['q'] = '%${query.toLowerCase()}%';
    }
    switch (sortBy) {
      case 'precio_asc':  sql += ' ORDER BY price ASC';
      case 'precio_desc': sql += ' ORDER BY price DESC';
      default: sql += ' ORDER BY id';
    }

    final rows = await (await _db).query(sql, substitutionValues: params);
    return rows.map((r) => _rowToProduct(r.toColumnMap())).toList();
  }

  Future<Product?> findProductById(String id) async {
    final rows = await (await _db).query(
        'SELECT * FROM products WHERE id = @id',
        substitutionValues: {'id': id});
    return rows.isEmpty ? null : _rowToProduct(rows.first.toColumnMap());
  }

  Future<void> addProduct(Product product) async {
    await (await _db).execute('''
      INSERT INTO products
      (id,brand,name,price,original_price,emoji,category,badge,
       badge_is_red,stock,description,specs,image_url)
      VALUES (@id,@brand,@name,@price,@op,@emoji,@cat,@badge,
              @br,@stock,@desc,@specs,@img)
    ''', substitutionValues: {
      'id':product.id,'brand':product.brand,'name':product.name,
      'price':product.price,'op':product.originalPrice,
      'emoji':product.emoji,'cat':product.category,
      'badge':product.badge,'br':product.badgeIsRed,
      'stock':product.stock,'desc':product.description,
      'specs':jsonEncode(product.specs),'img':product.imageUrl,
    });
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    final p = await findProductById(id);
    if (p == null) return false;

    await (await _db).execute('''
      UPDATE products SET
        brand=@brand, name=@name, price=@price, original_price=@op,
        emoji=@emoji, category=@cat, badge=@badge, badge_is_red=@br,
        stock=@stock, description=@desc, specs=@specs, image_url=@img
      WHERE id=@id
    ''', substitutionValues: {
      'id':id,
      'brand':  data['brand']        ?? p.brand,
      'name':   data['name']         ?? p.name,
      'price':  data['price']        ?? p.price,
      'op':     data['originalPrice']?? p.originalPrice,
      'emoji':  data['emoji']        ?? p.emoji,
      'cat':    data['category']     ?? p.category,
      'badge':  data['badge']        ?? p.badge,
      'br':     data['badgeIsRed']   ?? p.badgeIsRed,
      'stock':  data['stock']        ?? p.stock,
      'desc':   data['description']  ?? p.description,
      'specs':  data['specs'] != null
          ? jsonEncode((data['specs'] as Map<String,dynamic>)
              .map((k,v) => MapEntry(k, v.toString())))
          : jsonEncode(p.specs),
      'img':    data['imageUrl']     ?? p.imageUrl,
    });
    return true;
  }

  Future<bool> deleteProduct(String id) async {
    await (await _db).execute(
        'DELETE FROM products WHERE id = @id',
        substitutionValues: {'id': id});
    return true;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final rows = await (await _db).query(
        'SELECT category, COUNT(*) as count FROM products GROUP BY category ORDER BY category');
    return rows.map((r) => {
      'name':  r.toColumnMap()['category'] as String,
      'count': int.tryParse(r.toColumnMap()['count'].toString()) ?? 0,
    }).toList();
  }

  Product _rowToProduct(Map<String, dynamic> row) {
    Map<String, String> specs = {};
    try {
      final raw = row['specs'];
      if (raw is Map) {
        specs = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      } else if (raw is String) {
        specs = (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}

    return Product(
      id:            row['id']            as String,
      brand:         row['brand']         as String,
      name:          row['name']          as String,
      price:         row['price']         as int,
      originalPrice: row['original_price'] as int?,
      emoji:         row['emoji']         as String? ?? '📦',
      category:      row['category']      as String,
      badge:         row['badge']         as String?,
      badgeIsRed:    row['badge_is_red']  as bool? ?? false,
      stock:         row['stock']         as int? ?? 0,
      description:   row['description']   as String? ?? '',
      specs:         specs,
      imageUrl:      row['image_url']     as String?,
    );
  }

  // ── Órdenes ────────────────────────────────────────────────────────────────
  Future<void> saveOrder(Order order) async {
    final db = await _db;
    await db.execute('''
      INSERT INTO orders (id,user_id,name,phone,address,city,notes,status,created_at)
      VALUES (@id,@uid,@name,@phone,@addr,@city,@notes,@status,@created)
    ''', substitutionValues: {
      'id':order.id,'uid':order.userId,'name':order.name,
      'phone':order.phone,'addr':order.address,'city':order.city,
      'notes':order.notes,'status':order.status.name,
      'created':order.createdAt.toIso8601String(),
    });

    for (final item in order.items) {
      await db.execute('''
        INSERT INTO order_items
        (order_id,product_id,product_name,product_emoji,quantity,unit_price)
        VALUES (@oid,@pid,@pname,@pemoji,@qty,@price)
      ''', substitutionValues: {
        'oid':order.id,'pid':item.productId,'pname':item.productName,
        'pemoji':item.productEmoji,'qty':item.quantity,
        'price':item.unitPrice,
      });
    }
  }

  Future<List<Order>> getOrdersByUser(String userId) async =>
      _getOrders('WHERE o.user_id = @uid', {'uid': userId});

  Future<List<Order>> getAllOrders() async =>
      _getOrders('', {});

  Future<Order?> findOrderById(String id) async {
    final list = await _getOrders('WHERE o.id = @id', {'id': id});
    return list.isEmpty ? null : list.first;
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await (await _db).execute(
        'UPDATE orders SET status = @status WHERE id = @id',
        substitutionValues: {'status': status.name, 'id': id});
  }

  Future<List<Order>> _getOrders(
      String where, Map<String, dynamic> params) async {
    final rows = await (await _db).query(
        'SELECT * FROM orders o $where ORDER BY o.created_at DESC',
        substitutionValues: params);

    final orders = <Order>[];
    for (final row in rows) {
      final r       = row.toColumnMap();
      final orderId = r['id'] as String;
      final itemRows = await (await _db).query(
          'SELECT * FROM order_items WHERE order_id = @id',
          substitutionValues: {'id': orderId});

      final items = itemRows.map((i) {
        final ir = i.toColumnMap();
        return OrderItem(
          productId:    ir['product_id']    as String,
          productName:  ir['product_name']  as String,
          productEmoji: ir['product_emoji'] as String? ?? '📦',
          quantity:     ir['quantity']      as int,
          unitPrice:    ir['unit_price']    as int,
        );
      }).toList();

      orders.add(Order(
        id:        orderId,
        userId:    r['user_id'] as String,
        name:      r['name']    as String,
        phone:     r['phone']   as String,
        address:   r['address'] as String,
        city:      r['city']    as String,
        notes:     r['notes']   as String?,
        status:    OrderStatus.values.firstWhere(
            (s) => s.name == (r['status'] as String),
            orElse: () => OrderStatus.pendiente),
        createdAt: (r['created_at'] as DateTime?) ?? DateTime.now(),
        items:     items,
      ));
    }
    return orders;
  }
}
