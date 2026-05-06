import 'package:flutter/material.dart';
import 'observer.dart';
import 'cart_events.dart';
import 'auth_events.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SnackBarObserver — Observador visual
//
//  Muestra notificaciones en pantalla cada vez que el Sujeto emite un evento.
//  Usa un GlobalKey<ScaffoldMessengerState> para mostrar SnackBars
//  desde fuera del árbol de widgets, sin depender de un BuildContext específico.
// ─────────────────────────────────────────────────────────────────────────────

/// Clave global para acceder al ScaffoldMessenger desde cualquier parte.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// ── Observador del carrito ─────────────────────────────────────────────────
class CartSnackBarObserver implements Observer<CartEvent> {
  const CartSnackBarObserver();

  @override
  void onEvent(CartEvent event) {
    switch (event.type) {
      case CartEventType.itemAdded:
        _show(
          message: '${event.product?.name ?? "Producto"} agregado al carrito',
          icon: Icons.shopping_cart_outlined,
          color: AppColors.primary,
        );
      case CartEventType.itemRemoved:
        _show(
          message: '${event.product?.name ?? "Producto"} eliminado',
          icon: Icons.remove_shopping_cart_outlined,
          color: const Color(0xFF666666),
        );
      case CartEventType.cartCleared:
        _show(
          message: 'Carrito vaciado',
          icon: Icons.delete_outline,
          color: const Color(0xFF888888),
        );
      default:
        break; // No mostrar notificación para abrir/cerrar carrito
    }
  }

  void _show({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body(
                    fontSize: 13,
                    color: Colors.white,
                    weight: FontWeight.w500),
              ),
            ),
          ]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
          elevation: 4,
        ),
      );
  }
}

// ── Observador de autenticación ────────────────────────────────────────────
class AuthSnackBarObserver implements Observer<AuthEvent> {
  const AuthSnackBarObserver();

  @override
  void onEvent(AuthEvent event) {
    switch (event.type) {
      case AuthEventType.loggedIn:
        _show(
          message: '¡Bienvenido de nuevo, ${event.userName ?? ""}!',
          icon: Icons.person_outline,
          color: AppColors.primary,
        );
      case AuthEventType.registered:
        _show(
          message: '¡Cuenta creada! Bienvenido, ${event.userName ?? ""}',
          icon: Icons.check_circle_outline,
          color: AppColors.g2,
        );
      case AuthEventType.loggedOut:
        _show(
          message: 'Sesión cerrada correctamente',
          icon: Icons.logout,
          color: const Color(0xFF666666),
        );
      case AuthEventType.sessionExpired:
        _show(
          message: 'Tu sesión expiró. Por favor inicia sesión nuevamente.',
          icon: Icons.timer_off_outlined,
          color: const Color(0xFFE57373),
        );
    }
  }

  void _show({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.body(
                      fontSize: 13,
                      color: Colors.white,
                      weight: FontWeight.w500)),
            ),
          ]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          elevation: 4,
        ),
      );
  }
}
