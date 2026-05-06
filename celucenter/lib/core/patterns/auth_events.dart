// ══════════════════════════════════════════════════════════════════════════════
//  EVENTOS DE AUTENTICACIÓN
// ══════════════════════════════════════════════════════════════════════════════

enum AuthEventType {
  loggedIn,       // Usuario inició sesión
  loggedOut,      // Usuario cerró sesión
  registered,     // Usuario creó cuenta nueva
  sessionExpired, // Token JWT expiró
}

class AuthEvent {
  final AuthEventType type;
  final String? userId;
  final String? userName;
  final DateTime timestamp;

  AuthEvent({
    required this.type,
    this.userId,
    this.userName,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      'AuthEvent(${type.name}, user: ${userName ?? "—"}, '
      '${timestamp.toIso8601String()})';
}
