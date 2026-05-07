import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/cart_scope.dart';
import 'widgets/navbar_widget.dart';
import 'widgets/hero_section.dart';
import 'widgets/stats_bar.dart';
import 'widgets/categories_section.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/promo_band.dart';
import 'widgets/footer_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: NavBarDelegate(),
              ),
              const SliverToBoxAdapter(child: HeroSection()),
              const SliverToBoxAdapter(child: StatsBar()),
              SliverToBoxAdapter(
                child: CategoriesSection(
                  onCategoryTap: (_) => context.go(AppRoutes.catalog),
                ),
              ),
              const SliverToBoxAdapter(child: FeaturedProductsSection()),
              SliverToBoxAdapter(
                child: PromoBand(
                  onCtaTap: () => context.go(AppRoutes.catalog),
                ),
              ),
              const SliverToBoxAdapter(child: FooterWidget()),
            ],
          ),
    );
  }
}
