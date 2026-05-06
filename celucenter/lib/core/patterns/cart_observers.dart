import 'package:flutter/foundation.dart';
import 'observer.dart';
import 'cart_events.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  OBSERVADORES CONCRETOS DEL CARRITO
//
//  Cada clase implementa Observer<CartEvent> y define su propia reacción
//  ante los eventos del carrito. El CartController no los conoce directamente
//  — solo sabe que son Observer<CartEvent>.
// ══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
//  1. LoggerObserver
//  Registra todos los eventos del carrito en la consola.
//  Útil para depuración y auditoría.
// ─────────────────────────────────────────────────────────────────────────────
class CartLoggerObserver implements Observer<CartEvent> {
  const CartLoggerObserver();

  @override
  void onEvent(CartEvent event) {
    if (kDebugMode) {
      final icon = switch (event.type) {
        CartEventType.itemAdded     => '🛒 +',
        CartEventType.itemRemoved   => '🗑️  -',
        CartEventType.itemIncreased => '⬆️  +',
        CartEventType.itemDecreased => '⬇️  -',
        CartEventType.cartCleared   => '🧹  vaciado',
        CartEventType.cartOpened    => '📂  abierto',
        CartEventType.cartClosed    => '📁  cerrado',
      };
      print('[CartLogger] $icon '
            '${event.product?.name ?? ""} '
            '| total items: ${event.totalItems} '
            '| ${event.timestamp.toIso8601String()}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. StockAlertObserver
//  Monitorea si algún producto agregado tiene poco stock.
//  En producción podría mostrar un SnackBar o enviar una alerta.
// ─────────────────────────────────────────────────────────────────────────────
class StockAlertObserver implements Observer<CartEvent> {
  static const int _lowStockThreshold = 5;
  final void Function(String productName, int stock) onLowStock;

  const StockAlertObserver({required this.onLowStock});

  @override
  void onEvent(CartEvent event) {
    if (event.type != CartEventType.itemAdded) return;
    final product = event.product;
    if (product == null) return;

    final stock = product.stock ?? 99;
    if (stock <= _lowStockThreshold) {
      onLowStock(product.name, stock);
      if (kDebugMode) {
        print('[StockAlert] ⚠️ Stock bajo: ${product.name} → solo $stock disponibles');
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  3. AnalyticsObserver
//  Registra eventos de negocio para análisis.
//  En producción enviaría datos a Google Analytics, Mixpanel, etc.
// ─────────────────────────────────────────────────────────────────────────────
class CartAnalyticsObserver implements Observer<CartEvent> {
  const CartAnalyticsObserver();

  @override
  void onEvent(CartEvent event) {
    // Solo registrar eventos de negocio relevantes
    switch (event.type) {
      case CartEventType.itemAdded:
        _track('add_to_cart', {
          'product_id':   event.product?.id,
          'product_name': event.product?.name,
          'quantity':     event.quantity,
        });
      case CartEventType.cartCleared:
        _track('cart_cleared', {'total_items': event.totalItems});
      default:
        break;
    }
  }

  void _track(String eventName, Map<String, dynamic> params) {
    // En producción: FirebaseAnalytics.logEvent(name: eventName, parameters: params)
    if (kDebugMode) {
      print('[Analytics] 📊 $eventName → $params');
    }
  }
}
