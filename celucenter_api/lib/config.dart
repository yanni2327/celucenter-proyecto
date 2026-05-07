import 'dart:io';

class AppConfig {
  AppConfig._();

  static int get port =>
      int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  static const String jwtSecret = String.fromEnvironment(
    'JWT_SECRET', defaultValue: 'celucenter_dev_secret_2025');

  static const Duration tokenExpiry = Duration(hours: 1);

  static const String webhookSecret = String.fromEnvironment(
    'WEBHOOK_SECRET', defaultValue: 'webhook_dev_secret');

  /// URL de conexión a PostgreSQL (Neon).
  /// En Render → Environment Variables → DATABASE_URL
  static String get databaseUrl =>
      Platform.environment['DATABASE_URL'] ??
      'postgresql://neondb_owner:npg_qwI6TSW0aBrp@ep-flat-field-aprc92m1-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require';

  // Cloudinary
  static const String cloudinaryCloudName = 'dcsc2qlcs';
  static const String cloudinaryApiKey    = '724993147127646';
  static const String cloudinaryApiSecret = 'uiVmTFTyyTvRQVztJjRPEmwsJfY';
  static const String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/dcsc2qlcs/image/upload';

  // SendGrid
  static String get sendgridApiKey =>
      Platform.environment['SENDGRID_API_KEY'] ?? '';
  static const String sendgridFrom = 'celucenterwb@gmail.com';

  // Admin por defecto
  static const String adminEmail    = 'admin@celucenter.com';
  static const String adminPassword = 'Admin123!';
  static const String adminName     = 'Administrador';
}
