import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  static const _stats = [
    _Stat('+4.200', 'Productos disponibles'),
    _Stat('24h', 'Despacho express'),
    _Stat('99.9%', 'Disponibilidad del sitio'),
    _Stat('+18K', 'Clientes satisfechos'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.g9,
        border: Border(
          bottom: BorderSide(color: AppColors.g8),
        ),
      ),
      child: isMobile
          ? Wrap(
              children: _stats
                  .map((s) => _StatItem(stat: s, isLast: false))
                  .toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stats.length, (i) {
                return _StatItem(
                  stat: _stats[i],
                  isLast: i == _stats.length - 1,
                );
              }),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final _Stat stat;
  final bool isLast;

  const _StatItem({required this.stat, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                right: BorderSide(color: AppColors.g8),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stat.number, style: AppTextStyles.statNumber()),
          const SizedBox(height: 2),
          Text(stat.label, style: AppTextStyles.statLabel()),
        ],
      ),
    );
  }
}

class _Stat {
  final String number;
  final String label;
  const _Stat(this.number, this.label);
}
