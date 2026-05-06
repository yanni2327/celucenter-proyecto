import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/product_model.dart';
import 'product_form_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  final _http = SecureHttpClient();
  final _auth = AuthController();
  late TabController _tabCtrl;

  List<ProductModel>     _products = [];
  List<Map<String, dynamic>> _orders = [];
  bool _loadingProducts = true;
  bool _loadingOrders   = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (!_auth.isLoggedIn || !_auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(AppRoutes.login));
      return;
    }
    _loadAll();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _http.get('/api/productos'),
      _http.get('/api/admin/ordenes/'),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0].isSuccess) {
        _products = (results[0].data['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _loadingProducts = false;
      }
      if (results[1].isSuccess) {
        _orders = (results[1].data['data'] as List? ?? [])
            .map((o) => o as Map<String, dynamic>)
            .toList();
        _loadingOrders = false;
      }
    });
  }

  Future<void> _deleteProduct(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.discount),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final r = await _http.delete('/api/admin/productos/$id');
    if (!mounted) return;
    if (r.isSuccess) _loadAll();
  }

  Future<void> _updateStock(ProductModel p) async {
    final ctrl =
        TextEditingController(text: p.stock?.toString() ?? '0');
    final newStock = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Stock: ${p.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Nuevo stock', filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newStock == null) return;
    await _http.put(
        '/api/admin/productos/${p.id}/stock', {'stock': newStock});
    if (mounted) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (!_auth.isLoggedIn || !_auth.isAdmin) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: 'Celu',
                style: AppTextStyles.logoText(fontSize: 18)),
            TextSpan(text: 'Center',
                style: AppTextStyles.logoText(fontSize: 18)
                    .copyWith(color: AppColors.primary)),
          ])),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.g9,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Panel Admin',
                style: AppTextStyles.body(
                    fontSize: 11, color: AppColors.primary,
                    weight: FontWeight.w600)),
          ),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warehouse_outlined),
            tooltip: 'Vista de bodega',
            onPressed: () => context.go(AppRoutes.warehouse),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.midGray,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Estadísticas'),
            Tab(text: 'Productos'),
            Tab(text: 'Órdenes'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => _tabCtrl.index == 1
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ProductFormPage()));
                  _loadAll();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
                backgroundColor: AppColors.primary,
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab 1: Estadísticas ──────────────────────────────────────
          _StatsTab(
              products: _products,
              orders: _orders,
              loadingProducts: _loadingProducts,
              loadingOrders: _loadingOrders),

          // ── Tab 2: Productos ─────────────────────────────────────────
          _loadingProducts
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: _products
                      .map((p) => _ProductRow(
                            product: p,
                            onEdit: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProductFormPage(product: p)));
                              _loadAll();
                            },
                            onDelete: () =>
                                _deleteProduct(p.id, p.name),
                            onUpdateStock: () => _updateStock(p),
                          ))
                      .toList(),
                ),

          // ── Tab 3: Órdenes ───────────────────────────────────────────
          _loadingOrders
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : _orders.isEmpty
                  ? const Center(
                      child: Text('No hay órdenes aún'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _orders.length,
                      itemBuilder: (_, i) =>
                          _OrderRow(order: _orders[i]),
                    ),
        ],
      ),
    );
  }
}

