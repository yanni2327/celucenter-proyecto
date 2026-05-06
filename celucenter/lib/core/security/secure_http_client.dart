import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_security_config.dart';

/// Cliente HTTP seguro para CeluCenter.
/// Usa package:http para compatibilidad con Flutter Web.
class SecureHttpClient {
  static final SecureHttpClient _instance = SecureHttpClient._internal();
  factory SecureHttpClient() => _instance;
  SecureHttpClient._internal();

  String? _authToken;

  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken()           => _authToken = null;
  bool get isAuthenticated        => _authToken != null;

  // ── Métodos públicos ───────────────────────────────────────────────────────
  Future<ApiResponse> get(String endpoint) =>
      _request('GET', endpoint);

  Future<ApiResponse> post(String endpoint, Map<String, dynamic> body) =>
      _request('POST', endpoint, body: body);

  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) =>
      _request('PUT', endpoint, body: body);

  Future<ApiResponse> delete(String endpoint) =>
      _request('DELETE', endpoint);

  // ── Implementación ─────────────────────────────────────────────────────────
  Future<ApiResponse> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri     = Uri.parse('${AppSecurityConfig.apiBaseUrl}$endpoint');
    final headers = _buildHeaders();

    if (kDebugMode) {
      print('[HTTP] $method $uri');
    }

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(AppSecurityConfig.requestTimeout);
        case 'POST':
          response = await http
              .post(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(AppSecurityConfig.requestTimeout);
        case 'PUT':
          response = await http
              .put(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(AppSecurityConfig.requestTimeout);
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(AppSecurityConfig.requestTimeout);
        default:
          return ApiResponse.error(statusCode: 0, message: 'Método no soportado');
      }

      return _parseResponse(response);
    } on Exception catch (e) {
      if (kDebugMode) print('[HTTP] Error: $e');
      return ApiResponse.error(
        statusCode: 0,
        message: 'Error de red. Verifica que el servidor esté corriendo en '
                 'localhost:8080',
      );
    }
  }

  // ── Cabeceras ──────────────────────────────────────────────────────────────
  Map<String, String> _buildHeaders() {
    final headers = Map<String, String>.from(
        AppSecurityConfig.defaultHeaders);

    if (_authToken != null) {
      headers['Authorization'] =
          '${AppSecurityConfig.authHeaderPrefix} $_authToken';
    }
    return headers;
  }

  // ── Parseo de respuesta ────────────────────────────────────────────────────
  ApiResponse _parseResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode == 401) {
      clearAuthToken();
      return ApiResponse.error(
        statusCode: 401,
        message: 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.',
      );
    }
    if (statusCode == 429) {
      return ApiResponse.error(
        statusCode: 429,
        message: 'Demasiadas solicitudes. Espera un momento antes de continuar.',
      );
    }
    if (statusCode >= 500) {
      return ApiResponse.error(
        statusCode: statusCode,
        message: 'Error interno del servidor.',
      );
    }

    try {
      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      if (statusCode >= 400) {
        final msg = (data is Map ? data['error'] : null) as String?
            ?? 'Error ${statusCode}';
        return ApiResponse.error(statusCode: statusCode, message: msg);
      }

      return ApiResponse.success(statusCode: statusCode, data: data);
    } catch (_) {
      return ApiResponse.success(
          statusCode: statusCode, data: <String, dynamic>{});
    }
  }
}

// ── Modelo de respuesta ───────────────────────────────────────────────────
class ApiResponse {
  final int statusCode;
  final bool isSuccess;
  final dynamic data;
  final String? errorMessage;

  const ApiResponse._({
    required this.statusCode,
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success({required int statusCode, dynamic data}) =>
      ApiResponse._(statusCode: statusCode, isSuccess: true, data: data);

  factory ApiResponse.error(
          {required int statusCode, required String message}) =>
      ApiResponse._(
          statusCode: statusCode, isSuccess: false, errorMessage: message);
}
