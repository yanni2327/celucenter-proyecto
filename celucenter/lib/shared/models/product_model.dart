import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProductModel {
  final String id;
  final String brand;
  final String name;
  final String price;
  final String? originalPrice;
  final String emoji;
  final String? badge;
  final bool badgeIsRed;
  final Color bgColor;
  final String? description;
  final Map<String, String>? specs;
  final int? stock;
  final String? imageUrl;

  const ProductModel({
    required this.id,
    required this.brand,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.emoji,
    this.badge,
    this.badgeIsRed = false,
    required this.bgColor,
    this.description,
    this.specs,
    this.stock,
    this.imageUrl,
  });

  /// Construye un ProductModel desde la respuesta JSON del backend.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id:            json['id'] as String,
      brand:         json['brand'] as String,
      name:          json['name'] as String,
      price:         json['formattedPrice'] as String? ?? '\$${json['price']}',
      originalPrice: json['originalPrice'] != null
          ? _formatPrice(json['originalPrice'] as int)
          : null,
      emoji:         json['emoji'] as String? ?? '📦',
      badge:         json['badge'] as String?,
      badgeIsRed:    json['badgeIsRed'] as bool? ?? false,
      bgColor:       _colorForCategory(json['category'] as String? ?? ''),
      description:   json['description'] as String?,
      imageUrl:      json['imageUrl'] as String?,
      specs:         (json['specs'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      stock:         json['stock'] as int?,
    );
  }

  /// Precio como entero (para cálculos en el carrito).
  int get priceInt {
    final clean = price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(clean) ?? 0;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer(r'$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'smartphones': return AppColors.prodBg1;
      case 'computadoras': return AppColors.prodBg2;
      case 'audio': return AppColors.prodBg3;
      case 'monitores': return AppColors.prodBg4;
      default: return AppColors.prodBg2;
    }
  }
}

class CategoryModel {
  final String name;
  final String emoji;
  final String count;
  final Color bgColor;
  final Color iconBgColor;

  const CategoryModel({
    required this.name,
    required this.emoji,
    required this.count,
    required this.bgColor,
    required this.iconBgColor,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final name  = json['name'] as String;
    final count = json['count'] as int;
    return CategoryModel(
      name:        name,
      emoji:       _emojiForCategory(name),
      count:       '$count productos',
      bgColor:     _bgForCategory(name),
      iconBgColor: _iconBgForCategory(name),
    );
  }

  static String _emojiForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'smartphones':  return '📱';
      case 'computadoras': return '💻';
      case 'audio':        return '🎧';
      case 'monitores':    return '🖥️';
      default:             return '🔌';
    }
  }

  static Color _bgForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'smartphones':  return AppColors.g9;
      case 'audio':        return const Color(0xFFFFF3E8);
      default:             return const Color(0xFFF0F0F0);
    }
  }

  static Color _iconBgForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'smartphones':  return AppColors.g7;
      case 'audio':        return const Color(0xFFFFD8B0);
      default:             return const Color(0xFFDDDDDD);
    }
  }
}
