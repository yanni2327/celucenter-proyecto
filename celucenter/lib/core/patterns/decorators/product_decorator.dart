import 'package:flutter/material.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PATRÓN DECORATOR — Productos CeluCenter
//
//  Problema que resuelve:
//  Cada producto puede tener múltiples "capas" de presentación:
//  puede ser nuevo, tener descuento Y tener poco stock al mismo tiempo.
//  Sin Decorator necesitaríamos un if/else por cada combinación posible.
//
//  Con Decorator: cada capa se agrega independientemente y se combinan.
//
//  Estructura:
//    IProductCard (interfaz)
//         │
//         ├── BaseProductCard          → tarjeta básica sin decoración
//         │
//         └── ProductCardDecorator     → base de todos los decoradores
//              ├── DiscountDecorator   → muestra precio tachado + % ahorro
//              ├── LowStockDecorator   → alerta de stock bajo
//              ├── NewArrivalDecorator → badge "NUEVO" animado
//              └── FeaturedDecorator   → borde y fondo destacado
// ─────────────────────────────────────────────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════════
//  INTERFAZ BASE — IProductCard
// ══════════════════════════════════════════════════════════════════════════════
abstract class IProductCard {
  Widget buildCard(BuildContext context);
  List<Widget> buildBadges();
  Widget? buildAlert();
  Color get cardBorderColor;
  Color get cardBackground;
}

