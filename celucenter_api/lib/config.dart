class AppConfig {
  AppConfig._();

  static const int    port       = 8080;
  static const String jwtSecret  =
      'celucenter_dev_secret_2025_cambiar_en_produccion';
  static const Duration tokenExpiry = Duration(hours: 1);
  static const String webhookSecret =
      'webhook_dev_secret_cambiar_en_produccion';

  // ── Cloudinary ─────────────────────────────────────────────────────────────
  static const String cloudinaryCloudName = 'dcsc2qlcs';
  static const String cloudinaryApiKey    = '724993147127646';
  static const String cloudinaryApiSecret = 'uiVmTFTyyTvRQVztJjRPEmwsJfY';
  static const String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/dcsc2qlcs/image/upload';

  // ── Admin por defecto ──────────────────────────────────────────────────────
  static const String adminEmail    = 'admin@celucenter.com';
  static const String adminPassword = 'Admin123!';
  static const String adminName     = 'Administrador';
}
