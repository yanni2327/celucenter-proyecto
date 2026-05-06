class OrderItem {
  final String productId;
  final String productName;
  final String productEmoji;
  final int quantity;
  final int unitPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productEmoji,
    required this.quantity,
    required this.unitPrice,
  });

  int get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productEmoji': productEmoji,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

enum OrderStatus { pendiente, pagado, preparando, enviado, entregado }

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String? notes;
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    this.notes,
    this.status = OrderStatus.pendiente,
    required this.createdAt,
  });

  int get total => items.fold(0, (sum, item) => sum + item.total);

  String get formattedTotal {
    final s = total.toString();
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'items': items.map((i) => i.toJson()).toList(),
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
        if (notes != null) 'notes': notes,
        'status': status.name,
        'total': total,
        'formattedTotal': formattedTotal,
        'createdAt': createdAt.toIso8601String(),
      };
}
