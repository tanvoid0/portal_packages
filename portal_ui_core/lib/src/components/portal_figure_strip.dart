import 'package:flutter/material.dart';

import '../dev/portal_review_tag.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';
import 'portal_skeleton.dart';
import 'portal_text.dart';

/// One cell of a [PortalFigureStrip]. [spoken] is the caption a screen reader
/// hears when the short one leans on its neighbour ('Done this year' for
/// 'This year').
class PortalFigure {
  const PortalFigure(this.caption, this.value, {this.unit, this.spoken});

  final String caption;
  final String value;
  final String? unit;
  final String? spoken;
}

/// `row`: the cells share the width. `figure`: the `.fit` cell, 34 and
/// "scales to fit", 150 wide, wrapping.
enum PortalFigureSize { row, figure }

// `.fit` caption-to-amount gap 2; the cell is 150 wide, so a long figure
// shows the scaling. Its rule is the theme's hairline colour.
const double _fitGap = 2;
const double _fitWidth = 150;

/// Supporting figures under a hero (`.fits`): 2-4 equal cells, each a
/// caption over an amount that shrinks to its cell, a hairline on the leading
/// edge. Row-size by default -- G2 keeps one headline number per page.
class PortalFigureStrip extends StatelessWidget {
  const PortalFigureStrip({
    super.key,
    required this.figures,
    this.size = PortalFigureSize.row,
  }) : _cells = 0;

  /// The strip while it loads: [cells] hairline cells, each a caption bar
  /// over an amount bar at their lines' heights. Row size only.
  const PortalFigureStrip.skeleton({super.key, int cells = 3})
      : figures = const [],
        size = PortalFigureSize.row,
        _cells = cells;

  final List<PortalFigure> figures;

  /// `figure` is the kit's 34 "scales to fit" cell.
  final PortalFigureSize size;
  final int _cells;

