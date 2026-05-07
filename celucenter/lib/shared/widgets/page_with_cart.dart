import 'package:flutter/material.dart';
import '../../features/cart/presentation/cart_drawer.dart';

/// Envuelve cualquier página con el CartDrawer.
class PageWithCart extends StatelessWidget {
  final Widget child;
  const PageWithCart({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const CartDrawer(),
      ],
    );
  }
}
