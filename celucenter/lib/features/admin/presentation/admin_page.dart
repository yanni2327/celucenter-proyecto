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
  late TabController _tab;

  List<ProductModel>           _products = [];
  List<Map<String, dynamic>>   _orders   = [];
  bool _loadingP = true, _loadingO = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    if (!_auth.isLoggedIn || !_auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(AppRoutes.login));
      return;
    }
    _loadAll();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { _loadingP = true; _loadingO = true; });
    final res = await Future.wait([
      _http.get('/api/productos'),
      _http.get('/api/admin/ordenes/'),
    ]);
    if (!mounted) return;
    setState(() {
      if (res[0].isSuccess) {
        _products = (res[0].data['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _loadingP = false;
      }
      if (res[1].isSuccess) {
        _orders = (res[1].data['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loadingO = false;
      }
    });
  }

  Future<void> _deleteProduct(String id, String name) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Eliminar producto',
            style: AppTextStyles.sectionTitle(fontSize: 16)),
        content: Text('¿Eliminar "$name"?\nEsta acción no se puede deshacer.',
            style: AppTextStyles.body(fontSize: 14, color: AppColors.midGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.discount,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await _http.delete('/api/admin/productos/$id');
    if (mounted && r.isSuccess) { _loadAll(); _showSnack('Producto eliminado'); }
  }

  Future<void> _updateStock(ProductModel p) async {
    final ctrl = TextEditingController(text: p.stock?.toString() ?? '0');
    final val = await showDialog<int>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Actualizar stock',
            style: AppTextStyles.sectionTitle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(p.name, style: AppTextStyles.body(
              fontSize: 13, color: AppColors.midGray)),
          const SizedBox(height: 16),
          TextField(controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Nuevo stock',
                filled: true, counterText: ''),
            autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (val == null) return;
    final r = await _http.put('/api/admin/productos/${p.id}/stock',
        {'stock': val});
    if (mounted && r.isSuccess) { _loadAll(); _showSnack('Stock actualizado'); }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Row(children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: 'Celu',
                style: AppTextStyles.logoText(fontSize: 18)
                    .copyWith(color: AppColors.dark)),
            TextSpan(text: 'Center',
                style: AppTextStyles.logoText(fontSize: 18)
                    .copyWith(color: AppColors.primary)),
          ])),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.g9,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Panel Admin',
                style: AppTextStyles.body(fontSize: 11,
                    color: AppColors.primary, weight: FontWeight.w600)),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.warehouse_outlined, color: AppColors.dark),
            tooltip: 'Bodega',
            onPressed: () => context.go(AppRoutes.warehouse),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.dark),
            tooltip: 'Actualizar',
            onPressed: _loadAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.midGray,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Órdenes'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (_, __) => _tab.index == 1
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
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
        controller: _tab,
        children: [
          _StatsTab(products: _products, orders: _orders,
              loading: _loadingP || _loadingO),
          _ProductsTab(products: _products, loading: _loadingP,
              onEdit: (p) async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProductFormPage(product: p)));
                _loadAll();
              },
              onDelete: (p) => _deleteProduct(p.id, p.name),
              onStock: (p) => _updateStock(p)),
          _OrdersTab(orders: _orders, loading: _loadingO),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Estadísticas
