import 'package:flutter/material.dart';
import 'input_validator.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Widget que muestra la fortaleza de la contraseña en tiempo real.
/// Se usa en el formulario de registro debajo del campo de contraseña.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = InputValidator.checkStrength(password);
    final (color, label, filled) = switch (strength) {
      PasswordStrength.weak   => (const Color(0xFFE53935), 'Débil',   1),
      PasswordStrength.medium => (const Color(0xFFFFA726), 'Regular', 2),
      PasswordStrength.strong => (AppColors.primary,       'Fuerte',  3),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de indicador
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < filled ? color : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'Contraseña $label',
            style: AppTextStyles.body(fontSize: 11, color: color),
          ),
          // Requisitos
          const SizedBox(height: 6),
          ..._buildRequirements(password),
        ],
      ),
    );
  }

  List<Widget> _buildRequirements(String pw) {
    final requirements = [
      (pw.length >= 8,                            'Mínimo 8 caracteres'),
      (pw.contains(RegExp(r'[A-Z]')),             'Al menos una mayúscula'),
      (pw.contains(RegExp(r'[0-9]')),             'Al menos un número'),
      (pw.contains(RegExp(r'[!@#$%^&*()_+]')), 'Al menos un carácter especial'),
    ];

    return requirements.map((req) {
      final (met, label) = req;
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 12,
              color: met ? AppColors.primary : AppColors.midGray,
            ),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.body(
                  fontSize: 11,
                  color: met ? AppColors.primary : AppColors.midGray,
                )),
          ],
        ),
      );
    }).toList();
  }
}
