import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/catalog/presentation/catalog_page.dart';
import '../../features/checkout/presentation/checkout_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/product/presentation/product_detail_page.dart';
import '../../features/warehouse/presentation/warehouse_page.dart';

class AppRoutes {
  AppRoutes._();
  static const home      = '/';
  static const login     = '/login';
  static const register  = '/register';
  static const catalog   = '/catalogo';
  static const checkout  = '/checkout';
  static const admin     = '/admin';
  static const profile   = '/perfil';
  static const warehouse = '/bodega';
  static String product(String id) => '/producto/$id';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.home,
        builder: (_, __) => const HomePage()),
    GoRoute(path: AppRoutes.login,
        builder: (_, __) => const LoginPage()),
    GoRoute(path: AppRoutes.register,
        builder: (_, __) => const RegisterPage()),
    GoRoute(path: AppRoutes.catalog,
        builder: (_, __) => const CatalogPage()),
    GoRoute(path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutPage()),
    GoRoute(path: AppRoutes.admin,
        builder: (_, __) => const AdminPage()),
    GoRoute(path: AppRoutes.profile,
        builder: (_, __) => const ProfilePage()),
    GoRoute(path: AppRoutes.warehouse,
        builder: (_, __) => const WarehousePage()),
    GoRoute(path: '/producto/:id',
        builder: (_, state) => ProductDetailPage(
            productId: state.pathParameters['id'] ?? '')),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('404',
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
        Text('Página no encontrada: ${state.uri}'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Volver al inicio'),
        ),
      ],
    )),
  ),
);
