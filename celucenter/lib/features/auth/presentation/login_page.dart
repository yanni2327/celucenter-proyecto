import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/app_security_config.dart';
import '../../../core/security/input_validator.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _rateLimiter  = RateLimiter();
  final _httpClient   = SecureHttpClient();
  final _auth         = AuthController();

  bool _obscurePassword = true;
  bool _loading         = false;
  String? _serverError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rateLimiter.isLocked) {
      setState(() => _serverError = _rateLimiter.lockMessage);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() { _loading = true; _serverError = null; });

    final email    = InputValidator.sanitize(_emailCtrl.text.trim().toLowerCase());
    final password = _passwordCtrl.text;

    final response = await _httpClient.post('/api/auth/login', {
      'email': email, 'password': password,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (response.isSuccess) {
      _rateLimiter.reset();
      final data  = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user  = data['user'] as Map<String, dynamic>;
      _auth.setSession(token, user);
      if (mounted) context.go(AppRoutes.home);
    } else {
      _rateLimiter.registerFailedAttempt();
      setState(() {
        _serverError = response.statusCode == 401
            ? 'Usuario o contraseña incorrectos.'
            : response.errorMessage ?? 'Error al iniciar sesión.';
      });
      _passwordCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CeluLogo(),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Iniciar sesión',
                          style: AppTextStyles.sectionTitle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text('Bienvenido de nuevo',
                          style: AppTextStyles.body(fontSize: 14, color: AppColors.midGray)),
                      const SizedBox(height: 28),

                      const _FieldLabel('Correo electrónico'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        maxLength: AppSecurityConfig.maxTextFieldLength,
                        validator: InputValidator.email,
                        decoration: _deco('tucorreo@ejemplo.com', Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Contraseña'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        maxLength: AppSecurityConfig.passwordMaxLength,
                        validator: InputValidator.passwordLogin,
                        decoration: _deco('••••••••', Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18, color: AppColors.midGray,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            )),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('¿Olvidaste tu contraseña?',
                              style: AppTextStyles.body(fontSize: 12, color: AppColors.primary)),
                        ),
                      ),

                      if (_serverError != null) ...[
                        const SizedBox(height: 4),
                        _ErrorBanner(message: _serverError!),
                      ],

                      if (!_rateLimiter.isLocked &&
                          _rateLimiter.attemptsLeft < AppSecurityConfig.maxLoginAttempts &&
                          _rateLimiter.attemptsLeft > 0)
                        _WarningBanner(
                            message: 'Te quedan ${_rateLimiter.attemptsLeft} intento(s).'),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading || _rateLimiter.isLocked ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Iniciar sesión',
                                  style: AppTextStyles.btnLabel(fontSize: 15)
                                      .copyWith(color: AppColors.white)),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o', style: AppTextStyles.body(fontSize: 12, color: AppColors.midGray)),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 16),

                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('¿No tienes cuenta?',
                            style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: Text('Regístrate',
                              style: AppTextStyles.body(fontSize: 13,
                                  color: AppColors.primary, weight: FontWeight.w500)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.midGray),
        suffixIcon: suffix,
        counterText: '',
        filled: true, fillColor: AppColors.surface,
      );
}

class _CeluLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(children: [
      TextSpan(text: 'Celu', style: AppTextStyles.logoText(fontSize: 22)),
      TextSpan(text: 'Center', style: AppTextStyles.logoText(fontSize: 22)
          .copyWith(color: AppColors.primary)),
    ]),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.body(fontSize: 13, weight: FontWeight.w500, color: AppColors.dark));
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFEECEC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE57373))),
    child: Row(children: [
      const Icon(Icons.error_outline, size: 16, color: Color(0xFFD32F2F)),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: AppTextStyles.body(fontSize: 13, color: const Color(0xFFD32F2F)))),
    ]),
  );
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFFB300))),
    child: Row(children: [
      const Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xFFF57F17)),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: AppTextStyles.body(fontSize: 13, color: const Color(0xFFF57F17)))),
    ]),
  );
}
