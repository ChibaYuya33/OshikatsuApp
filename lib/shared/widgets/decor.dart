import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// やわらかい影つきカード(大人可愛いの基本パーツ)。
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLight ? const Color(0xFF9A7A82) : Colors.black)
                      .withValues(alpha: isLight ? 0.08 : 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// 推し色のくすみグラデーションのヘッダー(ホームのヒーロー等)。
class GradientHeader extends StatelessWidget {
  final Color baseColor;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GradientHeader({
    super.key,
    required this.baseColor,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final m = AppTheme.muted(baseColor);
    final hsl = HSLColor.fromColor(m);
    final top = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
    final bottom =
        hsl.withLightness((hsl.lightness - 0.04).clamp(0.0, 1.0)).toColor();
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        boxShadow: [
          BoxShadow(
            color: m.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 小さな統計表示(ラベル＋値)。
class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: t.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 2),
        Text(value,
            style: t.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

/// 細い角丸プログレスバー(予算ゲージ等)。
class MiniBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const MiniBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 9,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
