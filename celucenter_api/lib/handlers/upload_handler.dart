import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../middleware/auth.dart';

/// Maneja la subida de imágenes a Cloudinary.
/// El frontend envía la imagen en base64 y este handler
/// la sube a Cloudinary y devuelve la URL segura.
Router uploadRouter() {
  final router = Router();

  // POST /api/admin/upload
  router.post('/', (Request req) async {
    final userId = getUserId(req);
    if (userId == null) return _json({'error': 'No autenticado'}, 401);

    final body      = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final imageB64  = body['image'] as String? ?? '';
    final folder    = body['folder'] as String? ?? 'productos';

    if (imageB64.isEmpty) {
      return _json({'error': 'Imagen requerida en base64'}, 400);
    }

    // Generar firma para Cloudinary
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = _generateSignature(timestamp, folder);

    // Subir a Cloudinary
    final response = await http.post(
      Uri.parse(AppConfig.cloudinaryUploadUrl),
      body: {
        'file':       imageB64,
        'api_key':    AppConfig.cloudinaryApiKey,
        'timestamp':  timestamp.toString(),
        'signature':  signature,
        'folder':     folder,
        'quality':    'auto',
        'fetch_format': 'auto',
      },
    );

    if (response.statusCode != 200) {
      print('[Upload] Error Cloudinary: ${response.body}');
      return _json({'error': 'Error al subir la imagen'}, 500);
    }

    final data       = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl  = data['secure_url'] as String;
    final publicId   = data['public_id']  as String;

    print('[Upload] ✅ Imagen subida: $secureUrl');
    return _json({'url': secureUrl, 'publicId': publicId});
  });

  return router;
}

/// Genera la firma requerida por Cloudinary para uploads autenticados.
String _generateSignature(int timestamp, String folder) {
  final params    = 'folder=$folder&timestamp=$timestamp';
  final toSign    = '$params${AppConfig.cloudinaryApiSecret}';
  final bytes     = utf8.encode(toSign);
  return sha1.convert(bytes).toString();
}

Response _json(dynamic data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