// ── Tab de estadísticas ────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final List<ProductModel> products;
  final List<Map<String, dynamic>> orders;
  final bool loadingProducts, loadingOrders;

  const _StatsTab({
    required this.products, required this.orders,
    required this.loadingProducts, required this.loadingOrders,
  });

  int get totalIngresos => orders.fold(0, (sum, o) {
    final items = o['items'] as List? ?? [];
    return sum + items.fold(0, (s, i) =>
        s + ((i as Map)['total'] as int? ?? 0));
  });

  Map<String, int> get productosMasVendidos {
    final map = <String, int>{};
    for (final o in orders) {
      for (final item in (o['items'] as List? ?? [])) {
        final name = (item as Map)['productName'] as String? ?? '';
        final qty  = item['quantity']             as int?   ?? 0;
        map[name]  = (map[name] ?? 0) + qty;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  String _fmt(int price) {
    final s   = price.toString();
    final buf = StringBuffer(r'$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final sinStock  = products.where((p) => (p.stock ?? 0) == 0).length;
    final stockBajo = products
        .where((p) => (p.stock ?? 0) > 0 && (p.stock ?? 0) <= 5)
        .length;

    final statusCount = <String, int>{};
    for (final o in orders) {
      final s = o['status'] as String? ?? 'pendiente';
      statusCount[s] = (statusCount[s] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // KPIs principales
        LayoutBuilder(builder: (_, constraints) {
          final cols = constraints.maxWidth > 700 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2,
            children: [
              _KpiCard('Productos', '${products.length}',
                  Icons.inventory_2_outlined, AppColors.primary),
              _KpiCard('Órdenes totales', '${orders.length}',
                  Icons.receipt_long_outlined, const Color(0xFF1976D2)),
              _KpiCard('Sin stock', '$sinStock',
                  Icons.warning_amber_outlined, AppColors.discount),
              _KpiCard('Stock bajo', '$stockBajo',
                  Icons.low_priority, const Color(0xFFF57F17)),
            ],
          );
        }),
        const SizedBox(height: 24),

        // Ingresos totales
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.g2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingresos totales',
                  style: AppTextStyles.body(
                      fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 6),
              Text(_fmt(totalIngresos),
                  style: AppTextStyles.sectionTitle(fontSize: 28)
                      .copyWith(color: Colors.white)),
              Text('${orders.length} órdenes procesadas',
                  style: AppTextStyles.body(
                      fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Órdenes por estado
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Órdenes por estado',
                  style: AppTextStyles.sectionTitle(fontSize: 15)),
              const SizedBox(height: 12),
              ...['pendiente','pagado','preparando','enviado','entregado']
                  .map((s) {
                final count = statusCount[s] ?? 0;
                final total = orders.isEmpty ? 1 : orders.length;
                final pct   = count / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_statusLabel(s),
                              style: AppTextStyles.body(
                                  fontSize: 12)),
                          Text('$count',
                              style: AppTextStyles.body(
                                  fontSize: 12,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.lightBorder,
                          color: _statusColor(s),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          )),
          const SizedBox(width: 24),

          // Más vendidos
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Productos más vendidos',
                  style: AppTextStyles.sectionTitle(fontSize: 15)),
              const SizedBox(height: 12),
              if (productosMasVendidos.isEmpty)
                Text('Sin datos de ventas',
                    style: AppTextStyles.body(
                        fontSize: 13, color: AppColors.midGray))
              else
                ...productosMasVendidos.entries.map((e) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(child: Text(e.key,
                            style: AppTextStyles.body(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.g9,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${e.value} uds',
                              style: AppTextStyles.body(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  weight: FontWeight.w600)),
                        ),
                      ]),
                    )),
            ],
          )),
        ]),
      ]),
    );
  }

  String _statusLabel(String s) => switch (s) {
    'pendiente'  => 'Pendiente',
    'pagado'     => 'Pagado',
    'preparando' => 'Preparando',
    'enviado'    => 'Enviado',
    'entregado'  => 'Entregado',
    _            => s,
  };

  Color _statusColor(String s) => switch (s) {
    'pagado'     => AppColors.primary,
    'preparando' => const Color(0xFFF57F17),
    'enviado'    => const Color(0xFF1976D2),
    'entregado'  => AppColors.g2,
    _            => AppColors.midGray,
  };
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.statNumber(fontSize: 20)
              .copyWith(color: color)),
          Text(label, style: AppTextStyles.body(
              fontSize: 11, color: AppColors.midGray)),
        ],
      )),
    ]),
  );
}

// ── Fila de producto ───────────────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit, onDelete, onUpdateStock;
  const _ProductRow({required this.product, required this.onEdit,
      required this.onDelete, required this.onUpdateStock});

  @override
  Widget build(BuildContext context) {
    final stock = product.stock ?? 0;
    final sc    = stock == 0 ? AppColors.discount
        : stock <= 5 ? const Color(0xFFF57F17) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: product.bgColor,
              borderRadius: BorderRadius.circular(8)),
          child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(product.emoji,
                              style: const TextStyle(fontSize: 22)))))
              : Center(child: Text(product.emoji,
                  style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTextStyles.body(
                fontSize: 13, weight: FontWeight.w500)),
            Text('${product.brand} · ${product.price}',
                style: AppTextStyles.body(
                    fontSize: 11, color: AppColors.midGray)),
          ],
        )),
        GestureDetector(
          onTap: onUpdateStock,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sc.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2_outlined, size: 12, color: sc),
              const SizedBox(width: 4),
              Text('$stock',
                  style: AppTextStyles.body(
                      fontSize: 11, color: sc,
                      weight: FontWeight.w600)),
              const SizedBox(width: 3),
              Icon(Icons.edit, size: 10, color: sc),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.primary, tooltip: 'Editar',
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.discount, tooltip: 'Eliminar',
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ── Fila de orden en admin ─────────────────────────────────────────────────
class _OrderRow extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final id     = order['id']            as String? ?? '';
    final name   = order['name']          as String? ?? '';
    final city   = order['city']          as String? ?? '';
    final total  = order['formattedTotal'] as String? ?? '';
    final status = order['status']        as String? ?? '';
    final items  = order['items']         as List?   ?? [];

    final sc = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${id.length > 10 ? id.substring(0, 10) : id}...',
                style: AppTextStyles.body(
                    fontSize: 12, weight: FontWeight.w600)),
            Text('$name · $city · ${items.length} items',
                style: AppTextStyles.body(
                    fontSize: 11, color: AppColors.midGray)),
          ],
        )),
        Text(total, style: AppTextStyles.productPrice(fontSize: 14)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sc.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_statusLabel(status),
              style: AppTextStyles.body(
                  fontSize: 10, color: sc,
                  weight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pagado'     => AppColors.primary,
    'preparando' => const Color(0xFFF57F17),
    'enviado'    => const Color(0xFF1976D2),
    'entregado'  => AppColors.g2,
    _            => AppColors.midGray,
  };

  String _statusLabel(String s) => switch (s) {
    'pendiente'  => 'Pendiente',
    'pagado'     => 'Pagado',
    'preparando' => 'Preparando',
    'enviado'    => 'Enviado',
    'entregado'  => 'Entregado',
    _            => s,
  };
}
