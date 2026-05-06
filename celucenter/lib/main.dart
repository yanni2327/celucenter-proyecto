import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/state/auth_controller.dart';
import 'core/state/cart_controller.dart';
import 'core/state/cart_scope.dart';
import 'core/theme/app_theme.dart';
import 'core/patterns/cart_observers.dart';
import 'core/patterns/auth_observers.dart';
import 'core/patterns/snackbar_observer.dart';
import 'core/patterns/email_observer.dart';

void main() {
  runApp(const CeluCenterApp());
}

class CeluCenterApp extends StatefulWidget {
  const CeluCenterApp({super.key});

  @override
  State<CeluCenterApp> createState() => _CeluCenterAppState();
}

class _CeluCenterAppState extends State<CeluCenterApp> {
  final _cartController = CartController();
  final _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _registerObservers();
  }

  void _registerObservers() {
    // ── Observadores del Carrito ──────────────────────────────────────────
    _cartController
      ..addObserver(const CartLoggerObserver())
      ..addObserver(const CartAnalyticsObserver())
      ..addObserver(const CartSnackBarObserver())    // ← muestra notificación visual
      ..addObserver(StockAlertObserver(
          onLowStock: (name, stock) {
            debugPrint('⚠️ Stock bajo: $name ($stock disponibles)');
          }));

    // ── Observadores de Autenticación ─────────────────────────────────────
    _authController
      ..addObserver(const AuthLoggerObserver())
      ..addObserver(const AuthAnalyticsObserver())
      ..addObserver(const AuthSnackBarObserver())    // ← muestra notificación visual
      ..addObserver(EmailObserver())                 // ← envía correo via SendGrid
      ..addObserver(SessionGuardObserver(
          onSessionExpired: () => appRouter.go('/login')));

    debugPrint('[Observer] ✓ ${_cartController.observerCount} observadores de carrito');
    debugPrint('[Observer] ✓ ${_authController.observerCount} observadores de auth');
  }

  @override
  void dispose() {
    _cartController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CartScope(
      controller: _cartController,
      child: MaterialApp.router(
        title: 'CeluCenter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        // scaffoldMessengerKey permite mostrar SnackBars desde los observadores
        // sin necesitar un BuildContext
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    );
  }
}
