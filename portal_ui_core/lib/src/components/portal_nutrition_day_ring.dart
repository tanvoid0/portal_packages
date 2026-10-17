import 'package:flutter/material.dart';

import '../format/portal_format.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_avatar_mark.dart';

/// A day's nutrition total: calories as a ring against [targetCalories], the
/// three macros under it.
///
/// With a target the ring fills to consumed / target (clamped, so the arc
/// never wraps) and the line under it reads "1,234 / 2,000 kcal"; over the
/// target the arc stays full but turns the theme's warning colour, and the
/// line says so too, so colour is never the only signal. With no target there
/// is no ring: just the consumed figure. Macro targets, when given, read as
/// "P 42/150g". Presentational only: the app maps its model to these numbers.
class PortalNutritionDayRing extends StatelessWidget {
  const PortalNutritionDayRing({
    super.key,
    required this.consumedCalories,
    this.targetCalories,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.ringColor,
  });

  final int consumedCalories;

  /// Null (or zero) is "no target set": no ring, just [consumedCalories].
  final int? targetCalories;
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;

  /// Theme `primary` when null; an over-target day uses the warning colour
  /// regardless.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final styles = tokens.textStyles;
    final fmt = PortalFormat.of(context);

    final target = (targetCalories ?? 0) > 0 ? targetCalories : null;
    final over = target != null && consumedCalories > target;
    final kcal = fmt.count(consumedCalories);
    final summary = target == null
        ? '$kcal kcal'
        : '$kcal / ${fmt.count(target)} kcal';
    final label = over ? '$summary, over target' : summary;

    String macro(String letter, double eaten, double? goal) {
      final e = eaten.round();
      return goal == null ? '$letter ${e}g' : '$letter $e/${goal.round()}g';
    }

    final macros = [
      macro('P', consumedProtein, targetProtein),
      macro('C', consumedCarbs, targetCarbs),
      macro('F', consumedFat, targetFat),
    ].join(' · ');

    return Semantics(
      container: true,
      label: '$label, $macros',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (target != null)
            PortalProgressRing(
              value: consumedCalories / target,
              size: tokens.avatarSizes.lg * 2,
              label: kcal,
              ringColor:
                  over ? PortalSemanticColors.of(context).warning : ringColor,
            ),
          if (target != null) SizedBox(height: tokens.spacing.sm),
          Text(
            target == null ? kcal : summary,
            style: target == null
                ? styles.numeric(styles.emphasized(styles.title))
                : styles.numeric(styles.caption)
                    .copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (target == null)
            Text('kcal',
                style: styles.caption.copyWith(color: cs.onSurfaceVariant)),
          SizedBox(height: tokens.spacing.xs),
          Text(
            macros,
            style: styles.numeric(styles.body).copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
