import 'package:flutter/material.dart';
import 'cart_controller.dart';

/// InheritedNotifier que provee CartController a todo el árbol de widgets
/// sin necesidad de paquetes externos (como provider o riverpod).
class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    super.key,
    required CartController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Accede al CartController más cercano en el árbol.
  static CartController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'No CartScope encontrado en el árbol de widgets');
    return scope!.notifier!;
  }

  /// Versión sin dependencia (no reconstruye el widget al cambiar).
  static CartController read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'No CartScope encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}
