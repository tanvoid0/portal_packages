import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';

/// How far through: one chunky, fully rounded track.
///
/// [value] null is indeterminate. Determinate animates from its previous
/// value on `motion.medium` (jumps under reduce-motion) and clamps to the
/// track; a value above 1 paints full in the overflow colour, so over budget
/// looks different, not just full. NaN and infinity read as 0. Re-skin with
/// [PortalProgressTheme]; the widget's own colours win.
///
/// Parts of a whole are [PortalSegmentedProgress]; one bar per step is
/// [PortalStepProgress].
class PortalProgress extends StatelessWidget {
  const PortalProgress({
    super.key,
    this.value,
    this.height,
    this.fillColor,
    this.trackColor,
    this.overflowColor,
    this.semanticLabel,
  });

  final double? value;
  final double? height;
  final Color? fillColor;
  final Color? trackColor;
  final Color? overflowColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalProgressTheme.of(context);
    final h = height ?? skin.height ?? tokens.spacing.sm;
    final track = trackColor ?? skin.trackColor ?? portal.muted;
    final fill = fillColor ?? skin.fillColor ?? portal.primary;
    final radius = BorderRadius.circular(tokens.radii.full);

    if (value == null) {
      return Semantics(
        label: semanticLabel,
        child: ClipRRect(
          borderRadius: radius,
          child: LinearProgressIndicator(
            minHeight: h,
            color: fill,
            backgroundColor: track,
          ),
        ),
      );
    }

    final safe = value!.isFinite ? value! : 0.0;
    final color = safe > 1
        ? (overflowColor ??
            skin.overflowColor ??
            PortalSemanticColors.of(context).danger)
        : fill;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: semanticLabel,
      value: '${(safe * 100).round()}%',
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: h,
          child: ColoredBox(
            color: track,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: safe.clamp(0.0, 1.0)),
              duration: reduceMotion ? Duration.zero : tokens.motion.medium,
              curve: tokens.motion.standard,
              builder: (context, v, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  // A spring curve may overshoot; the fill stays on the track.
                  widthFactor: v.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(color: color, borderRadius: radius),
                    child: SizedBox(height: h),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One slice of a [PortalSegmentedProgress].
class PortalProgressSegment {
  const PortalProgressSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Parts of a whole: one bar plus a legend in the same colours.
///
/// Not a second meter: [PortalProgress] answers "how far through", this
/// answers "what is it made of" (a pay packet split into tax, NI and take
/// home). A segment under 1.2% of the bar is still drawn so a small slice does
/// not vanish; the legend carries the real figures.
class PortalSegmentedProgress extends StatelessWidget {
  const PortalSegmentedProgress({
    super.key,
    required this.segments,
    this.height,
    this.showLegend = true,
    this.formatValue,
  });

  final List<PortalProgressSegment> segments;
  final double? height;
  final bool showLegend;

  /// Renders a segment's figure in the legend. Defaults to a percentage.
  final String Function(PortalProgressSegment segment, double share)?
      formatValue;

  static const double _minVisible = 0.012;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final h = height ??
        PortalProgressTheme.of(context).height ??
        tokens.spacing.sm;

    final visible =
        segments.where((s) => s.value.isFinite && s.value > 0).toList();
    final total = visible.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return const SizedBox.shrink();

    String describe(PortalProgressSegment s) {
      final share = s.value / total;
      return formatValue?.call(s, share) ?? '${(share * 100).round()}%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: visible.map((s) => '${s.label} ${describe(s)}').join(', '),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radii.full),
            child: SizedBox(
              height: h,
              child: Row(
                children: [
                  for (final s in visible)
                    Expanded(
                      flex: ((s.value / total).clamp(_minVisible, 1.0) * 10000)
                          .round(),
                      child: ColoredBox(color: s.color),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showLegend) ...[
          SizedBox(height: tokens.spacing.md),
          Wrap(
            spacing: tokens.spacing.lg,
            runSpacing: tokens.spacing.sm,
            children: [
              for (final s in visible)
                ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: tokens.spacing.sm,
                        height: tokens.spacing.sm,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sm),
                      Text(
                        s.label,
                        style: tokens.textStyles.caption
                            .copyWith(color: portal.onSurfaceVariant),
                      ),
                      SizedBox(width: tokens.spacing.xs),
                      Text(
                        describe(s),
                        style: tokens.textStyles
                            .numeric(tokens.textStyles.caption)
                            .copyWith(
                              color: portal.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One bar per step (cook mode, onboarding): done, current, upcoming.
///
/// The current bar is taller as well as coloured, so position never reads by
/// colour alone. With [onStepTap] each bar's hit area is `minTapTarget` tall
/// around the painted bar.
class PortalStepProgress extends StatelessWidget {
  const PortalStepProgress({
    super.key,
    required this.count,
    required this.current,
    this.isDone,
    this.onStepTap,
  });

  final int count;
  final int current;

  /// Whether step `i` is completed. Defaults to every step before [current].
  final bool Function(int i)? isDone;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalProgressTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final base = skin.height ?? tokens.spacing.xs;

    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Semantics(
              label: 'Step ${i + 1} of $count',
              selected: i == current,
              button: onStepTap != null,
              onTap: onStepTap == null ? null : () => onStepTap!(i),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onStepTap == null ? null : () => onStepTap!(i),
                child: SizedBox(
                  height: onStepTap == null ? null : tokens.minTapTarget,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: i < count - 1 ? tokens.spacing.xs : 0,
                      ),
                      child: AnimatedContainer(
                        duration:
                            reduceMotion ? Duration.zero : tokens.motion.fast,
                        height: i == current ? base * 1.5 : base,
                        decoration: BoxDecoration(
                          color: (isDone?.call(i) ?? i < current)
                              ? (skin.doneColor ??
                                  PortalSemanticColors.of(context).success)
                              : i == current
                                  ? (skin.fillColor ?? portal.primary)
                                  : (skin.trackColor ?? portal.muted),
                          borderRadius:
                              BorderRadius.circular(tokens.radii.full),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
