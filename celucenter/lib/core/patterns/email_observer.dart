import 'package:flutter/foundation.dart';
import 'observer.dart';
import 'auth_events.dart';
import '../security/secure_http_client.dart';
import '../state/auth_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EmailObserver — Observador de correos transaccionales
//
//  Escucha eventos de AuthController y llama al backend para
//  enviar correos reales via SendGrid.
//
//  Flujo:
//  AuthController.setSession() → emite AuthEvent(registered)
//  → EmailObserver.onEvent()
//  → POST /api/notificaciones/email
//  → Backend → SendGrid API
//  → Correo llega al Gmail del usuario
// ─────────────────────────────────────────────────────────────────────────────
class EmailObserver implements Observer<AuthEvent> {
  final SecureHttpClient _http = SecureHttpClient();

  EmailObserver();

  @override
  void onEvent(AuthEvent event) {
    // Solo enviar correo al registrarse
    if (event.type != AuthEventType.registered) return;

    // Obtener el email del usuario desde AuthController
    final userEmail = AuthController().userEmail;
    if (userEmail == null || userEmail.isEmpty) {
      if (kDebugMode) print('[EmailObserver] ⚠️ No hay email disponible');
      return;
    }

    if (kDebugMode) {
      print('[EmailObserver] 📧 Enviando correo de bienvenida a $userEmail');
    }

    // Llamada asíncrona — no bloquea la UI
    _sendWelcomeEmail(
      toEmail:  userEmail,
      userName: event.userName ?? '',
    );
  }

  Future<void> _sendWelcomeEmail({
    required String toEmail,
    required String userName,
  }) async {
    final response = await _http.post('/api/notificaciones/email', {
      'type':     'bienvenida',
      'toEmail':  toEmail,
      'userName': userName,
    });

    if (kDebugMode) {
      if (response.isSuccess) {
        print('[EmailObserver] ✅ Correo de bienvenida enviado a $toEmail');
      } else {
        print('[EmailObserver] ❌ Error: ${response.errorMessage}');
      }
    }
  }
}
