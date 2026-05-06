import 'package:shelf/shelf.dart';

/// Middleware CORS para desarrollo local.
/// En producción Nginx + Cloudflare manejan CORS.
Middleware corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers':
        'Content-Type, Authorization, X-CSRF-Token, X-Client-App',
    'Access-Control-Max-Age': '86400',
  };

  return (Handler inner) {
    return (Request request) async {
      // Pre-flight OPTIONS
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await inner(request);
      return response.change(headers: headers);
    };
  };
}
