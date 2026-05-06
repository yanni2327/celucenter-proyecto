import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  static const _links = [
    'Privacidad',
    'Términos',
    'Soporte',
    'PCI-DSS SAQ A',
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 26),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _FooterLogo(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _links.map(_buildLink).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  '© 2025 CeluCenter — 100% online',
                  style: AppTextStyles.footerCopy(),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FooterLogo(),
                Row(
                  children: _links
                      .map((l) => Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: _buildLink(l),
                          ))
                      .toList(),
                ),
                Text(
                  '© 2025 CeluCenter — 100% online',
                  style: AppTextStyles.footerCopy(),
                ),
              ],
            ),
    );
  }

  Widget _buildLink(String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Text(label, style: AppTextStyles.footerLink()),
      ),
    );
  }
}

class _FooterLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Celu',
            style: AppTextStyles.logoText(fontSize: 16),
          ),
          TextSpan(
            text: 'Center',
            style: AppTextStyles.logoText(fontSize: 16)
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
