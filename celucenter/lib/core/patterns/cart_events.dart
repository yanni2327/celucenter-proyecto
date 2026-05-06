import '../../shared/models/product_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  EVENTOS DEL CARRITO
//  Cada cambio en el carrito genera un evento específico.
//  Los observadores deciden cuáles les interesan.
// ══════════════════════════════════════════════════════════════════════════════

/// Tipos de eventos que puede emitir el carrito.
enum CartEventType {
  itemAdded,     // Se agregó un producto
  itemRemoved,   // Se eliminó un producto
  itemIncreased, // Se aumentó la cantidad
  itemDecreased, // Se disminuyó la cantidad
  cartCleared,   // Se vació el carrito
  cartOpened,    // Se abrió el panel del carrito
  cartClosed,    // Se cerró el panel del carrito
}

/// Evento concreto emitido por el carrito.
/// Contiene el tipo de evento y el contexto necesario.
class CartEvent {
  final CartEventType type;
  final ProductModel? product; // producto involucrado (si aplica)
  final int? quantity;         // cantidad actual del producto
  final int totalItems;        // total de items en el carrito
  final DateTime timestamp;

  CartEvent({
    required this.type,
    this.product,
    this.quantity,
    required this.totalItems,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      'CartEvent(${type.name}, producto: ${product?.name ?? "—"}, '
      'total: $totalItems, ${timestamp.toIso8601String()})';
}
