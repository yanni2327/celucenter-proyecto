import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/cart_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'cart_item_tile.dart';

class CartDrawer extends StatelessWidget {
  const CartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cart        = CartScope.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth < 500 ? screenWidth : 420.0;

    return Stack(
      children: [
        // Fondo oscuro semitransparente
        if (cart.isOpen)
          GestureDetector(
            onTap: cart.closeCart,
            child: Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // Panel del carrito
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          right: cart.isOpen ? 0 : -drawerWidth,
          top: 0, bottom: 0, width: drawerWidth,
          child: Material(
            color: AppColors.white,
            elevation: 0,
            child: Column(
              children: [
                _DrawerHeader(itemCount: cart.itemCount),
                Expanded(
                  child: cart.isEmpty
                      ? const _EmptyCart()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          itemCount: cart.items.length,
                          itemBuilder: (_, i) => CartItemTile(item: cart.items[i]),
                        ),
                ),
                if (!cart.isEmpty) _DrawerFooter(
                  total: cart.totalFormatted,
                  onCheckout: () {
                    cart.closeCart();
                    context.go(AppRoutes.checkout);
                  },
                  onContinue: cart.closeCart,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final int itemCount;
  const _DrawerHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.read(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      decoration: const BoxDecoration(color: AppColors.white,
          border: Border(bottom: BorderSide(color: AppColors.lightBorder))),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mi carrito', style: AppTextStyles.sectionTitle(fontSize: 18)),
          const SizedBox(height: 2),
          Text('$itemCount ${itemCount == 1 ? 'producto' : 'productos'}',
              style: AppTextStyles.body(fontSize: 12, color: AppColors.midGray)),
        ]),
        const Spacer(),
        if (itemCount > 0)
          TextButton(
            onPressed: () => _confirmClear(context, cart.clearCart),
            child: Text('Vaciar', style: AppTextStyles.body(
                fontSize: 12, color: AppColors.midGray)),
          ),
        IconButton(onPressed: cart.closeCart,
            icon: const Icon(Icons.close, size: 20), color: AppColors.dark),
      ]),
    );
  }

  void _confirmClear(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Vaciar carrito', style: AppTextStyles.sectionTitle(fontSize: 16)),
        content: Text('¿Eliminar todos los productos?',
            style: AppTextStyles.body(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { onConfirm(); Navigator.pop(context); },
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(color: AppColors.g9, shape: BoxShape.circle),
        child: const Icon(Icons.shopping_cart_outlined,
            size: 32, color: AppColors.primary),
      ),
      const SizedBox(height: 16),
      Text('Tu carrito está vacío', style: AppTextStyles.sectionTitle(fontSize: 16)),
      const SizedBox(height: 8),
      Text('Agrega productos desde el catálogo',
          style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
    ]));
  }
}

// ── Footer con total y botón de checkout ────────────────────────────────────
class _DrawerFooter extends StatelessWidget {
  final String total;
  final VoidCallback onCheckout;
  final VoidCallback onContinue;

  const _DrawerFooter({
    required this.total,
    required this.onCheckout,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.lightBorder))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Subtotal', style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
          Text(total, style: AppTextStyles.body(fontSize: 13, weight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Envío', style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
          Text('Gratis', style: AppTextStyles.body(
              fontSize: 13, color: AppColors.primary, weight: FontWeight.w500)),
        ]),
        const SizedBox(height: 12),
        Container(height: 1, color: AppColors.lightBorder),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: AppTextStyles.sectionTitle(fontSize: 16)),
          Text(total, style: AppTextStyles.productPrice(fontSize: 20)),
        ]),
        const SizedBox(height: 16),

        // Botón ir a checkout
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Proceder al pago',
                style: AppTextStyles.btnLabel(fontSize: 15)
                    .copyWith(color: AppColors.white)),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onContinue,
            child: Text('Continuar comprando',
                style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
          ),
        ),
      ]),
    );
  }
}
