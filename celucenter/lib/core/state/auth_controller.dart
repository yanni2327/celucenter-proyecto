import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../patterns/observer.dart';
import '../patterns/auth_events.dart';
import '../security/secure_http_client.dart';

class AuthController extends BaseObservable<AuthEvent> with ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  String? _token;
  Map<String, dynamic>? _user;

  bool    get isLoggedIn => _token != null;
  bool    get isAdmin    => _user?['isAdmin'] as bool? ?? false;
  String? get token      => _token;
  String? get userName   => _user?['name']  as String?;
  String? get userEmail  => _user?['email'] as String?;
  String? get userId     => _user?['id']    as String?;

  /// Carga la sesión guardada en localStorage al iniciar la app.
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final name  = prefs.getString('auth_name');
      final email = prefs.getString('auth_email');
      final id    = prefs.getString('auth_id');
      final admin = prefs.getBool('auth_is_admin') ?? false;

      if (token != null && id != null) {
        _token = token;
        _user  = {'id': id, 'name': name, 'email': email, 'isAdmin': admin};
        SecureHttpClient().setAuthToken(token);
        notifyListeners();
        if (kDebugMode) print('[Auth] Sesión restaurada: $name');
      }
    } catch (e) {
      if (kDebugMode) print('[Auth] No se pudo restaurar sesión: $e');
    }
  }

  Future<void> setSession(String token, Map<String, dynamic> user,
      {bool isNewUser = false}) async {
    _token = token;
    _user  = user;
    SecureHttpClient().setAuthToken(token);

    // Guardar en localStorage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_id',    user['id']    as String? ?? '');
      await prefs.setString('auth_name',  user['name']  as String? ?? '');
      await prefs.setString('auth_email', user['email'] as String? ?? '');
      await prefs.setBool('auth_is_admin', user['isAdmin'] as bool? ?? false);
    } catch (e) {
      if (kDebugMode) print('[Auth] Error guardando sesión: $e');
    }

    final event = AuthEvent(
      type:     isNewUser ? AuthEventType.registered : AuthEventType.loggedIn,
      userId:   user['id']   as String?,
      userName: user['name'] as String?,
    );
    if (kDebugMode) print('[AuthController] → $event');
    notifyObservers(event);
    notifyListeners();
  }

  Future<void> logout() async {
    final event = AuthEvent(
      type: AuthEventType.loggedOut,
      userId: userId, userName: userName,
    );

    _token = null;
    _user  = null;
    SecureHttpClient().clearAuthToken();

    // Limpiar localStorage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_id');
      await prefs.remove('auth_name');
      await prefs.remove('auth_email');
      await prefs.remove('auth_is_admin');
    } catch (_) {}

    notifyObservers(event);
    notifyListeners();
  }

  void notifySessionExpired() {
    _token = null;
    _user  = null;
    SecureHttpClient().clearAuthToken();
    notifyObservers(AuthEvent(type: AuthEventType.sessionExpired));
    notifyListeners();
  }
}
