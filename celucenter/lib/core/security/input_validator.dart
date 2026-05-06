import 'app_security_config.dart';

/// Validadores de formulario para CeluCenter.
/// Cada método devuelve null si el valor es válido,
/// o un String con el mensaje de error si no lo es.
/// Se usa directamente en el parámetro `validator` de TextFormField.
class InputValidator {
  InputValidator._();

  // ── Email ──────────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    final trimmed = value.trim();
    if (trimmed.length > AppSecurityConfig.maxTextFieldLength) {
      return 'El correo es demasiado largo';
    }
    if (_containsDangerousChars(trimmed)) {
      return 'El correo contiene caracteres no permitidos';
    }
    if (!AppSecurityConfig.emailRegex.hasMatch(trimmed)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  // ── Contraseña ─────────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < AppSecurityConfig.passwordMinLength) {
      return 'La contraseña debe tener al menos ${AppSecurityConfig.passwordMinLength} caracteres';
    }
    if (value.length > AppSecurityConfig.passwordMaxLength) {
      return 'La contraseña es demasiado larga';
    }
    if (!_hasUppercase(value)) {
      return 'Debe incluir al menos una letra mayúscula';
    }
    if (!_hasDigit(value)) {
      return 'Debe incluir al menos un número';
    }
    if (!_hasSpecialChar(value)) {
      return 'Debe incluir al menos un carácter especial (!@#\$%&*)';
    }
    return null;
  }

  /// Validador más permisivo para login (no muestra qué falta por seguridad).
  static String? passwordLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < AppSecurityConfig.passwordMinLength) {
      return 'Contraseña o usuario incorrectos';
    }
    return null;
  }

  /// Confirmación de contraseña — recibe la contraseña original.
  static String? Function(String?) passwordConfirm(String? original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirma tu contraseña';
      }
      if (value != original) {
        return 'Las contraseñas no coinciden';
      }
      return null;
    };
  }

  // ── Nombre ─────────────────────────────────────────────────────────────────
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    final trimmed = value.trim();
    if (_containsDangerousChars(trimmed)) {
      return 'El nombre contiene caracteres no permitidos';
    }
    if (!AppSecurityConfig.nameRegex.hasMatch(trimmed)) {
      return 'Ingresa un nombre válido (solo letras y espacios)';
    }
    return null;
  }

  // ── Teléfono ───────────────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!AppSecurityConfig.phoneRegex.hasMatch(clean)) {
      return 'Ingresa un número de celular colombiano válido (ej. 3001234567)';
    }
    return null;
  }

  // ── Dirección de envío ─────────────────────────────────────────────────────
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La dirección es obligatoria';
    }
    if (value.trim().length < 10) {
      return 'Ingresa una dirección más completa';
    }
    if (value.trim().length > AppSecurityConfig.maxTextFieldLength) {
      return 'La dirección es demasiado larga';
    }
    if (_containsDangerousChars(value)) {
      return 'La dirección contiene caracteres no permitidos';
    }
    return null;
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────────
  static String? search(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > AppSecurityConfig.maxSearchLength) {
      return 'La búsqueda es demasiado larga';
    }
    if (_containsDangerousChars(value)) {
      return 'La búsqueda contiene caracteres no permitidos';
    }
    return null;
  }

  // ── Campo requerido genérico ───────────────────────────────────────────────
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    if (_containsDangerousChars(value)) {
      return 'El campo contiene caracteres no permitidos';
    }
    return null;
  }

  // ── Helpers privados ───────────────────────────────────────────────────────
  static bool _containsDangerousChars(String value) =>
      AppSecurityConfig.dangerousCharsRegex.hasMatch(value);

  static bool _hasUppercase(String value) =>
      value.contains(RegExp(r'[A-Z]'));

  static bool _hasDigit(String value) =>
      value.contains(RegExp(r'[0-9]'));

  static bool _hasSpecialChar(String value) =>
      value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\+=]'));

  // ── Sanitización (para usar antes de mostrar datos del servidor) ───────────
  /// Elimina etiquetas HTML básicas de un string (XSS básico).
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// Indica si una contraseña es fuerte (para el indicador visual).
  static PasswordStrength checkStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    int score = 0;
    if (password.length >= 8)   score++;
    if (password.length >= 12)  score++;
    if (_hasUppercase(password)) score++;
    if (_hasDigit(password))     score++;
    if (_hasSpecialChar(password)) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, medium, strong }
