import 'package:flutter/foundation.dart';
import 'app_security_config.dart';

/// Control de intentos de login en el cliente.
/// Bloquea temporalmente la UI después de N intentos fallidos,
/// evitando ataques de fuerza bruta desde el frontend.
class RateLimiter extends ChangeNotifier {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  int _attempts    = 0;
  DateTime? _lockedUntil;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLocked {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _attempts    = 0;
      return false;
    }
    return true;
  }

  Duration get remainingLockTime {
    if (_lockedUntil == null) return Duration.zero;
    final remaining = _lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get lockMessage {
    final mins = remainingLockTime.inMinutes;
    final secs = remainingLockTime.inSeconds % 60;
    if (mins > 0) {
      return 'Demasiados intentos. Espera $mins min $secs s para continuar.';
    }
    return 'Demasiados intentos. Espera $secs segundos para continuar.';
  }

  int get attemptsLeft =>
      (AppSecurityConfig.maxLoginAttempts - _attempts).clamp(0, 99);

  // ── Acciones ───────────────────────────────────────────────────────────────
  /// Registra un intento fallido. Bloquea si se supera el límite.
  void registerFailedAttempt() {
    if (isLocked) return;
    _attempts++;
    if (_attempts >= AppSecurityConfig.maxLoginAttempts) {
      _lockedUntil = DateTime.now().add(AppSecurityConfig.loginLockDuration);
    }
    notifyListeners();
  }

  /// Reinicia el contador tras un login exitoso.
  void reset() {
    _attempts    = 0;
    _lockedUntil = null;
    notifyListeners();
  }
}
