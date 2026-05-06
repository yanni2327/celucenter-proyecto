import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final _http  = SecureHttpClient();
  final _auth  = AuthController();

  List<dynamic> _orders   = [];
  bool _loading           = true;
  String _statusFilter    = 'pendiente';

  static const _statuses = [
    ('pendiente',  'Pendientes'),
    ('pagado',     'Pagados'),
    ('preparando', 'Preparando'),
    ('enviado',    'Enviados'),
  ];

  @override
  void initState() {
    super.initState();
    if (!_auth.isLoggedIn || !_auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(AppRoutes.login));
      return;
    }
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final response = await _http.get('/api/admin/ordenes/');
    if (!mounted) return;
    setState(() {
      _orders  = response.isSuccess
          ? (response.data['data'] as List? ?? [])
          : [];
      _loading = false;
    });
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await _http.put('/api/admin/ordenes/$orderId/estado',
        {'status': newStatus});
    _loadOrders();
  }

  List<dynamic> get _filtered => _orders
      .where((o) => (o as Map)['status'] == _statusFilter)
      .toList();

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Bodega — VLAN 30',
                style: AppTextStyles.body(
                    fontSize: 11, weight: FontWeight.w600)),
          ),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.admin),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.lightBorder),
        ),
      ),
      body: Column(children: [
        // Filtros de estado
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final (value, label) = s;
                final count = _orders
                    .where((o) => (o as Map)['status'] == value)
                    .length;
                final selected = _statusFilter == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _statusFilter = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(children: [
                        Text(label,
                            style: AppTextStyles.body(
                              fontSize: 12,
                              color: selected
                                  ? AppColors.white : AppColors.dark,
                              weight: selected
                                  ? FontWeight.w500 : FontWeight.w400,
                            )),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$count',
                                style: AppTextStyles.body(
                                  fontSize: 10,
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.primary,
                                  weight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Lista de órdenes
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : _filtered.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 40, color: AppColors.midGray),
                        const SizedBox(height: 12),
                        Text('No hay órdenes en este estado',
                            style: AppTextStyles.body(
                                fontSize: 14,
                                color: AppColors.midGray)),
                      ],
                    ))
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _OrderTile(
                          order: _filtered[i] as Map<String, dynamic>,
                          onStatusChange: (newStatus) =>
                              _updateStatus(
                                (_filtered[i] as Map)['id'] as String,
                                newStatus),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final ValueChanged<String> onStatusChange;

  const _OrderTile(
      {required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final id      = order['id']            as String? ?? '';
    final name    = order['name']          as String? ?? '';
    final city    = order['city']          as String? ?? '';
    final address = order['address']       as String? ?? '';
    final phone   = order['phone']         as String? ?? '';
    final total   = order['formattedTotal'] as String? ?? '';
    final status  = order['status']        as String? ?? 'pendiente';
    final items   = order['items']         as List?   ?? [];
    final created = order['createdAt']     as String? ?? '';
    final date    = DateTime.tryParse(created);
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2,'0')}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orden #${id.length > 12 ? id.substring(0, 12) : id}...',
                  style: AppTextStyles.body(
                      fontSize: 13, weight: FontWeight.w600)),
              Text(dateStr, style: AppTextStyles.body(
                  fontSize: 11, color: AppColors.midGray)),
            ],
          )),
          Text(total, style: AppTextStyles.productPrice(fontSize: 15)),
        ]),
        const SizedBox(height: 10),

        // Cliente y dirección
        Row(children: [
          const Icon(Icons.person_outline,
              size: 14, color: AppColors.midGray),
          const SizedBox(width: 6),
          Text('$name · $phone',
              style: AppTextStyles.body(
                  fontSize: 12, color: AppColors.midGray)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_outlined,
              size: 14, color: AppColors.midGray),
          const SizedBox(width: 6),
          Expanded(child: Text('$address, $city',
              style: AppTextStyles.body(
                  fontSize: 12, color: AppColors.midGray),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),

        // Items
        Wrap(
          spacing: 8, runSpacing: 6,
          children: items.map((item) {
            final i = item as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${i['productEmoji']} ${i['productName']} x${i['quantity']}',
                style: AppTextStyles.body(fontSize: 12),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Cambiar estado
        Row(children: [
          Text('Cambiar estado:',
              style: AppTextStyles.body(
                  fontSize: 12, weight: FontWeight.w500)),
          const SizedBox(width: 10),
          _nextStatusButton(status, onStatusChange),
        ]),
      ]),
    );
  }

  Widget _nextStatusButton(
      String current, ValueChanged<String> onChange) {
    final Map<String, Map<String, dynamic>> next = {
      'pendiente':  {'label': 'Marcar pagado',    'next': 'pagado',     'color': AppColors.primary},
      'pagado':     {'label': 'Iniciar preparación','next': 'preparando', 'color': const Color(0xFFF57F17)},
      'preparando': {'label': 'Marcar enviado',   'next': 'enviado',    'color': const Color(0xFF1976D2)},
      'enviado':    {'label': 'Confirmar entrega','next': 'entregado',  'color': AppColors.g2},
    };

    final info = next[current];
    if (info == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.g9,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('✓ Entregado',
            style: AppTextStyles.body(
                fontSize: 12, color: AppColors.primary,
                weight: FontWeight.w500)),
      );
    }

    return ElevatedButton(
      onPressed: () => onChange(info['next'] as String),
      style: ElevatedButton.styleFrom(
        backgroundColor: info['color'] as Color,
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(info['label'] as String,
          style: AppTextStyles.body(
              fontSize: 12, color: Colors.white,
              weight: FontWeight.w500)),
    );
  }
}