// ─────────────────────────────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final List<ProductModel> products;
  final List<Map<String, dynamic>> orders;
  final bool loading;
  const _StatsTab({required this.products, required this.orders,
      required this.loading});

  int get _ingresos => orders.fold(0, (s, o) =>
      s + ((o['items'] as List? ?? []).fold<int>(0, (ss, i) =>
          ss + ((i as Map)['total'] as int? ?? 0))));

  Map<String, int> get _topProducts {
    final m = <String, int>{};
    for (final o in orders) {
      for (final i in (o['items'] as List? ?? [])) {
        final name = (i as Map)['productName'] as String? ?? '';
        final qty  = i['quantity'] as int? ?? 0;
        m[name] = (m[name] ?? 0) + qty;
      }
    }
    final s = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(s.take(5));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));

    final sinStock  = products.where((p) => (p.stock ?? 0) == 0).length;
    final stockBajo = products
        .where((p) => (p.stock ?? 0) > 0 && (p.stock ?? 0) <= 5).length;
    final statusCount = <String, int>{};
    for (final o in orders) {
      final s = o['status'] as String? ?? 'pendiente';
      statusCount[s] = (statusCount[s] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // KPI cards
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 600 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: c.maxWidth > 600 ? 1.6 : 1.4,
            children: [
              _KpiCard('Productos', '${products.length}',
                  Icons.inventory_2_outlined, AppColors.primary),
              _KpiCard('Órdenes', '${orders.length}',
                  Icons.receipt_long_outlined, const Color(0xFF1976D2)),
              _KpiCard('Sin stock', '$sinStock',
                  Icons.warning_amber_outlined, AppColors.discount),
              _KpiCard('Stock bajo', '$stockBajo',
                  Icons.low_priority, const Color(0xFFF57F17)),
            ],
          );
        }),
        const SizedBox(height: 16),

        // Ingresos banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.g2],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingresos totales',
                    style: AppTextStyles.body(
                        fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(_fmt(_ingresos),
                    style: AppTextStyles.sectionTitle(fontSize: 32)
                        .copyWith(color: Colors.white)),
                Text('${orders.length} órdenes procesadas',
                    style: AppTextStyles.body(
                        fontSize: 12, color: Colors.white70)),
              ],
            )),
            Icon(Icons.trending_up, color: Colors.white.withOpacity(0.6),
                size: 48),
          ]),
        ),
        const SizedBox(height: 16),

        // Dos columnas
        LayoutBuilder(builder: (_, c) {
          if (c.maxWidth < 600) {
            return Column(children: [
              _StatusCard(statusCount: statusCount, total: orders.length),
              const SizedBox(height: 12),
              _TopProducts(top: _topProducts),
            ]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatusCard(
                  statusCount: statusCount, total: orders.length)),
              const SizedBox(width: 12),
              Expanded(child: _TopProducts(top: _topProducts)),
            ],
          );
        }),
      ]),
    );
  }

  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer(r'$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: color, height: 1.1)),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.body(
              fontSize: 11, color: AppColors.midGray)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Map<String, int> statusCount;
  final int total;
  const _StatusCard({required this.statusCount, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Órdenes por estado',
            style: AppTextStyles.sectionTitle(fontSize: 14)),
        const SizedBox(height: 16),
        ...['pendiente','pagado','preparando','enviado','entregado'].map((s) {
          final count = statusCount[s] ?? 0;
          final pct   = total == 0 ? 0.0 : count / total;
          final color = _sc(s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_sl(s), style: AppTextStyles.body(fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$count', style: AppTextStyles.body(
                      fontSize: 11, color: color, weight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct,
                    backgroundColor: AppColors.lightBorder,
                    color: color, minHeight: 6)),
            ]),
          );
        }),
      ]),
    );
  }

  Color _sc(String s) => switch (s) {
    'pagado'     => AppColors.primary,
    'preparando' => const Color(0xFFF57F17),
    'enviado'    => const Color(0xFF1976D2),
    'entregado'  => AppColors.g2,
    _            => AppColors.midGray,
  };
  String _sl(String s) => switch (s) {
    'pendiente'  => 'Pendiente',  'pagado'   => 'Pagado',
    'preparando' => 'Preparando', 'enviado'  => 'Enviado',
    'entregado'  => 'Entregado',  _          => s,
  };
}

