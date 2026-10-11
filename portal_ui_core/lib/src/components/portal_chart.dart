import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dev/portal_review_tag.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_skeleton.dart';

/// The fleet's one chart look: primary marks, caption axis labels, no
/// gridlines and no tooltips, and the same frame height in every state.
/// Token candidates.
abstract final class _ChartValues {
  /// Plot height above the axis labels.
  static const double plot = 120;

  /// Everything that is not the mark: the fill colour at 15% (`.prog`).
  static const double rest = .15;

  /// A bar that is not the highlight is still data: primary at 70% (light)
  /// or 40% (dark) keeps it 3:1 on the page (WCAG 1.4.11).
  static const double restBarLight = .70;
  static const double restBarDark = .40;

  /// A bar's widest: with few bars (3 months) each stays a bar, centred in
  /// its share, rather than a block.
  static const double maxBar = 56;

  /// Line stroke and its end dot.
  static const double stroke = 2;
  static const double dot = 4;

  /// A sparkline rides in a stat card's footer, so it is shorter than a
  /// plot and carries neither an end dot nor a wash.
  static const double sparkline = 28;
}

/// One bar: its axis label, value, an optional figure drawn over it, and an
/// optional screen-reader line (the default reads [label] and [valueLabel],
/// which is what a tappable chart announces).
class PortalBar {
  const PortalBar(
    this.label,
    this.value, {
    this.valueLabel,
    this.semanticLabel,
  });

  final String label;
  final double value;
  final String? valueLabel;
  final String? semanticLabel;
}

/// Placeholder bar heights (fractions of the plot) for a loading chart.
const _skeletonBars = [.45, .7, .55, .85, .6, .4, .75];

TextStyle _cap(BuildContext context) {
  final t = PortalUiTheme.of(context).tokens;
  return t.textStyles
      .numeric(t.textStyles.caption)
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
}

/// One caption line at the current text scale.
double _capLine(BuildContext context) {
  final cap = _cap(context);
  return MediaQuery.textScalerOf(context).scale(cap.fontSize!) * cap.height!;
}

/// The chart's frame in every state: a value-label line, xs, the plot, xs,
/// then the axis labels -- so loading, empty and data share a height.
class _ChartFrame extends StatelessWidget {
  const _ChartFrame({
    required this.id,
    required this.semanticLabel,
    required this.plotHeight,
    required this.plot,
    required this.axis,
    this.explicitChildNodes = false,
  });

  final String id;
  final String semanticLabel;
  final double plotHeight;
  final Widget plot;
  final Widget axis;

  /// A chart whose bars are buttons keeps those buttons reachable; a static
  /// one announces [semanticLabel] alone.
  final bool explicitChildNodes;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final capLine = _capLine(context);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spacing.xs,
      children: [
        SizedBox(height: capLine + t.spacing.xs + plotHeight, child: plot),
        SizedBox(height: capLine, child: ExcludeSemantics(child: axis)),
      ],
    );
    return PortalReviewTag(
      id: id,
      child: Semantics(
        container: true,
        label: semanticLabel,
        explicitChildNodes: explicitChildNodes,
        // Without reachable bars the chart is its summary and nothing else;
        // with them, only the figures and axis labels are dropped.
        child: explicitChildNodes ? body : ExcludeSemantics(child: body),
      ),
    );
  }
}

/// [label] centred in the plot, under the value-label line, over the
/// plot's baseline hairline, so the band still reads as a chart.
Widget _emptyPlot(BuildContext context, String label, double plotHeight) {
  final t = PortalUiTheme.of(context).tokens;
  return Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      height: plotHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: t.borderWidth,
          ),
        ),
      ),
      child: Center(
        child: Text(label, style: _cap(context), textAlign: TextAlign.center),
      ),
    ),
  );
}

/// Bars in primary faded to a 3:1 tone, the [highlight] (or, with none,
/// every bar) in primary; caption axis labels, no gridlines. Screen readers
/// get [semanticLabel] only -- write it as the chart's one-line summary --
/// unless [onBarTap] makes each bar a button, which keeps the bars
/// reachable with their own labels. A tappable chart wants few bars: the
/// hit area is a full-height column, so its width is the plot divided by
/// [bars], and seven is about where that stops being a target.
/// No bars, or all zero, keeps the chart's height and axis with
/// [emptyLabel] in the plot. [PortalBarChart.loading] is its skeleton.
class PortalBarChart extends StatelessWidget {
  const PortalBarChart({
    super.key,
    required this.bars,
    required this.semanticLabel,
    this.highlight,
    this.emptyLabel = 'Nothing to show yet',
    this.plotHeight = _ChartValues.plot,
    this.minBarHeight = 0,
    this.onBarTap,
  }) : _loading = false;

