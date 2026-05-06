import 'package:flutter/foundation.dart';
import 'observer.dart';
import 'auth_events.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  OBSERVADORES CONCRETOS DE AUTENTICACIÓN
// ══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
//  1. AuthLoggerObserver
//  Registra todos los eventos de autenticación.
// ─────────────────────────────────────────────────────────────────────────────
class AuthLoggerObserver implements Observer<AuthEvent> {
  const AuthLoggerObserver();

  @override
  void onEvent(AuthEvent event) {
    if (kDebugMode) {
      final icon = switch (event.type) {
        AuthEventType.loggedIn       => '🔓',
        AuthEventType.loggedOut      => '🔒',
        AuthEventType.registered     => '✅',
        AuthEventType.sessionExpired => '⏰',
      };
      print('[AuthLogger] $icon ${event.type.name} '
            '| user: ${event.userName ?? "—"} '
            '| ${event.timestamp.toIso8601String()}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. SessionGuardObserver
//  Reacciona a la expiración del token redirigiendo al login.
//  El callback onSessionExpired viene del router de la app.
// ─────────────────────────────────────────────────────────────────────────────
class SessionGuardObserver implements Observer<AuthEvent> {
  final void Function() onSessionExpired;

  const SessionGuardObserver({required this.onSessionExpired});

  @override
  void onEvent(AuthEvent event) {
    if (event.type == AuthEventType.sessionExpired) {
      if (kDebugMode) print('[SessionGuard] ⏰ Sesión expirada → redirigiendo al login');
      onSessionExpired();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  3. AuthAnalyticsObserver
//  Registra eventos de autenticación para métricas de negocio.
// ─────────────────────────────────────────────────────────────────────────────
class AuthAnalyticsObserver implements Observer<AuthEvent> {
  const AuthAnalyticsObserver();

  @override
  void onEvent(AuthEvent event) {
    switch (event.type) {
      case AuthEventType.loggedIn:
        _track('login', {'user_id': event.userId});
      case AuthEventType.registered:
        _track('sign_up', {'user_id': event.userId});
      case AuthEventType.loggedOut:
        _track('logout', {'user_id': event.userId});
      case AuthEventType.sessionExpired:
        _track('session_expired', {'user_id': event.userId});
    }
  }

  void _track(String eventName, Map<String, dynamic> params) {
    if (kDebugMode) print('[AuthAnalytics] 📊 $eventName → $params');
  }
}
