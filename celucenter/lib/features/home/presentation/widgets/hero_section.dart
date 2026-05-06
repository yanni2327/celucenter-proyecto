import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class _HeroCell {
  final String emoji;
  final String label;
  final Color bgColor;
  final bool lightText;
  const _HeroCell(this.emoji, this.label, this.bgColor, this.lightText);
}

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  bool _primaryHovered   = false;
  bool _secondaryHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return ColoredBox(
        color: AppColors.dark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLeft(),
            const SizedBox(height: 260, child: _HeroRight()),
          ],
        ),
      );
    }

    // Desktop: altura fija para que Row tenga constraints acotados
    return SizedBox(
      height: 420,
      child: ColoredBox(
        color: AppColors.dark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildLeft()),
            const Expanded(child: _HeroRight()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeft() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.g5.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.g5.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.g5, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Nueva temporada 2025',
                  style: AppTextStyles.heroTag()),
            ]),
          ),
          const SizedBox(height: 14),

          // Título
          RichText(
            text: TextSpan(
              style: AppTextStyles.heroTitle(fontSize: 40),
              children: const [
                TextSpan(text: 'Tecnología\nque '),
                TextSpan(text: 'cambia',
                    style: TextStyle(color: AppColors.g5)),
                TextSpan(text: '\ntu mundo'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subtítulo
          Text(
            'Smartphones, computadoras y accesorios de\n'
            'última generación. Envío rápido, garantía real.',
            style: AppTextStyles.heroSub(),
          ),
          const SizedBox(height: 18),

          // CTAs
          Row(children: [
            _HoverButton(
              label: 'Ver catálogo',
              hovered: _primaryHovered,
              onEnter: () => setState(() => _primaryHovered = true),
              onExit:  () => setState(() => _primaryHovered = false),
              hoveredColor: AppColors.g2,
              defaultColor: AppColors.primary,
              textColor: AppColors.white,
              borderColor: Colors.transparent,
            ),
            const SizedBox(width: 12),
            _HoverButton(
              label: 'Nuestras ofertas',
              hovered: _secondaryHovered,
              onEnter: () => setState(() => _secondaryHovered = true),
              onExit:  () => setState(() => _secondaryHovered = false),
              hoveredColor: const Color(0xFF333333),
              defaultColor: Colors.transparent,
              textColor: const Color(0xFFCCCCCC),
              borderColor: const Color(0xFF444444),
            ),
          ]),
        ],
      ),
    );
  }
}

class _HoverButton extends StatelessWidget {
  final String label;
  final bool hovered;
  final VoidCallback onEnter, onExit;
  final Color hoveredColor, defaultColor, textColor, borderColor;

  const _HoverButton({
    required this.label,
    required this.hovered,
    required this.onEnter,
    required this.onExit,
    required this.hoveredColor,
    required this.defaultColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit:  (_) => onExit(),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          decoration: BoxDecoration(
            color: hovered ? hoveredColor : defaultColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor),
          ),
          child: Text(label,
              style: AppTextStyles.btnLabel()
                  .copyWith(color: textColor)),
        ),
      ),
    );
  }
}

class _HeroRight extends StatelessWidget {
  static const _cells = [
    _HeroCell('📱', 'Smartphones', AppColors.darkCard,  false),
    _HeroCell('💻', 'Laptops',     AppColors.darkCard2, false),
    _HeroCell('🎧', 'Audio',       AppColors.darkCard3, false),
    _HeroCell('⚡', 'Componentes', AppColors.primary,   true),
  ];

  const _HeroRight();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Row(children: [
          Expanded(child: _cell(_cells[0])),
          const SizedBox(width: 2),
          Expanded(child: _cell(_cells[1])),
        ])),
        const SizedBox(height: 2),
        Expanded(child: Row(children: [
          Expanded(child: _cell(_cells[2])),
          const SizedBox(width: 2),
          Expanded(child: _cell(_cells[3])),
        ])),
      ],
    );
  }

  Widget _cell(_HeroCell c) {
    return ColoredBox(
      color: c.bgColor,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(c.emoji, style: const TextStyle(fontSize: 34)),
        const SizedBox(height: 6),
        Text(c.label.toUpperCase(),
            style: AppTextStyles.body(
              fontSize: 10,
              color: c.lightText
                  ? AppColors.white.withOpacity(0.9)
                  : const Color(0xFF666666),
              weight: FontWeight.w500,
            ).copyWith(letterSpacing: 1.0)),
      ]),
    );
  }
}
