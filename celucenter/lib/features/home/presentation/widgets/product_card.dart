import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/cart_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _cardHovered = false;
  bool _btnHovered = false;
  bool _added = false;

  void _addToCart(BuildContext context) {
    CartScope.read(context).addItem(widget.product);

    // Feedback visual momentáneo en el botón
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _cardHovered = true),
      onExit: (_) => setState(() => _cardHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _cardHovered
                ? AppColors.g6.withOpacity(0.6)
                : AppColors.lightBorder,
          ),
          boxShadow: _cardHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ──────────────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: widget.product.bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: widget.product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: Image.network(
                            widget.product.imageUrl!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(widget.product.emoji,
                                  style: const TextStyle(fontSize: 48))),
                          ))
                      : Center(
                          child: Text(widget.product.emoji,
                              style: const TextStyle(fontSize: 48))),
                ),
                if (widget.product.badge != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.product.badgeIsRed
                            ? AppColors.discount
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(widget.product.badge!,
                          style: AppTextStyles.badge()),
                    ),
                  ),
              ],
            ),

            // ── Info ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.brand.toUpperCase(),
                      style: AppTextStyles.brandLabel()),
                  const SizedBox(height: 4),
                  Text(widget.product.name,
                      style: AppTextStyles.productName(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Precio
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.price,
                              style: AppTextStyles.productPrice()),
                          if (widget.product.originalPrice != null)
                            Text(widget.product.originalPrice!,
                                style: AppTextStyles.oldPrice()),
                        ],
                      ),

                      // Botón agregar al carrito
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) =>
                            setState(() => _btnHovered = true),
                        onExit: (_) =>
                            setState(() => _btnHovered = false),
                        child: GestureDetector(
                          onTap: () => _addToCart(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _added
                                  ? AppColors.primary
                                  : _btnHovered
                                      ? AppColors.primary
                                      : AppColors.g9,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _added
                                      ? Icons.check
                                      : Icons.add_shopping_cart,
                                  size: 14,
                                  color: _added || _btnHovered
                                      ? AppColors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _added ? '¡Agregado!' : 'Agregar',
                                  style: AppTextStyles.body(
                                    fontSize: 12,
                                    color: _added || _btnHovered
                                        ? AppColors.white
                                        : AppColors.primary,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
