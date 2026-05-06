import 'package:flutter/material.dart';
import '../../../core/state/cart_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/cart_item_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.read(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          // Imagen / emoji del producto
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: item.product.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                item.product.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.brand.toUpperCase(),
                  style: AppTextStyles.brandLabel(),
                ),
                const SizedBox(height: 2),
                Text(
                  item.product.name,
                  style: AppTextStyles.body(
                    fontSize: 13,
                    weight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item.product.price,
                  style: AppTextStyles.productPrice(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Controles de cantidad
          Column(
            children: [
              // Botón eliminar
              GestureDetector(
                onTap: () => cart.removeItem(item.product.id),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFFBBBBBB),
                ),
              ),
              const SizedBox(height: 8),

              // Selector cantidad
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () => cart.decrement(item.product.id),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyles.body(
                          fontSize: 13,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () => cart.increment(item.product.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.surface,
        ),
        child: Icon(icon, size: 14, color: AppColors.dark),
      ),
    );
  }
}
