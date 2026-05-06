import 'package:flutter/foundation.dart';
import '../patterns/observer.dart';
import '../patterns/cart_events.dart';
import '../../shared/models/cart_item_model.dart';
import '../../shared/models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CartController — Sujeto (Observable) del patrón Observer
//
//  Extiende BaseObservable<CartEvent> → implementa el patrón Observer explícito.
//  Extiende ChangeNotifier            → integración con el árbol de widgets Flutter.
//
//  Cada vez que el carrito cambia:
//    1. Crea un CartEvent con los detalles del cambio
//    2. Llama a notifyObservers(event) → notifica a los observadores registrados
//    3. Llama a notifyListeners()      → reconstruye los widgets de Flutter
// ─────────────────────────────────────────────────────────────────────────────
class CartController extends BaseObservable<CartEvent> with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isOpen = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<CartItem> get items      => List.unmodifiable(_items);
  bool get isOpen               => _isOpen;
  bool get isEmpty              => _items.isEmpty;
  int  get itemCount            => _items.fold(0, (s, i) => s + i.quantity);
  double get total              => _items.fold(0.0, (s, i) => s + i.totalPrice);

  String get totalFormatted {
    final t = total.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < t.length; i++) {
      if (i > 0 && (t.length - i) % 3 == 0) buf.write('.');
      buf.write(t[i]);
    }
    return '\$${buf.toString()}';
  }

  // ── Acciones — cada una notifica el evento correspondiente ─────────────────
  void addItem(ProductModel product) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    _emit(CartEvent(
      type:       CartEventType.itemAdded,
      product:    product,
      quantity:   _items.firstWhere((i) => i.product.id == product.id).quantity,
      totalItems: itemCount,
    ));
    notifyListeners();
  }

  void removeItem(String productId) {
    final product = _items
        .where((i) => i.product.id == productId)
        .map((i) => i.product)
        .firstOrNull;
    _items.removeWhere((i) => i.product.id == productId);
    _emit(CartEvent(
      type:       CartEventType.itemRemoved,
      product:    product,
      totalItems: itemCount,
    ));
    notifyListeners();
  }

  void increment(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    _emit(CartEvent(
      type:       CartEventType.itemIncreased,
      product:    _items[idx].product,
      quantity:   _items[idx].quantity,
      totalItems: itemCount,
    ));
    notifyListeners();
  }

  void decrement(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (_items[idx].quantity <= 1) {
      removeItem(productId);
      return;
    }
    _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity - 1);
    _emit(CartEvent(
      type:       CartEventType.itemDecreased,
      product:    _items[idx].product,
      quantity:   _items[idx].quantity,
      totalItems: itemCount,
    ));
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _emit(CartEvent(type: CartEventType.cartCleared, totalItems: 0));
    notifyListeners();
  }

  void openCart() {
    _isOpen = true;
    _emit(CartEvent(type: CartEventType.cartOpened, totalItems: itemCount));
    notifyListeners();
  }

  void closeCart() {
    _isOpen = false;
    _emit(CartEvent(type: CartEventType.cartClosed, totalItems: itemCount));
    notifyListeners();
  }

  void toggleCart() => _isOpen ? closeCart() : openCart();

  // ── Notificación interna ────────────────────────────────────────────────────
  void _emit(CartEvent event) {
    if (kDebugMode) print('[CartController] → ${event}');
    notifyObservers(event);
  }
}
