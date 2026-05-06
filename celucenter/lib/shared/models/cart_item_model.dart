import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  // Precio limpio como double para poder calcular totales
  double get unitPrice {
    final clean = product.price
        .replaceAll('\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0;
  }

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
