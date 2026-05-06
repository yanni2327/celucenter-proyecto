import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../middleware/auth.dart';

const _fromEmail = 'celucenterwb@gmail.com';
const _fromName  = 'CeluCenter';

// API key cargada desde variable de entorno — nunca hardcodear en el código
String get _sendgridApiKey =>
    Platform.environment['SENDGRID_API_KEY'] ?? '';

Router emailRouter() {
  final router = Router();

  // POST /api/notificaciones/email
  router.post('/email', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final body     = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final type     = body['type']     as String? ?? '';
    final toEmail  = body['toEmail']  as String? ?? '';
    final userName = body['userName'] as String? ?? '';

    if (toEmail.isEmpty) {
      return _json({'error': 'Email destinatario requerido'}, 400);
    }

    String subject;
    String html;

    switch (type) {
      case 'bienvenida':
        subject = '¡Bienvenido a CeluCenter, $userName!';
        html    = _templateBienvenida(userName);
      default:
        return _json({'error': 'Tipo de correo no reconocido: $type'}, 400);
    }

    final success = await _sendEmail(to: toEmail, subject: subject, html: html);

    if (success) {
      print('[Email] ✅ Correo "$type" enviado a $toEmail');
      return _json({'message': 'Correo enviado correctamente', 'to': toEmail});
    } else {
      print('[Email] ❌ Error enviando correo a $toEmail');
      return _json({'error': 'Error al enviar el correo'}, 500);
    }
  });

  return router;
}

Future<bool> _sendEmail({
  required String to,
  required String subject,
  required String html,
}) async {
  final apiKey = _sendgridApiKey;
  if (apiKey.isEmpty) {
    print('[Email] ⚠️ SENDGRID_API_KEY no configurada');
    return false;
  }

  try {
    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'personalizations': [{'to': [{'email': to}]}],
        'from':    {'email': _fromEmail, 'name': _fromName},
        'subject': subject,
        'content': [{'type': 'text/html', 'value': html}],
      }),
    );
    return response.statusCode == 202;
  } catch (e) {
    print('[Email] Error llamando SendGrid: $e');
    return false;
  }
}

String _templateBienvenida(String userName) => '''
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f5f5f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 0;">
    <tr><td align="center">
      <table width="580" cellpadding="0" cellspacing="0"
             style="background:#fff;border-radius:12px;overflow:hidden;">
        <tr><td style="background:#419F00;padding:32px 40px;text-align:center;">
          <h1 style="margin:0;color:#fff;font-size:28px;font-weight:800;">
            Celu<span style="color:#e3f59b;">Center</span>
          </h1>
        </td></tr>
        <tr><td style="padding:40px;">
          <h2 style="color:#1a1a1a;">¡Hola, $userName! 👋</h2>
          <p style="color:#555;font-size:15px;line-height:1.6;">
            Tu cuenta en <strong>CeluCenter</strong> ha sido creada exitosamente.
            Ya puedes explorar nuestro catálogo de smartphones, computadoras y accesorios.
          </p>
          <table cellpadding="0" cellspacing="0" style="margin-top:24px;">
            <tr><td style="background:#419F00;border-radius:8px;">
              <a href="https://celucenter.onrender.com"
                 style="display:inline-block;padding:14px 32px;color:#fff;
                        font-size:15px;font-weight:600;text-decoration:none;">
                Explorar catálogo →
              </a>
            </td></tr>
          </table>
        </td></tr>
        <tr><td style="background:#f9fdf4;padding:20px 40px;text-align:center;">
          <p style="margin:0;color:#888;font-size:12px;">
            © 2025 CeluCenter — 100% online
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>
''';

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
