import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/cart_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/product_model.dart';
import '../../home/presentation/widgets/navbar_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _http = SecureHttpClient();

  ProductModel? _product;
  bool _loading  = true;
  int  _quantity = 1;
  bool _added    = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final response =
        await _http.get('/api/productos/${widget.productId}');
    if (!mounted) return;
    if (response.isSuccess) {
      setState(() {
        _product = ProductModel.fromJson(
            response.data as Map<String, dynamic>);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _addToCart() {
    if (_product == null) return;
    final cart = CartScope.read(context);
    for (var i = 0; i < _quantity; i++) {
      cart.addItem(_product!);
    }
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 1500),
        () { if (mounted) setState(() => _added = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          SliverPersistentHeader(
              pinned: true, delegate: NavBarDelegate()),
          SliverToBoxAdapter(
            child: _loading
                ? const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator(
                        color: AppColors.primary)))
                : _product == null
                    ? _NotFound()
                    : _ProductBody(
                        product:  _product!,
                        quantity: _quantity,
                        added:    _added,
                        onQuantityChanged: (q) =>
                            setState(() => _quantity = q),
                        onAddToCart: _addToCart,
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Cuerpo del detalle ─────────────────────────────────────────────────────
class _ProductBody extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final bool added;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const _ProductBody({
    required this.product,
    required this.quantity,
    required this.added,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Breadcrumb
        Row(children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Text('Inicio', style: AppTextStyles.body(
                fontSize: 12, color: AppColors.primary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('/', style: TextStyle(color: AppColors.midGray)),
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.catalog),
            child: Text('Catálogo', style: AppTextStyles.body(
                fontSize: 12, color: AppColors.primary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('/', style: TextStyle(color: AppColors.midGray)),
          ),
          Flexible(child: Text(product.name,
              style: AppTextStyles.body(
                  fontSize: 12, color: AppColors.midGray),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 32),

        // Contenido principal
        w > 700
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2,
                    child: _ProductImage(product: product)),
                const SizedBox(width: 48),
                Expanded(flex: 3,
                    child: _ProductInfo(
                      product: product, quantity: quantity,
                      added: added,
                      onQuantityChanged: onQuantityChanged,
                      onAddToCart: onAddToCart,
                    )),
              ])
            : Column(children: [
                _ProductImage(product: product),
                const SizedBox(height: 32),
                _ProductInfo(
                  product: product, quantity: quantity,
                  added: added,
                  onQuantityChanged: onQuantityChanged,
                  onAddToCart: onAddToCart,
                ),
              ]),
      ]),
    );
  }
}

// ── Imagen ─────────────────────────────────────────────────────────────────
class _ProductImage extends StatelessWidget {
  final ProductModel product;
  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: product.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: product.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 80))),
              ))
          : Center(child: Text(product.emoji,
              style: const TextStyle(fontSize: 80))),
    );
  }
}

// ── Información y acciones ─────────────────────────────────────────────────
class _ProductInfo extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final bool added;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const _ProductInfo({
    required this.product, required this.quantity,
    required this.added, required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final stock = product.stock ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Marca y badge
      Row(children: [
        Text(product.brand.toUpperCase(),
            style: AppTextStyles.brandLabel()),
        if (product.badge != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: product.badgeIsRed
                  ? AppColors.discount : AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(product.badge!,
                style: AppTextStyles.badge()),
          ),
        ],
      ]),
      const SizedBox(height: 8),

      // Nombre
      Text(product.name, style: AppTextStyles.sectionTitle(fontSize: 24)),
      const SizedBox(height: 16),

      // Precio
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(product.price,
            style: AppTextStyles.productPrice(fontSize: 28)),
        if (product.originalPrice != null) ...[
          const SizedBox(width: 10),
          Text(product.originalPrice!,
              style: AppTextStyles.oldPrice()),
        ],
      ]),
      const SizedBox(height: 16),

      // Stock
      Row(children: [
        Icon(
          stock > 5 ? Icons.check_circle_outline
              : stock > 0 ? Icons.warning_amber_outlined
              : Icons.cancel_outlined,
          size: 16,
          color: stock > 5 ? AppColors.primary
              : stock > 0 ? const Color(0xFFF57F17)
              : AppColors.discount,
        ),
        const SizedBox(width: 6),
        Text(
          stock > 5 ? 'En stock ($stock disponibles)'
              : stock > 0 ? 'Stock bajo (solo $stock)'
              : 'Sin stock',
          style: AppTextStyles.body(
            fontSize: 13,
            color: stock > 5 ? AppColors.primary
                : stock > 0 ? const Color(0xFFF57F17)
                : AppColors.discount,
          ),
        ),
      ]),
      const SizedBox(height: 20),

      // Descripción
      if (product.description != null) ...[
        Text(product.description!,
            style: AppTextStyles.body(
                fontSize: 14, color: const Color(0xFF555555))),
        const SizedBox(height: 24),
      ],

      // Selector de cantidad
      if (stock > 0) ...[
        Text('Cantidad', style: AppTextStyles.body(
            fontSize: 13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          _QtyBtn(
            icon: Icons.remove,
            onTap: () {
              if (quantity > 1) onQuantityChanged(quantity - 1);
            },
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text('$quantity',
                style: AppTextStyles.body(
                    fontSize: 16, weight: FontWeight.w600)),
          ),
          _QtyBtn(
            icon: Icons.add,
            onTap: () {
              if (quantity < stock) onQuantityChanged(quantity + 1);
            },
          ),
        ]),
        const SizedBox(height: 20),

        // Botón agregar al carrito
        SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: added ? AppColors.g2 : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                  added ? Icons.check : Icons.add_shopping_cart,
                  color: Colors.white),
              label: Text(
                added ? '¡Agregado al carrito!' : 'Agregar al carrito',
                style: AppTextStyles.btnLabel(fontSize: 15)
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],

      // Especificaciones
      if (product.specs != null && product.specs!.isNotEmpty) ...[
        const SizedBox(height: 32),
        Text('Especificaciones técnicas',
            style: AppTextStyles.sectionTitle(fontSize: 16)),
        const SizedBox(height: 12),
        ...product.specs!.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 14),
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            SizedBox(
              width: 160,
              child: Text(e.key, style: AppTextStyles.body(
                  fontSize: 13, color: AppColors.midGray)),
            ),
            Expanded(child: Text(e.value,
                style: AppTextStyles.body(
                    fontSize: 13, weight: FontWeight.w500))),
          ]),
        )),
      ],
    ]);
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: AppColors.dark),
    ),
  );
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 400,
    child: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off, size: 48, color: AppColors.midGray),
        const SizedBox(height: 16),
        Text('Producto no encontrado',
            style: AppTextStyles.sectionTitle(fontSize: 18)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.catalog),
          child: const Text('Volver al catálogo'),
        ),
      ],
    )),
  );
}
