import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/cart_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/product_model.dart';
import '../../home/presentation/widgets/navbar_widget.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<ProductModel> _products = [];
  List<String> _categories    = ['Todos'];
  bool    _loading             = true;
  String  _selectedCat         = 'Todos';
  String  _sortBy              = 'Relevancia';
  String  _searchQuery         = '';

  static const _sortOptions = ['Relevancia', 'Menor precio', 'Mayor precio', 'Más nuevos'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    // Carga paralela de productos y categorías
    final results = await Future.wait([
      SecureHttpClient().get('/api/productos'),
      SecureHttpClient().get('/api/categorias'),
    ]);

    if (!mounted) return;

    final prodRes = results[0];
    final catRes  = results[1];

    final products = prodRes.isSuccess
        ? (prodRes.data['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList()
        : <ProductModel>[];

    final cats = catRes.isSuccess
        ? ['Todos', ...(catRes.data['data'] as List)
            .map((j) => (j as Map<String, dynamic>)['name'] as String)]
        : ['Todos'];

    setState(() {
      _products   = products;
      _categories = cats;
      _loading    = false;
    });
  }

  Future<void> _applyFilters() async {
    setState(() => _loading = true);

    final params = <String, String>{};
    if (_selectedCat != 'Todos') params['categoria'] = _selectedCat;
    if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;
    if (_sortBy == 'Menor precio') params['orden'] = 'precio_asc';
    if (_sortBy == 'Mayor precio') params['orden'] = 'precio_desc';
    if (_sortBy == 'Más nuevos')   params['orden'] = 'nuevo';

    final query    = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '/api/productos${query.isNotEmpty ? '?$query' : ''}';
    final response = await SecureHttpClient().get(endpoint);

    if (!mounted) return;
    if (response.isSuccess) {
      setState(() {
        _products = (response.data['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(pinned: true, delegate: NavBarDelegate()),

          // Cabecera
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.dark,
              padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: Text('Inicio', style: AppTextStyles.body(
                      fontSize: 13, color: AppColors.g6)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/', style: AppTextStyles.body(
                      fontSize: 13, color: AppColors.midGray)),
                ),
                Text('Catálogo', style: AppTextStyles.body(
                    fontSize: 13, color: AppColors.white)),
                const Spacer(),
                Text('${_products.length} productos',
                    style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
              ]),
            ),
          ),

          // Barra de filtros
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              child: Wrap(
                spacing: 10, runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 240, height: 38,
                    child: TextField(
                      onSubmitted: (v) {
                        setState(() => _searchQuery = v);
                        _applyFilters();
                      },
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFFAAAAAA)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true, fillColor: AppColors.white,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  _applyFilters();
                                })
                            : null,
                      ),
                    ),
                  ),

                  ..._categories.map((cat) => _CategoryChip(
                    label: cat,
                    selected: _selectedCat == cat,
                    onTap: () {
                      setState(() => _selectedCat = cat);
                      _applyFilters();
                    },
                  )),

                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      style: AppTextStyles.body(fontSize: 13),
                      items: _sortOptions.map((s) =>
                          DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) {
                        setState(() => _sortBy = v ?? _sortBy);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid de productos
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.primary)))
              : _products.isEmpty
                  ? SliverFillRemaining(child: _EmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 52),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _CatalogProductCard(product: _products[i]),
                          childCount: _products.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          crossAxisSpacing: 16, mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}

// ── Chip de categoría ──────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.lightBorder),
        ),
        child: Text(label, style: AppTextStyles.body(
          fontSize: 12,
          color: selected ? AppColors.white : AppColors.dark,
          weight: selected ? FontWeight.w500 : FontWeight.w400,
        )),
      ),
    );
  }
}

// ── Tarjeta de producto ────────────────────────────────────────────────────
class _CatalogProductCard extends StatefulWidget {
  final ProductModel product;
  const _CatalogProductCard({required this.product});

  @override
  State<_CatalogProductCard> createState() => _CatalogProductCardState();
}

class _CatalogProductCardState extends State<_CatalogProductCard> {
  bool _hovered = false;
  bool _added   = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? AppColors.g6.withOpacity(0.6) : AppColors.lightBorder),
          boxShadow: _hovered
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: widget.product.bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Center(child: Text(widget.product.emoji,
                  style: const TextStyle(fontSize: 44))),
            ),
            if (widget.product.badge != null)
              Positioned(top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.product.badgeIsRed ? AppColors.discount : AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(widget.product.badge!, style: AppTextStyles.badge()),
                )),
          ]),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.product.brand.toUpperCase(), style: AppTextStyles.brandLabel()),
              const SizedBox(height: 3),
              Text(widget.product.name, style: AppTextStyles.productName(),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.product.price, style: AppTextStyles.productPrice(fontSize: 16)),
                  if (widget.product.originalPrice != null)
                    Text(widget.product.originalPrice!, style: AppTextStyles.oldPrice()),
                ]),
                GestureDetector(
                  onTap: () {
                    CartScope.read(context).addItem(widget.product);
                    setState(() => _added = true);
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (mounted) setState(() => _added = false);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _added ? AppColors.primary : AppColors.g9,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _added ? Icons.check : Icons.add_shopping_cart,
                      size: 16,
                      color: _added ? AppColors.white : AppColors.primary,
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(children: [
        const Icon(Icons.search_off, size: 48, color: AppColors.midGray),
        const SizedBox(height: 16),
        Text('No se encontraron productos',
            style: AppTextStyles.sectionTitle(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Intenta con otros términos', style: AppTextStyles.body(
            fontSize: 13, color: AppColors.midGray)),
      ]),
    ));
  }
}
