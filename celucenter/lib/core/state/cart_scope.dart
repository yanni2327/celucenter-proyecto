import 'package:flutter/material.dart';
import 'cart_controller.dart';

/// CartScope mantiene compatibilidad con el código existente.
/// Internamente usa el singleton CartController.
class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    super.key,
    required CartController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Obtiene el CartController — usa el singleton directamente.
  static CartController of(BuildContext context) {
    // Primero intenta InheritedWidget, si no usa el singleton
    final scope = context
        .dependOnInheritedWidgetOfExactType<CartScope>();
    return scope?.notifier ?? CartController();
  }

  /// Lee sin registrar dependencia — usa singleton.
  static CartController read(BuildContext context) {
    return CartController();
  }

  @override
  bool updateShouldNotify(CartScope oldWidget) => true;
}
