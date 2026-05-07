class AppSecurityConfig {
  AppSecurityConfig._();

  // ── API ────────────────────────────────────────────────────────────────────
  /// URL del backend en producción (Render.com)
  static const String apiBaseUrl = 'https://celucenter-api.onrender.com';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  // ── Sesión ─────────────────────────────────────────────────────────────────
  static const Duration sessionDuration   = Duration(minutes: 60);
  static const String   sessionCookieName = 'cc_session';
  static const String   authHeaderPrefix  = 'Bearer';

  // ── Contraseñas ────────────────────────────────────────────────────────────
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;

  // ── Rate limiting ──────────────────────────────────────────────────────────
  static const int      maxLoginAttempts  = 5;
  static const Duration loginLockDuration = Duration(minutes: 15);

  // ── Inputs ─────────────────────────────────────────────────────────────────
  static const int maxTextFieldLength = 200;
  static const int maxSearchLength    = 100;

  // ── Headers ────────────────────────────────────────────────────────────────
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept':       'application/json',
    'X-Client-App': 'CeluCenter-Flutter-Web/1.0',
  };

  // ── Regex ──────────────────────────────────────────────────────────────────
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp nameRegex = RegExp(
    r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-]{2,50}$",
  );
  static final RegExp phoneRegex = RegExp(
    r'^(\+57)?[3][0-9]{9}$',
  );
  static final RegExp dangerousCharsRegex = RegExp(
    r"""[<>"'`]|javascript:|data:|vbscript:""",
    caseSensitive: false,
  );
}