class _TopProducts extends StatelessWidget {
  final Map<String, int> top;
  const _TopProducts({required this.top});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Más vendidos',
            style: AppTextStyles.sectionTitle(fontSize: 14)),
        const SizedBox(height: 16),
        if (top.isEmpty)
          Center(child: Column(children: [
            const Icon(Icons.bar_chart, color: AppColors.midGray, size: 32),
            const SizedBox(height: 8),
            Text('Sin datos aún', style: AppTextStyles.body(
                fontSize: 13, color: AppColors.midGray)),
          ]))
        else
          ...top.entries.toList().asMap().entries.map((e) {
            final rank  = e.key + 1;
            final entry = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: rank == 1 ? const Color(0xFFFFF8E1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Text('$rank',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: rank == 1 ? const Color(0xFFF9A825)
                            : AppColors.midGray,
                      ))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(entry.key,
                    style: AppTextStyles.body(fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.g9,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${entry.value} uds',
                      style: AppTextStyles.body(fontSize: 11,
                          color: AppColors.primary,
                          weight: FontWeight.w600)),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Productos
// ─────────────────────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  final List<ProductModel> products;
  final bool loading;
  final void Function(ProductModel) onEdit, onDelete, onStock;

  const _ProductsTab({required this.products, required this.loading,
      required this.onEdit, required this.onDelete, required this.onStock});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    if (products.isEmpty) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 48,
            color: AppColors.midGray),
        const SizedBox(height: 12),
        Text('No hay productos',
            style: AppTextStyles.sectionTitle(fontSize: 16)),
      ],
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductTile(
        product: products[i],
        onEdit:   () => onEdit(products[i]),
        onDelete: () => onDelete(products[i]),
        onStock:  () => onStock(products[i]),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit, onDelete, onStock;
  const _ProductTile({required this.product, required this.onEdit,
      required this.onDelete, required this.onStock});

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [const BoxShadow(color: Color(0x05000000),
            blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(children: [
        // Imagen / emoji
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: product.bgColor,
              borderRadius: BorderRadius.circular(10)),
          child: product.imageUrl != null
              ? ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                        child: Text(product.emoji,
                            style: const TextStyle(fontSize: 22)))))
              : Center(child: Text(product.emoji,
                  style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTextStyles.body(
                fontSize: 13, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${product.brand} · ${product.price}',
                style: AppTextStyles.body(
                    fontSize: 12, color: AppColors.midGray)),
          ],
        )),

        // Stock badge — clickable
        GestureDetector(
          onTap: onStock,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sc.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2_outlined, size: 13, color: sc),
              const SizedBox(width: 4),
              Text('$stock', style: AppTextStyles.body(
                  fontSize: 12, color: sc, weight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 10, color: sc),
            ]),
          ),
        ),
        const SizedBox(width: 6),

        // Acciones
        _ActionBtn(icon: Icons.edit_outlined, color: AppColors.primary,
            onTap: onEdit),
        _ActionBtn(icon: Icons.delete_outline, color: AppColors.discount,
            onTap: onDelete),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: color),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Órdenes
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool loading;
  const _OrdersTab({required this.orders, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    if (orders.isEmpty) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.receipt_long_outlined, size: 48,
            color: AppColors.midGray),
        const SizedBox(height: 12),
        Text('No hay órdenes aún',
            style: AppTextStyles.sectionTitle(fontSize: 16)),
      ],
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderTile(order: orders[i]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final id     = order['id']             as String? ?? '';
    final name   = order['name']           as String? ?? '';
    final city   = order['city']           as String? ?? '';
    final total  = order['formattedTotal'] as String? ?? '';
    final status = order['status']         as String? ?? '';
    final items  = order['items']          as List?   ?? [];
    final sc     = _sc(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [const BoxShadow(color: Color(0x05000000),
            blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            color: sc.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long_outlined, color: sc, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${id.length > 12 ? id.substring(0, 12) : id}...',
                style: AppTextStyles.body(
                    fontSize: 13, weight: FontWeight.w600)),
            Text('$name · $city · ${items.length} items',
                style: AppTextStyles.body(
                    fontSize: 11, color: AppColors.midGray)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(total, style: AppTextStyles.productPrice(fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_sl(status), style: AppTextStyles.body(
                fontSize: 10, color: sc, weight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Color _sc(String s) => switch (s) {
    'pagado'     => AppColors.primary,
    'preparando' => const Color(0xFFF57F17),
    'enviado'    => const Color(0xFF1976D2),
    'entregado'  => AppColors.g2,
    _            => AppColors.midGray,
  };
  String _sl(String s) => switch (s) {
    'pendiente'  => 'Pendiente',  'pagado'   => 'Pagado',
    'preparando' => 'Preparando', 'enviado'  => 'Enviado',
    'entregado'  => 'Entregado',  _          => s,
  };
}
