class Product {
  final String id;
  final String brand;
  final String name;
  final int price;
  final int? originalPrice;
  final String emoji;
  final String category;
  final String? badge;
  final bool badgeIsRed;
  int stock;
  final String description;
  final Map<String, String> specs;
  String? imageUrl; // URL de Cloudinary

  Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.emoji,
    required this.category,
    this.badge,
    this.badgeIsRed = false,
    required this.stock,
    required this.description,
    this.specs = const {},
    this.imageUrl,
  });

  String get formattedPrice {
    final s = price.toString();
    final buf = StringBuffer(r'$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'id':            id,
        'brand':         brand,
        'name':          name,
        'price':         price,
        'formattedPrice':formattedPrice,
        if (originalPrice != null) 'originalPrice': originalPrice,
        'emoji':         emoji,
        'category':      category,
        if (badge != null) 'badge': badge,
        'badgeIsRed':    badgeIsRed,
        'stock':         stock,
        'description':   description,
        'specs':         specs,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
