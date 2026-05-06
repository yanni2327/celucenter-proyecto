import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PromoBand extends StatefulWidget {
  final VoidCallback? onCtaTap;
  const PromoBand({super.key, this.onCtaTap});

  @override
  State<PromoBand> createState() => _PromoBandState();
}

class _PromoBandState extends State<PromoBand> {
  bool _btnHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: AppColors.dark,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _PromoText(),
              const SizedBox(height: 20),
              _PromoActions(
                btnHovered: _btnHovered,
                onEnter: () => setState(() => _btnHovered = true),
                onExit:  () => setState(() => _btnHovered = false),
                onTap: widget.onCtaTap,
              ),
            ])
          : Row(children: [
              Expanded(flex: 2, child: _PromoText()),
              const SizedBox(width: 20),
              Expanded(child: _PromoActions(
                btnHovered: _btnHovered,
                onEnter: () => setState(() => _btnHovered = true),
                onExit:  () => setState(() => _btnHovered = false),
                onTap: widget.onCtaTap,
              )),
            ]),
    );
  }
}

class _PromoText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
        text: TextSpan(
          style: AppTextStyles.promoTitle(),
          children: const [
            TextSpan(text: 'Escala tu negocio\ncon '),
            TextSpan(text: 'tecnología real',
                style: TextStyle(color: AppColors.g5)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Compras corporativas, facturación electrónica\n'
        'y despacho a todo el país.',
        style: AppTextStyles.body(fontSize: 13, color: const Color(0xFF888888)),
      ),
    ]);
  }
}

class _PromoActions extends StatelessWidget {
  final bool btnHovered;
  final VoidCallback onEnter, onExit;
  final VoidCallback? onTap;

  const _PromoActions({
    required this.btnHovered,
    required this.onEnter,
    required this.onExit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.g6.withOpacity(0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.g6.withOpacity(0.25)),
        ),
        child: Text('Envío gratis desde \$500.000',
            style: AppTextStyles.body(fontSize: 12, color: AppColors.g6)),
      ),
      const SizedBox(height: 14),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onEnter(),
        onExit:  (_) => onExit(),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(
              color: btnHovered ? AppColors.g2 : AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Ver catálogo completo',
                style: AppTextStyles.btnLabel(fontSize: 13)
                    .copyWith(color: AppColors.white)),
          ),
        ),
      ),
    ]);
  }
}
