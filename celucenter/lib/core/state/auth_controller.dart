import 'package:flutter/foundation.dart';
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

  void setSession(String token, Map<String, dynamic> user,
      {bool isNewUser = false}) {
    _token = token;
    _user  = user;
    SecureHttpClient().setAuthToken(token);

    final event = AuthEvent(
      type:     isNewUser ? AuthEventType.registered : AuthEventType.loggedIn,
      userId:   user['id']   as String?,
      userName: user['name'] as String?,
    );

    if (kDebugMode) print('[AuthController] → $event');
    notifyObservers(event);
    notifyListeners();
  }

  void logout() {
    final event = AuthEvent(
      type: AuthEventType.loggedOut,
      userId: userId, userName: userName,
    );
    _token = null;
    _user  = null;
    SecureHttpClient().clearAuthToken();
    if (kDebugMode) print('[AuthController] → $event');
    notifyObservers(event);
    notifyListeners();
  }

  void notifySessionExpired() {
    _token = null;
    _user  = null;
    SecureHttpClient().clearAuthToken();
    final event = AuthEvent(type: AuthEventType.sessionExpired);
    notifyObservers(event);
    notifyListeners();
  }
}
