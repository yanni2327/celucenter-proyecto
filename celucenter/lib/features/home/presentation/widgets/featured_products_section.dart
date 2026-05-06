import 'package:flutter/material.dart';
import '../../../../core/security/secure_http_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/product_model.dart';
import 'product_card.dart';

class FeaturedProductsSection extends StatefulWidget {
  const FeaturedProductsSection({super.key});

  /// Lista de respaldo cuando la API no está disponible.
  static final List<ProductModel> _fallback = [
    const ProductModel(id: 'p1', brand: 'Samsung', name: 'Galaxy S25 Ultra 256GB',
        price: r'$3.899.000', emoji: '📱', badge: 'Nuevo', bgColor: AppColors.prodBg1),
    const ProductModel(id: 'p2', brand: 'Apple', name: 'MacBook Air M3 13"',
        price: r'$6.499.000', originalPrice: r'$7.900.000', emoji: '💻',
        badge: '-18%', badgeIsRed: true, bgColor: AppColors.prodBg2),
    const ProductModel(id: 'p3', brand: 'Sony', name: 'WH-1000XM5',
        price: r'$1.249.000', emoji: '🎧', bgColor: AppColors.prodBg3),
    const ProductModel(id: 'p4', brand: 'LG', name: 'Monitor 34" UltraWide',
        price: r'$2.190.000', emoji: '🖥️', badge: 'Stock bajo', bgColor: AppColors.prodBg4),
    const ProductModel(id: 'p5', brand: 'Logitech', name: 'MX Master 3S',
        price: r'$389.000', emoji: '🖱️', bgColor: AppColors.prodBg2),
    const ProductModel(id: 'p6', brand: 'Apple', name: 'iPhone 16 Pro 128GB',
        price: r'$5.299.000', emoji: '📱', badge: 'Nuevo', bgColor: AppColors.prodBg1),
    const ProductModel(id: 'p7', brand: 'Xiaomi', name: 'Redmi Note 14 Pro',
        price: r'$1.099.000', originalPrice: r'$1.350.000', emoji: '📱',
        badge: '-19%', badgeIsRed: true, bgColor: AppColors.prodBg3),
    const ProductModel(id: 'p8', brand: 'Samsung', name: 'Galaxy Tab S9 FE',
        price: r'$1.590.000', emoji: '📟', bgColor: AppColors.prodBg4),
  ];

  /// Acceso estático para el catálogo (fallback).
  static List<ProductModel> get products => _fallback;

  @override
  State<FeaturedProductsSection> createState() =>
      _FeaturedProductsSectionState();
}

class _FeaturedProductsSectionState extends State<FeaturedProductsSection> {
  List<ProductModel> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await SecureHttpClient().get('/api/productos');
    if (!mounted) return;

    if (response.isSuccess) {
      final data = (response.data['data'] as List)
          .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
          .take(8)
          .toList();
      setState(() { _products = data; _loading = false; });
    } else {
      setState(() { _products = FeaturedProductsSection.products; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final columns = w < 600 ? 1 : w < 900 ? 2 : w < 1200 ? 3 : 4;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(40, 52, 40, 52),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Productos destacados', style: AppTextStyles.sectionTitle()),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text('Ver catálogo completo →',
                  style: AppTextStyles.body(
                      fontSize: 13, color: AppColors.primary, weight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 32),

        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16, mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: _products.length,
            itemBuilder: (_, i) => ProductCard(product: _products[i]),
          ),
      ]),
    );
  }
}