  @override
  Widget build(BuildContext context) {
    final portalUi = PortalUiTheme.of(context);
    final t = portalUi.tokens;
    final cs = Theme.of(context).colorScheme;
    final rule = BorderSide(
      color: portalUi.rule(cs),
      width: t.borderWidth,
    );
    final cap = t.textStyles.caption.copyWith(color: cs.onSurfaceVariant);
    Widget ruled(Widget child) => DecoratedBox(
          decoration: BoxDecoration(border: BorderDirectional(start: rule)),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              t.spacing.lg,
              t.spacing.xs,
              0,
              t.spacing.xs,
            ),
            child: child,
          ),
        );
    Widget strip(Widget child) => PortalReviewTag(
          id: 'kit.figureStrip',
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              t.spacing.lg,
              t.spacing.lg,
              t.spacing.lg,
              t.spacing.xs,
            ),
            child: child,
          ),
        );

    if (_cells > 0) {
      final ts = MediaQuery.textScalerOf(context);
      final value = _rowValue(t);
      Widget bar(TextStyle s, double widthFactor) => SizedBox(
            height: ts.scale(s.fontSize!) * s.height!,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                child: PortalSkeleton(
                  height: ts.scale(s.fontSize!),
                  borderRadius: BorderRadius.circular(t.radii.sm),
                ),
              ),
            ),
          );
      return strip(
        ExcludeSemantics(
          child: PortalSkeletonTone(
            child: Row(
              spacing: t.spacing.lg,
              children: [
                for (var i = 0; i < _cells; i++)
                  Expanded(
                    child: ruled(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: _fitGap,
                        children: [bar(cap, .7), bar(value, .55)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget cell(PortalFigure f) => Semantics(
          container: true,
          label: [f.spoken ?? f.caption, f.value, if (f.unit case final u?) u]
              .join(', '),
          child: ExcludeSemantics(
            child: ruled(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _fitGap,
                children: [
                  // ponytail: the figure strip measures its cells with
                  // IntrinsicHeight, which PortalText's LayoutBuilder cannot
                  // answer; plain Text there, shrink-to-fit in the row size.
                  size == PortalFigureSize.figure
                      ? Text(f.caption, style: cap)
                      : PortalText(f.caption, style: cap),
                  _FigureValue(f.value, unit: f.unit, size: size),
                ],
              ),
            ),
          ),
        );
    return strip(
      // `figure` is the kit's `.fits`: 150 cells that wrap, 16 by 8;
      // a row-size strip shares the width.
      size == PortalFigureSize.figure
          ? Wrap(
              spacing: t.spacing.lg,
              runSpacing: t.spacing.sm,
              children: [
                // Every cell takes the unscaled amount's height, as the
                // kit's flex row stretches a shrunk one to its neighbour.
                for (final f in figures)
                  SizedBox(
                    width: _fitWidth,
                    child: IntrinsicHeight(child: cell(f)),
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: t.spacing.lg,
              children: [for (final f in figures) Expanded(child: cell(f))],
            ),
    );
  }
}

/// `.val`: 500 16/1.35 in every app (whatever the skin's body size), and
/// proportional figures.
TextStyle _rowValue(DesignTokens t) => t.textStyles.body.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0,
    );

// A figure with an optional sign and currency, then an optional word-unit,
// then the rest.
final _valueParts = RegExp(
  r'^([+\-−]?\p{Sc}?\d[\d.,]*)(\s+[A-Za-z%/°]+)?(.*)$',
  unicode: true,
);

/// What may follow a figure and still leave it a quantity: a unit glued to
/// it ('+18%'), or another figure behind a multiplier or a slash, with a
/// short unit ('x 8', '/ 100 g'). Anything else is prose.
final _valueTail = RegExp(
  r'^\s*(?:[%°]|[x×*/·]\s*\d[\d.,]*\s*[A-Za-z%]{0,4})$',
);

/// A row's value, built to be read at a glance: the figure heavy (700, 17),
/// its unit small and muted, anything after it ('x 8' reps) at 600. Only a
/// value that *is* a quantity is drawn that way; prose ('Paid', '10 min and
/// 1 h before') is 600 throughout. [unit] is appended when the value does not
/// carry one.
TextSpan portalValueSpan(
  TextStyle base,
  String value, {
  String? unit,
  required Color muted,
}) {
  final m = _valueParts.firstMatch(value);
  final strong = base.copyWith(fontWeight: FontWeight.w600);
  final unitStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: muted,
  );
  if (m == null || !(m[3]!.isEmpty || _valueTail.hasMatch(m[3]!))) {
    return TextSpan(
      text: value,
      style: strong,
      children: [
        if (unit != null) TextSpan(text: ' $unit', style: unitStyle),
      ],
    );
  }
  return TextSpan(
    style: strong,
    children: [
      TextSpan(
        text: m[1],
        style: base.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      if (m[2] != null) TextSpan(text: m[2], style: unitStyle),
      if (unit != null) TextSpan(text: ' $unit', style: unitStyle),
      if (m[3]!.isNotEmpty) TextSpan(text: m[3]),
    ],
  );
}

/// A strip cell's value, drawn as the viewer's `KitAmount` does: a row's value
/// heavy-figure-plus-muted-unit, or the 34 `.fit` display figure.
class _FigureValue extends StatelessWidget {
  const _FigureValue(this.value, {required this.unit, required this.size});

  final String value;
  final String? unit;
  final PortalFigureSize size;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    final row = size == PortalFigureSize.row;
    final style = (row
            ? _rowValue(t)
            : t.textStyles
                .numeric(t.textStyles.hero)
                .copyWith(fontSize: 34, height: 1.15))
        .copyWith(color: ink);
    final TextSpan span;
    if (row) {
      span = portalValueSpan(style, value, unit: unit, muted: muted);
    } else {
      // `.amt small`: .5em, 600.
      final unitStyle = style.copyWith(
        fontSize: style.fontSize! / 2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: muted,
      );
      span = TextSpan(
        text: value,
        children: [
          if (unit case final u?) ...[
            const TextSpan(text: ' '),
            TextSpan(text: u, style: unitStyle),
          ],
        ],
      );
    }
    return PortalReviewTag(
      id: row ? 'kit.G2.row' : 'kit.G2.fit',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text.rich(span, style: style, maxLines: 1, softWrap: false),
      ),
    );
  }
}
