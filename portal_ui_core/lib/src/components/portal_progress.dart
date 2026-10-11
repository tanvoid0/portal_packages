import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_prompt.dart';
import 'portal_skeleton.dart';

/// A budget meter's sentiment by how much of it is used: positive under 75%,
/// warning to the limit, negative over it. [value] is spent over budget, 1.0
/// at the line.
// ponytail: thresholds fixed at 75% and 100%; make them tokens if a second app wants other bands.
PortalSentiment portalBudgetSentiment(double value) => value > 1
    ? PortalSentiment.negative
    : value >= .75
        ? PortalSentiment.warning
        : PortalSentiment.positive;

/// The colour a [PortalSentiment] reads as; neutral is [neutral] rather than
/// the scale's `onSurfaceVariant`, so a meter can carry its own figure colour.
Color _sentimentColor(BuildContext context, PortalSentiment s, Color neutral) =>
    s == PortalSentiment.neutral ? neutral : s.base(context);

/// How far through: one chunky, fully rounded track.
///
/// [value] null is indeterminate. Determinate animates from its previous
/// value on `motion.medium` (jumps under reduce-motion) and clamps to the
/// track; a value above 1 paints full in the overflow colour, so over budget
/// looks different, not just full. NaN and infinity read as 0. Re-skin with
/// [PortalProgressTheme]; the widget's own colours win.
///
/// With [sentiment] the fill takes its colour (see [portalBudgetSentiment])
/// and a value above 1 stops clamping: the bar rescales so the whole spend
/// fits, the part up to the limit in the warning colour, the overspend in the
/// overflow colour, and a tick where the limit sits. [startLabel] and
/// [endLabel] sit under the bar; only the end label's first word (its
/// figure) takes the sentiment colour.
///
/// [PortalProgress.banded] is a scale in ranges instead (BMI's Under /
/// Healthy / Over / Obese).
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
    this.sentiment,
    this.startLabel,
    this.endLabel,
    this.semanticValue,
  })  : _skeleton = false,
        bands = null,
        bandLabels = null;

  /// A scale in ranges: the track split at [bands] (0..1 stops), the band
  /// holding [value] in the fill and the rest on the track, and a marker at
  /// [value] -- never a fill that reads as "done". [bandLabels] (one per band)
  /// sit centred under the bands; [startLabel] / [endLabel] name the scale's
  /// ends ('15', '35'). [value] is 0..1 along the scale and clamps to it; say
  /// the range in [semanticValue] ('Healthy'), the percentage means little.
  const PortalProgress.banded({
    super.key,
    required double this.value,
    required List<double> this.bands,
    this.bandLabels,
    this.height,
    this.fillColor,
    this.trackColor,
    this.semanticLabel,
    this.semanticValue,
    this.startLabel,
    this.endLabel,
  })  : _skeleton = false,
        overflowColor = null,
        sentiment = null;

  /// The meter while it loads: its track, and a bar at the labels' line
  /// height for each label the data has. Hidden from screen readers.
  const PortalProgress.skeleton({
    super.key,
    this.height,
    bool hasStartLabel = true,
    bool hasEndLabel = true,
  })  : _skeleton = true,
        value = 0,
        fillColor = null,
        trackColor = null,
        overflowColor = null,
        semanticLabel = null,
        semanticValue = null,
        sentiment = null,
        bands = null,
        bandLabels = null,
        startLabel = hasStartLabel ? '' : null,
        endLabel = hasEndLabel ? '' : null;

  final double? value;
  final double? height;
  final Color? fillColor;
  final Color? trackColor;
  final Color? overflowColor;
  final String? semanticLabel;

  /// What a screen reader hears for the value when the labels abbreviate
  /// ("about 1 minute left" for "About 1 min left"); else the labels, or the
  /// percentage with none.
  final String? semanticValue;

  /// [PortalProgress.banded] only: the stops between bands, and a name per band.
  final List<double>? bands;
  final List<String>? bandLabels;

  /// Colours the fill (over [fillColor]) and opts into the over-limit
  /// rescale; null keeps the plain bar. Neutral is the normal fill.
  final PortalSentiment? sentiment;

  /// Captions under the bar, start and end. With either, a screen reader
  /// hears them as the value in place of the percentage.
  final String? startLabel;
  final String? endLabel;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    if (_skeleton) return _buildSkeleton(context);
    final bar = _buildBar(context);
    if (startLabel == null && endLabel == null) return bar;

    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final s = sentiment;
    final cap = tokens.textStyles
        .numeric(tokens.textStyles.caption)
        .copyWith(color: portal.onSurfaceVariant);
    final end = endLabel;
    final space = end?.indexOf(' ') ?? -1;
    final figure = s == null || s == PortalSentiment.neutral
        ? null
        : cap.copyWith(
            color: _sentimentColor(context, s, portal.onSurfaceVariant));

    return Semantics(
      container: true,
      label: semanticLabel,
      value: semanticValue ??
          [startLabel, endLabel].whereType<String>().join(', '),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar,
            SizedBox(height: tokens.spacing.sm),
            Row(
              mainAxisAlignment: startLabel == null
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (startLabel case final start?)
                  Flexible(child: Text(start, style: cap)),
                if (startLabel != null && end != null)
                  SizedBox(width: tokens.spacing.sm),
                if (end != null)
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: cap,
                        children: [
                          TextSpan(
                            text: space < 0 ? end : end.substring(0, space),
                            style: figure,
                          ),
                          if (space >= 0) TextSpan(text: end.substring(space)),
                        ],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final h =
        height ?? PortalProgressTheme.of(context).height ?? tokens.spacing.sm;
    final cap = tokens.textStyles.caption;
    final text = MediaQuery.textScalerOf(context)
        .scale(cap.fontSize ?? tokens.typeScale.sm);
    Widget label(double width) => SizedBox(
          height: text * (cap.height ?? 1),
          child: Center(
            child: PortalSkeleton(
              width: width,
              height: text,
              borderRadius: BorderRadius.circular(tokens.radii.sm),
            ),
          ),
        );

    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalSkeleton(
            height: h,
            borderRadius: BorderRadius.circular(tokens.radii.full),
          ),
          if (startLabel != null || endLabel != null) ...[
            SizedBox(height: tokens.spacing.sm),
            Row(
              mainAxisAlignment: startLabel == null
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (startLabel != null) label(tokens.spacing.xxxl * 2),
                if (endLabel != null)
                  label(tokens.spacing.xxxl + tokens.spacing.lg),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBanded(BuildContext context, List<double> stops, double v,
      double h, Color fill, Color track) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final edges = [0.0, ...stops, 1.0];
    final gap = SizedBox(width: tokens.borderWidth * 2);
    final marker = h + tokens.spacing.sm;
    final radius = BorderRadius.circular(tokens.radii.full);
    int flex(int i) => ((edges[i + 1] - edges[i]) * 1000).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: marker,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Row(children: [
                  for (var i = 0; i < edges.length - 1; i++) ...[
                    if (i > 0) gap,
                    Expanded(
                      flex: flex(i),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          color: v >= edges[i] &&
                                  (v < edges[i + 1] || i == edges.length - 2)
                              ? fill
                              : track,
                        ),
                      ),
                    ),
                  ],
                ]),
                PositionedDirectional(
                  start: v * c.maxWidth - marker / 2,
                  child: Container(
                    width: marker,
                    height: marker,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                      // Ringed in the card so it reads over any band.
                      border: Border.all(
                        width: tokens.borderWidth * 2,
                        color: portal.card,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (bandLabels case final names?) ...[
          SizedBox(height: tokens.spacing.xs),
          Row(children: [
            for (var i = 0; i < names.length && i < edges.length - 1; i++) ...[
              if (i > 0) gap,
              Expanded(
                flex: flex(i),
                child: Text(
                  names[i],
                  style: tokens.textStyles.caption
                      .copyWith(color: portal.onSurfaceVariant),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ]),
        ],
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
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
        value: semanticValue,
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
    final percent = semanticValue ?? '${(safe * 100).round()}%';
    if (bands case final stops?) {
      return Semantics(
        label: semanticLabel,
        value: percent,
        child: ExcludeSemantics(
          child: _buildBanded(
              context, stops, safe.clamp(0.0, 1.0), h, fill, track),
        ),
      );
    }
    final s = sentiment;
    final color = safe > 1
        ? (overflowColor ??
            skin.overflowColor ??
            PortalSemanticColors.of(context).danger)
        : (s == null ? fill : _sentimentColor(context, s, fill));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (s != null && safe > 1) {
      // Thousandths of the bar up to the limit; kept off 0 and 1000 so both
      // segments stay flexible.
      final within = (1000 / safe).round().clamp(1, 999).toInt();
      final tick = h + tokens.spacing.sm;
      return Semantics(
        label: semanticLabel,
        value: percent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                height: h,
                child: Row(
                  children: [
                    Expanded(
                      flex: within,
                      child: ColoredBox(
                        color: PortalSemanticColors.of(context).warning,
                      ),
                    ),
                    Expanded(
                      flex: 1000 - within,
                      child: ColoredBox(color: color),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: within / 1000,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: OverflowBox(
                    maxHeight: tick,
                    child: SizedBox(
                      width: tokens.borderWidth * 2,
                      height: tick,
                      child: ColoredBox(color: portal.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      value: percent,
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
    required this.segmentColor,
  });

  final String label;
  final double value;
  final Color segmentColor;
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
    final h =
        height ?? PortalProgressTheme.of(context).height ?? tokens.spacing.sm;

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
                      child: ColoredBox(color: s.segmentColor),
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
                          color: s.segmentColor,
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
/// The current bar is taller as well as coloured, and an upcoming one is
/// thinner, so position never reads by colour alone; a done bar announces
/// [doneLabel] as its value. With [onStepTap] each bar's hit area is `minTapTarget` tall
/// around the painted bar.
class PortalStepProgress extends StatelessWidget {
  const PortalStepProgress({
    super.key,
    required this.count,
    required this.current,
    this.isDone,
    this.onStepTap,
    this.doneLabel = 'done',
  });

  /// The semantic value of a completed step; pass it localised.
  final String doneLabel;

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
    bool done(int i) => isDone?.call(i) ?? i < current;

    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Semantics(
              label: 'Step ${i + 1} of $count',
              value: done(i) ? doneLabel : null,
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
                        height: i == current
                            ? base * 1.5
                            : (done(i) ? base : base * .5),
                        decoration: BoxDecoration(
                          color: done(i)
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
