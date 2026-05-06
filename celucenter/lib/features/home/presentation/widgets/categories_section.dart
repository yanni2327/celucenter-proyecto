import 'package:flutter/material.dart';
import '../../../../core/security/secure_http_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/product_model.dart';

class CategoriesSection extends StatefulWidget {
  final void Function(String category)? onCategoryTap;
  const CategoriesSection({super.key, this.onCategoryTap});

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  List<CategoryModel> _categories = [];
  bool _loading = true;

  static const _fallback = [
    CategoryModel(name: 'Smartphones', emoji: '📱', count: '— productos',
        bgColor: AppColors.g9, iconBgColor: AppColors.g7),
    CategoryModel(name: 'Computadoras', emoji: '💻', count: '— productos',
        bgColor: Color(0xFFF0F0F0), iconBgColor: Color(0xFFDDDDDD)),
    CategoryModel(name: 'Audio', emoji: '🎧', count: '— productos',
        bgColor: Color(0xFFFFF3E8), iconBgColor: Color(0xFFFFD8B0)),
    CategoryModel(name: 'Monitores', emoji: '🖥️', count: '— productos',
        bgColor: Color(0xFFF0F0F0), iconBgColor: Color(0xFFDDDDDD)),
    CategoryModel(name: 'Accesorios', emoji: '🔌', count: '— productos',
        bgColor: AppColors.g9, iconBgColor: AppColors.g7),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final response = await SecureHttpClient().get('/api/categorias');
    if (!mounted) return;

    if (response.isSuccess) {
      final data = (response.data['data'] as List)
          .map((j) => CategoryModel.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() { _categories = data; _loading = false; });
    } else {
      setState(() { _categories = _fallback; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final columns = w < 600 ? 2 : w < 900 ? 3 : 5;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(40, 52, 40, 40),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Categorías', style: AppTextStyles.sectionTitle()),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget.onCategoryTap?.call('Todos'),
                child: Text('Ver todas →',
                    style: AppTextStyles.body(
                        fontSize: 13, color: AppColors.primary, weight: FontWeight.w500)),
              ),
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
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, i) => _CategoryCard(
              category: _categories[i],
              onTap: () => widget.onCategoryTap?.call(_categories[i].name),
            ),
          ),
      ]),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.category.bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? AppColors.g6 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: widget.category.iconBgColor, shape: BoxShape.circle),
              child: Center(child: Text(widget.category.emoji,
                  style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 10),
            Text(widget.category.name,
                style: AppTextStyles.catName(), textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(widget.category.count, style: AppTextStyles.catCount()),
          ]),
        ),
      ),
    );
  }
}