  /// Shaped like the chart while its data loads: a skeleton bar per axis
  /// label, the labels kept.
  PortalBarChart.loading({
    super.key,
    required List<String> labels,
    this.semanticLabel = 'Loading',
    this.plotHeight = _ChartValues.plot,
  }) : bars = [for (final l in labels) PortalBar(l, 0)],
       highlight = null,
       emptyLabel = '',
       minBarHeight = 0,
       onBarTap = null,
       _loading = true;

  final List<PortalBar> bars;
  final String semanticLabel;
  final int? highlight;
  final String emptyLabel;
  final double plotHeight;

  /// A floor under every bar, so a zero month reads as a short column
  /// rather than a gap. Zero, the default, draws nothing for nothing.
  final double minBarHeight;

  /// Makes each bar a button carrying its index -- for a chart that is also
  /// the period picker.
  final ValueChanged<int>? onBarTap;

  final bool _loading;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cap = _cap(context);
    final top = bars.fold<double>(0, (m, b) => math.max(m, b.value));

    final Widget plot;
    if (_loading) {
      plot = PortalSkeletonTone(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: t.spacing.sm,
          children: [
            for (var i = 0; i < bars.length; i++)
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _ChartValues.maxBar,
                    ),
                    child: PortalSkeleton(
                      height:
                          plotHeight * _skeletonBars[i % _skeletonBars.length],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(t.radii.sm),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (top <= 0) {
      plot = _emptyPlot(context, emptyLabel, plotHeight);
    } else {
      plot = Row(
        // Stretched, so a column -- and with [onBarTap] its hit area -- is
        // the plot's full height; the bar itself still sits on the baseline.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spacing.sm,
        children: [
          for (final (i, b) in bars.indexed)
            Expanded(child: _bar(context, i, b, top, cap)),
        ],
      );
    }

    return _ChartFrame(
      id: 'kit.chart.bar',
      semanticLabel: semanticLabel,
      plotHeight: plotHeight,
      explicitChildNodes: onBarTap != null && !_loading && top > 0,
      plot: plot,
      axis: Row(
        spacing: t.spacing.sm,
        children: [
          for (final b in bars)
            Expanded(
              child: Text(
                b.label,
                style: cap,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    int i,
    PortalBar b,
    double top,
    TextStyle cap,
  ) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final rest = cs.primary.withValues(
      alpha: Theme.of(context).brightness == Brightness.light
          ? _ChartValues.restBarLight
          : _ChartValues.restBarDark,
    );
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: t.spacing.xs,
      children: [
        // Centred on its bar; only a figure wider than its column ends at
        // the plot edge (the first and last).
        if (b.valueLabel case final v?)
          SizedBox(
            height: _capLine(context),
            child: LayoutBuilder(
              builder: (context, c) {
                final tp = TextPainter(
                  text: TextSpan(text: v, style: cap),
                  maxLines: 1,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final wide = tp.width > c.maxWidth;
                tp.dispose();
                return OverflowBox(
                  maxWidth: double.infinity,
                  alignment: !wide
                      ? AlignmentDirectional.center
                      : i == bars.length - 1 && i > 0
                      ? AlignmentDirectional.centerEnd
                      : i == 0 && bars.length > 1
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.center,
                  child: Text(v, style: cap, maxLines: 1, softWrap: false),
                );
              },
            ),
          ),
        Container(
          height:
              minBarHeight +
              (plotHeight - minBarHeight) * (b.value / top).clamp(0.0, 1.0),
          constraints: const BoxConstraints(maxWidth: _ChartValues.maxBar),
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlight == null || highlight == i ? cs.primary : rest,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(t.radii.sm),
              ),
            ),
          ),
        ),
      ],
    );
    if (onBarTap == null) return column;
    return Semantics(
      button: true,
      selected: highlight == i,
      label:
          b.semanticLabel ??
          [b.label, b.valueLabel].whereType<String>().join(' '),
      child: InkWell(
        onTap: () => onBarTap!(i),
        borderRadius: BorderRadius.circular(t.radii.sm),
        child: ExcludeSemantics(child: column),
      ),
    );
  }
}

/// A trend line in primary, a dot on the latest point, and [labels] spread
/// along the axis; a 15% wash under it only when its range includes zero
/// (washed down to its minimum, a small change looks big). One summary
/// label for screen readers. Fewer than two points keeps the chart's height
/// with [emptyLabel] in the plot; [PortalLineChart.loading] is its skeleton.
class PortalLineChart extends StatelessWidget {
  const PortalLineChart({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.labels = const [],
    this.emptyLabel = 'Nothing to show yet',
    this.plotHeight = _ChartValues.plot,
  }) : _loading = false;

  /// Shaped like the chart while its data loads: the plot as one skeleton
  /// block, the axis labels kept.
  const PortalLineChart.loading({
    super.key,
    this.labels = const [],
    this.semanticLabel = 'Loading',
    this.plotHeight = _ChartValues.plot,
  }) : points = const [],
       emptyLabel = '',
       _loading = true;

  final List<double> points;
  final String semanticLabel;
  final List<String> labels;
  final String emptyLabel;
  final double plotHeight;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final Widget line = _loading
        ? PortalSkeletonTone(
            child: PortalSkeleton(
              height: plotHeight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(t.radii.sm),
              ),
            ),
          )
        : points.length < 2
        ? _emptyPlot(context, emptyLabel, plotHeight)
        : CustomPaint(
            size: Size.fromHeight(plotHeight),
            painter: _LinePainter(
              points,
              cs.primary,
              Directionality.of(context) == TextDirection.rtl,
            ),
          );
    return _ChartFrame(
      id: 'kit.chart.line',
      semanticLabel: semanticLabel,
      plotHeight: plotHeight,
      plot: Align(alignment: Alignment.bottomCenter, child: line),
      axis: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final l in labels) Text(l, style: _cap(context))],
      ),
    );
  }
}

