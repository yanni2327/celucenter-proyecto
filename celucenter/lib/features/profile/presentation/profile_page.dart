import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _http = SecureHttpClient();
  final _auth = AuthController();

  Map<String, dynamic>? _profile;
  List<dynamic> _orders = [];
  bool _loadingProfile = true;
  bool _loadingOrders  = true;

  @override
  void initState() {
    super.initState();
    if (!_auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(AppRoutes.login));
      return;
    }
    _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _http.get('/api/usuarios/perfil'),
      _http.get('/api/ordenes/'),
    ]);
    if (!mounted) return;

    setState(() {
      if (results[0].isSuccess) {
        _profile        = results[0].data as Map<String, dynamic>;
        _loadingProfile = false;
      }
      if (results[1].isSuccess) {
        _orders        = results[1].data['data'] as List? ?? [];
        _loadingOrders = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(text: TextSpan(children: [
          TextSpan(text: 'Celu',
              style: AppTextStyles.logoText(fontSize: 18)),
          TextSpan(text: 'Center',
              style: AppTextStyles.logoText(fontSize: 18)
                  .copyWith(color: AppColors.primary)),
        ])),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.lightBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Perfil ────────────────────────────────────────────────
              Text('Mi perfil', style: AppTextStyles.sectionTitle()),
              const SizedBox(height: 16),
              _loadingProfile
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : _ProfileCard(profile: _profile ?? {}),
              const SizedBox(height: 32),

              // ── Historial ─────────────────────────────────────────────
              Text('Mis pedidos', style: AppTextStyles.sectionTitle()),
              const SizedBox(height: 16),
              _loadingOrders
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : _orders.isEmpty
                      ? _EmptyOrders()
                      : Column(
                          children: _orders
                              .map((o) => _OrderCard(
                                  order: o as Map<String, dynamic>))
                              .toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de perfil ──────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name  = profile['name']  as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final phone = profile['phone'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.g9,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTextStyles.sectionTitle(fontSize: 24)
                .copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTextStyles.sectionTitle(fontSize: 18)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.email_outlined,
                  size: 14, color: AppColors.midGray),
              const SizedBox(width: 6),
              Text(email, style: AppTextStyles.body(
                  fontSize: 13, color: AppColors.midGray)),
            ]),
            if (phone != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.midGray),
                const SizedBox(width: 6),
                Text(phone, style: AppTextStyles.body(
                    fontSize: 13, color: AppColors.midGray)),
              ]),
            ],
          ],
        )),
        if (profile['isAdmin'] == true)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.g9,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Administrador',
                style: AppTextStyles.body(
                    fontSize: 12, color: AppColors.primary,
                    weight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

// ── Tarjeta de orden ───────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  Color _statusColor(String status) => switch (status) {
    'pagado'     => AppColors.primary,
    'preparando' => const Color(0xFFF57F17),
    'enviado'    => const Color(0xFF1976D2),
    'entregado'  => AppColors.g2,
    _            => AppColors.midGray,
  };

  String _statusLabel(String status) => switch (status) {
    'pendiente'  => 'Pendiente',
    'pagado'     => 'Pagado',
    'preparando' => 'Preparando',
    'enviado'    => 'Enviado',
    'entregado'  => 'Entregado',
    _            => status,
  };

  @override
  Widget build(BuildContext context) {
    final id       = widget.order['id']            as String? ?? '';
    final total    = widget.order['formattedTotal'] as String? ?? '';
    final status   = widget.order['status']        as String? ?? 'pendiente';
    final city     = widget.order['city']          as String? ?? '';
    final address  = widget.order['address']       as String? ?? '';
    final items    = widget.order['items']         as List?   ?? [];
    final created  = widget.order['createdAt']     as String? ?? '';
    final date     = DateTime.tryParse(created);
    final dateStr  = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '—';

    final sc = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(children: [
        // Header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Orden #${id.substring(0, 12)}...',
                    style: AppTextStyles.body(
                        fontSize: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$dateStr · $city',
                    style: AppTextStyles.body(
                        fontSize: 12, color: AppColors.midGray)),
              ]),
              const Spacer(),
              Text(total,
                  style: AppTextStyles.productPrice(fontSize: 16)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusLabel(status),
                    style: AppTextStyles.body(
                        fontSize: 11, color: sc,
                        weight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.midGray,
              ),
            ]),
          ),
        ),

        // Detalle expandible
        if (_expanded) ...[
          Container(height: 1, color: AppColors.lightBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.midGray),
                  const SizedBox(width: 6),
                  Text('$address, $city',
                      style: AppTextStyles.body(
                          fontSize: 12, color: AppColors.midGray)),
                ]),
                const SizedBox(height: 12),
                Text('Productos:',
                    style: AppTextStyles.body(
                        fontSize: 12, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final i = item as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Text(i['productEmoji'] as String? ?? '📦',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                          i['productName'] as String? ?? '',
                          style: AppTextStyles.body(fontSize: 12))),
                      Text('x${i['quantity']}',
                          style: AppTextStyles.body(
                              fontSize: 12,
                              color: AppColors.midGray)),
                      const SizedBox(width: 12),
                      Text(
                        _fmt(i['total'] as int? ?? 0),
                        style: AppTextStyles.body(
                            fontSize: 12,
                            weight: FontWeight.w500),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ],
      ]),
    );
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
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.lightBorder),
    ),
    child: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.receipt_long_outlined,
            size: 40, color: AppColors.midGray),
        const SizedBox(height: 12),
        Text('No tienes pedidos aún',
            style: AppTextStyles.sectionTitle(fontSize: 15)),
        const SizedBox(height: 6),
        Text('Tus órdenes aparecerán aquí',
            style: AppTextStyles.body(
                fontSize: 13, color: AppColors.midGray)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.catalog),
          child: const Text('Ir al catálogo'),
        ),
      ],
    )),
  );
}
