import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/app_security_config.dart';
import '../../../core/security/input_validator.dart';
import '../../../core/security/password_strength_indicator.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _http         = SecureHttpClient();
  final _auth         = AuthController();

  bool    _obscurePassword = true;
  bool    _obscureConfirm  = true;
  bool    _acceptedTerms   = false;
  bool    _loading         = false;
  bool    _success         = false;
  String? _serverError;
  String  _passwordValue   = '';

  @override
  void dispose() {
    _nameCtrl.dispose();  _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      setState(() => _serverError = 'Debes aceptar los términos y condiciones.');
      return;
    }

    setState(() { _loading = true; _serverError = null; });

    final name  = InputValidator.sanitize(_nameCtrl.text.trim());
    final email = InputValidator.sanitize(_emailCtrl.text.trim().toLowerCase());
    final phone = _phoneCtrl.text.trim().isEmpty ? null
        : _phoneCtrl.text.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    final response = await _http.post('/api/auth/register', {
      'name': name, 'email': email, 'password': _passwordCtrl.text,
      if (phone != null) 'phone': phone,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (response.isSuccess) {
      final data  = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user  = data['user'] as Map<String, dynamic>;
      _auth.setSession(token, user, isNewUser: true);
      setState(() => _success = true);
    } else {
      setState(() {
        _serverError = response.statusCode == 409
            ? 'Ya existe una cuenta con ese correo electrónico.'
            : response.errorMessage ?? 'Error al crear la cuenta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _success ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: const BoxDecoration(color: AppColors.g9, shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.primary)),
      const SizedBox(height: 20),
      Text('¡Cuenta creada!', style: AppTextStyles.sectionTitle(fontSize: 22)),
      const SizedBox(height: 8),
      Text('Bienvenido, ${_auth.userName ?? ''}.',
          style: AppTextStyles.body(fontSize: 14, color: AppColors.midGray)),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Ir al inicio',
              style: AppTextStyles.btnLabel(fontSize: 15)
                  .copyWith(color: AppColors.white)),
        ),
      ),
    ]);
  }

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Logo(),
      const SizedBox(height: 32),
      Text('Crear cuenta', style: AppTextStyles.sectionTitle(fontSize: 22)),
      const SizedBox(height: 4),
      Text('Es gratis. Sin tarjeta de crédito.',
          style: AppTextStyles.body(fontSize: 14, color: AppColors.midGray)),
      const SizedBox(height: 28),

      Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _L('Nombre completo'), const SizedBox(height: 6),
          TextFormField(controller: _nameCtrl, maxLength: 50,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: InputValidator.fullName,
              decoration: _d('Tu nombre y apellido', Icons.person_outline)),
          const SizedBox(height: 14),

          _L('Correo electrónico'), const SizedBox(height: 6),
          TextFormField(controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress, autocorrect: false,
              maxLength: AppSecurityConfig.maxTextFieldLength,
              validator: InputValidator.email,
              decoration: _d('tucorreo@ejemplo.com', Icons.email_outlined)),
          const SizedBox(height: 14),

          _L('Celular (opcional)'), const SizedBox(height: 6),
          TextFormField(controller: _phoneCtrl,
              keyboardType: TextInputType.phone, maxLength: 13,
              validator: InputValidator.phone,
              decoration: _d('300 123 4567', Icons.phone_outlined)),
          const SizedBox(height: 14),

          _L('Contraseña'), const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            maxLength: AppSecurityConfig.passwordMaxLength,
            validator: InputValidator.password,
            onChanged: (v) => setState(() => _passwordValue = v),
            decoration: _d('••••••••', Icons.lock_outline,
                suffix: _Eye(obscure: _obscurePassword,
                    onToggle: () => setState(
                        () => _obscurePassword = !_obscurePassword))),
          ),
          if (_passwordValue.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 6),
                child: PasswordStrengthIndicator(password: _passwordValue)),

          const SizedBox(height: 14),
          _L('Confirmar contraseña'), const SizedBox(height: 6),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            maxLength: AppSecurityConfig.passwordMaxLength,
            validator: InputValidator.passwordConfirm(_passwordCtrl.text),
            decoration: _d('••••••••', Icons.lock_outline,
                suffix: _Eye(obscure: _obscureConfirm,
                    onToggle: () => setState(
                        () => _obscureConfirm = !_obscureConfirm))),
          ),
          const SizedBox(height: 6),

          // Términos
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(width: 20, height: 20,
              child: Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              )),
            const SizedBox(width: 10),
            Expanded(child: RichText(text: TextSpan(
              style: AppTextStyles.body(fontSize: 12, color: AppColors.midGray),
              children: [
                const TextSpan(text: 'Acepto los '),
                TextSpan(text: 'términos y condiciones',
                    style: AppTextStyles.body(fontSize: 12,
                        color: AppColors.primary, weight: FontWeight.w500)),
                const TextSpan(text: ' y la '),
                TextSpan(text: 'política de privacidad',
                    style: AppTextStyles.body(fontSize: 12,
                        color: AppColors.primary, weight: FontWeight.w500)),
              ],
            ))),
          ]),

          if (_serverError != null) ...[
            const SizedBox(height: 12),
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEECEC),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFE57373))),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 16, color: Color(0xFFD32F2F)),
                const SizedBox(width: 8),
                Expanded(child: Text(_serverError!, style: AppTextStyles.body(
                    fontSize: 13, color: const Color(0xFFD32F2F)))),
              ])),
          ],

          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Crear cuenta', style: AppTextStyles.btnLabel(fontSize: 15)
                      .copyWith(color: AppColors.white)),
            ),
          ),

          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o', style: AppTextStyles.body(
                    fontSize: 12, color: AppColors.midGray))),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('¿Ya tienes cuenta?', style: AppTextStyles.body(
                fontSize: 13, color: AppColors.midGray)),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text('Inicia sesión', style: AppTextStyles.body(
                  fontSize: 13, color: AppColors.primary, weight: FontWeight.w500)),
            ),
          ]),
        ]),
      ),
    ]);
  }

  InputDecoration _d(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
    hintText: hint, filled: true, fillColor: AppColors.surface,
    prefixIcon: Icon(icon, size: 18, color: AppColors.midGray),
    suffixIcon: suffix, counterText: '',
  );
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(children: [
      TextSpan(text: 'Celu', style: AppTextStyles.logoText(fontSize: 22)),
      TextSpan(text: 'Center', style: AppTextStyles.logoText(fontSize: 22)
          .copyWith(color: AppColors.primary)),
    ]),
  );
}

class _L extends StatelessWidget {
  final String text;
  const _L(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.body(fontSize: 13, weight: FontWeight.w500, color: AppColors.dark));
}

class _Eye extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;
  const _Eye({required this.obscure, required this.onToggle});
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 18, color: AppColors.midGray),
    onPressed: onToggle,
  );
}