/// The line alone, 28 high, for a stat card's footer or a row: no axis, no
/// frame, no end dot and no wash -- the figure beside it is the subject and
/// the shape is the footnote. Fewer than two points reserves its height and
/// draws nothing. [lineColor] defaults to primary.
class PortalSparkline extends StatelessWidget {
  const PortalSparkline({
    super.key,
    required this.points,
    this.height = _ChartValues.sparkline,
    this.lineColor,
    this.semanticLabel,
  });

  final List<double> points;
  final double height;
  final Color? lineColor;

  /// The shape's one-line summary; with none it stays out of the tree, for
  /// a trend the figure beside it already states.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(height: height);
    return PortalReviewTag(
      id: 'kit.chart.sparkline',
      child: Semantics(
        container: semanticLabel != null,
        label: semanticLabel,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              points,
              lineColor ?? Theme.of(context).colorScheme.primary,
              Directionality.of(context) == TextDirection.rtl,
              dot: 0,
              wash: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(
    this.points,
    this.color,
    this.rtl, {
    this.dot = _ChartValues.dot,
    this.wash = true,
  });

  final List<double> points;
  final Color color;
  final bool rtl;

  /// Radius of the dot on the latest point; 0 draws none.
  final double dot;

  /// Fill under the line when its range includes zero.
  final bool wash;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = points.reduce(math.min), hi = points.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    // Vertical room for the dot and the stroke; across, the line spans the
    // axis labels' width and the end dot overhangs.
    final pad = math.max(dot, _ChartValues.stroke);
    double y(double v) => pad + (size.height - 2 * pad) * (1 - (v - lo) / span);
    Offset at(int i) {
      final x = size.width * i / (points.length - 1);
      return Offset(rtl ? size.width - x : x, y(points[i]));
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    if (wash && lo <= 0) {
      final zero = y(0).clamp(0, size.height).toDouble();
      canvas.drawPath(
        Path.from(line)
          ..lineTo(at(points.length - 1).dx, zero)
          ..lineTo(at(0).dx, zero)
          ..close(),
        Paint()..color = color.withValues(alpha: _ChartValues.rest),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ChartValues.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (dot > 0) {
      canvas.drawCircle(at(points.length - 1), dot, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.color != color ||
      old.rtl != rtl ||
      old.dot != dot ||
      old.wash != wash;
}