// ══════════════════════════════════════════════════════════════════════════════
//  COMPONENTE BASE — BaseProductCard
//  Muestra el producto sin ninguna decoración adicional.
// ══════════════════════════════════════════════════════════════════════════════
class BaseProductCard implements IProductCard {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const BaseProductCard({
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Color get cardBorderColor => AppColors.lightBorder;

  @override
  Color get cardBackground => AppColors.white;

  @override
  List<Widget> buildBadges() => [];

  @override
  Widget? buildAlert() => null;

  @override
  Widget buildCard(BuildContext context) {
    return _DecoratedProductCard(
      product:     product,
      decorator:   this,
      onTap:       onTap,
      onAddToCart: onAddToCart,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CLASE BASE DE DECORADORES — ProductCardDecorator
//  Delega todo al decorador envuelto, solo sobreescribe lo necesario.
// ══════════════════════════════════════════════════════════════════════════════
abstract class ProductCardDecorator implements IProductCard {
  final IProductCard _wrapped;
  const ProductCardDecorator(this._wrapped);

  @override
  Color get cardBorderColor => _wrapped.cardBorderColor;

  @override
  Color get cardBackground => _wrapped.cardBackground;

  @override
  List<Widget> buildBadges() => _wrapped.buildBadges();

  @override
  Widget? buildAlert() => _wrapped.buildAlert();

  @override
  Widget buildCard(BuildContext context) => _wrapped.buildCard(context);
}

// ══════════════════════════════════════════════════════════════════════════════
//  DECORADOR 1 — DiscountDecorator
//  Agrega visualmente el porcentaje de descuento y el precio original tachado.
// ══════════════════════════════════════════════════════════════════════════════
class DiscountDecorator extends ProductCardDecorator {
  final int originalPrice;
  final int currentPrice;

  const DiscountDecorator(
    super.wrapped, {
    required this.originalPrice,
    required this.currentPrice,
  });

  int get discountPercent =>
      ((originalPrice - currentPrice) / originalPrice * 100).round();

  @override
  List<Widget> buildBadges() {
    return [
      // Badge de descuento
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.discount,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '-$discountPercent%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 4),
      // Badge de ahorro en pesos
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.discount.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.discount.withOpacity(0.3)),
        ),
        child: Text(
          'Ahorras \$${_fmt(originalPrice - currentPrice)}',
          style: TextStyle(
            color: AppColors.discount,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Badges del decorador envuelto
      ..._wrapped.buildBadges(),
    ];
  }

  @override
  Color get cardBorderColor => AppColors.discount.withOpacity(0.3);

  String _fmt(int price) {
    final s   = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DECORADOR 2 — LowStockDecorator
//  Agrega una alerta roja cuando el stock es bajo (≤5 unidades).
// ══════════════════════════════════════════════════════════════════════════════
class LowStockDecorator extends ProductCardDecorator {
  final int stock;
  static const int _threshold = 5;

  const LowStockDecorator(super.wrapped, {required this.stock});

  @override
  Widget? buildAlert() {
    if (stock <= 0) {
      return _AlertBanner(
        text: '😞 Sin stock',
        color: const Color(0xFF9E9E9E),
      );
    }
    if (stock <= _threshold) {
      return _AlertBanner(
        text: '⚡ ¡Solo $stock disponibles!',
        color: const Color(0xFFE53935),
      );
    }
    return _wrapped.buildAlert();
  }

  @override
  Color get cardBorderColor => stock <= _threshold
      ? const Color(0xFFE53935).withOpacity(0.4)
      : _wrapped.cardBorderColor;
}

class _AlertBanner extends StatelessWidget {
  final String text;
  final Color color;
  const _AlertBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: color.withOpacity(0.1),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DECORADOR 3 — NewArrivalDecorator
//  Agrega un badge "NUEVO" con animación de pulso.
// ══════════════════════════════════════════════════════════════════════════════
class NewArrivalDecorator extends ProductCardDecorator {
  const NewArrivalDecorator(super.wrapped);

  @override
  List<Widget> buildBadges() {
    return [
      const _PulsingBadge(),
      ..._wrapped.buildBadges(),
    ];
  }

  @override
  Color get cardBackground =>
      AppColors.g9.withOpacity(0.3);
}

class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge();

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('✨ NUEVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DECORADOR 4 — FeaturedDecorator
//  Agrega borde dorado y fondo especial para productos destacados.
// ══════════════════════════════════════════════════════════════════════════════
class FeaturedDecorator extends ProductCardDecorator {
  const FeaturedDecorator(super.wrapped);

  @override
  Color get cardBorderColor => const Color(0xFFFFB300);

  @override
  Color get cardBackground =>
      const Color(0xFFFFFDE7);

  @override
  List<Widget> buildBadges() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('⭐ DESTACADO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            )),
      ),
      ..._wrapped.buildBadges(),
    ];
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET FINAL — _DecoratedProductCard
//  Renderiza la tarjeta usando los valores del decorador activo.
// ══════════════════════════════════════════════════════════════════════════════
class _DecoratedProductCard extends StatefulWidget {
  final ProductModel product;
  final IProductCard decorator;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const _DecoratedProductCard({
    required this.product,
    required this.decorator,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<_DecoratedProductCard> createState() => _DecoratedProductCardState();
}

class _DecoratedProductCardState extends State<_DecoratedProductCard> {
  bool _hovered = false;
  bool _added   = false;

  @override
  Widget build(BuildContext context) {
    final badges = widget.decorator.buildBadges();
    final alert  = widget.decorator.buildAlert();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.decorator.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withOpacity(0.5)
                  : widget.decorator.cardBorderColor,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen / emoji
              Stack(children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: widget.product.bgColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: widget.product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            widget.product.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            headers: const {
                              'Access-Control-Allow-Origin': '*',
                            },
                            loadingBuilder: (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                            errorBuilder: (_, error, __) {
                              return Center(
                                child: Text(widget.product.emoji,
                                    style: const TextStyle(fontSize: 44)));
                            },
                          ))
                      : Center(child: Text(widget.product.emoji,
                            style: const TextStyle(fontSize: 44))),
                ),
              ]),

              // Alerta de stock (si existe)
              if (alert != null) alert,

              // Badges de los decoradores
              if (badges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Wrap(spacing: 4, runSpacing: 4, children: badges),
                ),

              // Info del producto
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.brand.toUpperCase(),
                        style: AppTextStyles.brandLabel()),
                    const SizedBox(height: 3),
                    Text(widget.product.name,
                        style: AppTextStyles.productName(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.price,
                                style: AppTextStyles.productPrice(fontSize: 16)),
                            if (widget.product.originalPrice != null)
                              Text(widget.product.originalPrice!,
                                  style: AppTextStyles.oldPrice()),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            widget.onAddToCart?.call();
                            setState(() => _added = true);
                            Future.delayed(const Duration(milliseconds: 1200),
                                () { if (mounted) setState(() => _added = false); });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _added ? AppColors.primary : AppColors.g9,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _added ? Icons.check : Icons.add_shopping_cart,
                              size: 16,
                              color: _added ? Colors.white : AppColors.primary,
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
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FACTORY — ProductDecoratorFactory
//
//  Decide automáticamente qué decoradores aplicar según las propiedades
//  del producto. Aquí se ve claramente cómo se combinan los decoradores.
// ══════════════════════════════════════════════════════════════════════════════
class ProductDecoratorFactory {
  ProductDecoratorFactory._();

  static IProductCard decorate(
    ProductModel product, {
    VoidCallback? onTap,
    VoidCallback? onAddToCart,
  }) {
    // Empezar con la tarjeta base
    IProductCard card = BaseProductCard(
      product:     product,
      onTap:       onTap,
      onAddToCart: onAddToCart,
    );

    // Aplicar LowStockDecorator si tiene stock bajo
    final stock = product.stock ?? 99;
    if (stock <= 5) {
      card = LowStockDecorator(card, stock: stock);
    }

    // Aplicar DiscountDecorator si tiene precio original
    if (product.originalPrice != null) {
      card = DiscountDecorator(
        card,
        originalPrice: int.tryParse(
              product.originalPrice!.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
        currentPrice: product.priceInt,
      );
    }

    // Aplicar NewArrivalDecorator si el badge es "Nuevo"
    if (product.badge == 'Nuevo') {
      card = NewArrivalDecorator(card);
    }

    return card;
  }
}
