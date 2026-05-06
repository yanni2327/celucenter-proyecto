import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../middleware/auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EmailHandler — Envío de correos via SendGrid
//
//  Recibe la solicitud del EmailObserver del frontend,
//  construye el HTML del correo y lo envía via SendGrid API.
// ─────────────────────────────────────────────────────────────────────────────

// API key cargada desde variable de entorno — nunca hardcodear en el código
import 'dart:io' show Platform;

String get _sendgridApiKey =>
    Platform.environment['SENDGRID_API_KEY'] ??
    const String.fromEnvironment('SENDGRID_API_KEY', defaultValue: '');
const _fromEmail = 'celucenterwb@gmail.com';
const _fromName  = 'CeluCenter';

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

    final success = await _sendEmail(
      to:      toEmail,
      subject: subject,
      html:    html,
    );

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

// ── Llamada a la API de SendGrid ───────────────────────────────────────────
Future<bool> _sendEmail({
  required String to,
  required String subject,
  required String html,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $_sendgridApiKey',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [{'email': to}],
          }
        ],
        'from':    {'email': _fromEmail, 'name': _fromName},
        'subject': subject,
        'content': [
          {'type': 'text/html', 'value': html}
        ],
      }),
    );

    // SendGrid retorna 202 cuando el correo se acepta para envío
    return response.statusCode == 202;
  } catch (e) {
    print('[Email] Error llamando SendGrid: $e');
    return false;
  }
}

// ── Template HTML de bienvenida ────────────────────────────────────────────
String _templateBienvenida(String userName) => '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Bienvenido a CeluCenter</title>
</head>
<body style="margin:0;padding:0;background:#f5f5f5;font-family:'Helvetica Neue',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f5;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="580" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:12px;overflow:hidden;
                      box-shadow:0 2px 8px rgba(0,0,0,0.08);">

          <!-- Header verde -->
          <tr>
            <td style="background:#419F00;padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:28px;
                         font-weight:800;letter-spacing:-0.5px;">
                Celu<span style="color:#e3f59b;">Center</span>
              </h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.8);font-size:13px;">
                Tecnología que cambia tu mundo
              </p>
            </td>
          </tr>

          <!-- Contenido principal -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h2 style="margin:0 0 16px;color:#1a1a1a;font-size:22px;font-weight:700;">
                ¡Hola, $userName! 👋
              </h2>
              <p style="margin:0 0 16px;color:#555555;font-size:15px;line-height:1.6;">
                Tu cuenta en <strong>CeluCenter</strong> ha sido creada exitosamente.
                Ya puedes explorar nuestro catálogo de smartphones, computadoras y accesorios
                de última generación.
              </p>
              <p style="margin:0 0 28px;color:#555555;font-size:15px;line-height:1.6;">
                Te esperan los mejores productos con precios increíbles y envío rápido a
                todo el país.
              </p>

              <!-- Botón CTA -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background:#419F00;border-radius:8px;">
                    <a href="http://localhost:50673"
                       style="display:inline-block;padding:14px 32px;
                              color:#ffffff;font-size:15px;font-weight:600;
                              text-decoration:none;letter-spacing:0.2px;">
                      Explorar catálogo →
                    </a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Características -->
          <tr>
            <td style="padding:0 40px 32px;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="33%" style="padding:16px;background:#f9fdf4;
                                          border-radius:8px;text-align:center;">
                    <div style="font-size:24px;margin-bottom:8px;">📱</div>
                    <div style="font-size:12px;color:#419F00;font-weight:600;">
                      +4.200 productos
                    </div>
                  </td>
                  <td width="4%"></td>
                  <td width="33%" style="padding:16px;background:#f9fdf4;
                                          border-radius:8px;text-align:center;">
                    <div style="font-size:24px;margin-bottom:8px;">🚀</div>
                    <div style="font-size:12px;color:#419F00;font-weight:600;">
                      Envío en 24h
                    </div>
                  </td>
                  <td width="4%"></td>
                  <td width="33%" style="padding:16px;background:#f9fdf4;
                                          border-radius:8px;text-align:center;">
                    <div style="font-size:24px;margin-bottom:8px;">🔒</div>
                    <div style="font-size:12px;color:#419F00;font-weight:600;">
                      Pago seguro
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background:#f9fdf4;padding:24px 40px;text-align:center;
                       border-top:1px solid #e8f5d6;">
              <p style="margin:0 0 6px;color:#888888;font-size:12px;">
                Recibiste este correo porque creaste una cuenta en CeluCenter.
              </p>
              <p style="margin:0;color:#888888;font-size:12px;">
                © 2025 CeluCenter — 100% online
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
