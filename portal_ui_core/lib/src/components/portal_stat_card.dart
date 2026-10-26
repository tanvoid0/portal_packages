import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_card.dart';
import 'portal_icon_tile.dart';
import 'portal_skeleton.dart';
import 'portal_gutter_scope.dart';

/// One metric: glyph, value, label, optional footer.
///
/// The value carries the weight — tabular figures in `textStyles.title`, or
/// `textStyles.hero` when [hero] is set; the label is `overline`. Anything
/// richer than a footer belongs in a real card, not here.
///
/// [PortalStatCard.tile] is the landing-page form -- a round mark, the figure
/// large, what it counts and what changed lately -- and two or three of them
/// sit in a [PortalStatRow]. [PortalStatCard.skeleton] is that tile loading.
class PortalStatCard extends StatelessWidget {
  const PortalStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accentColor,
    this.delta,
    this.footer,
    this.onTap,
    this.hero = false,
    this.valueColor,
    this.backgroundColor,
    this.margin,
  })  : note = null,
        _tile = false,
        _skeleton = false;

  /// A tile of a [PortalStatRow]: a 36 round mark in [accentColor] (the
  /// primary when null), [value] large on one line (scaled down to fit its
  /// third of the row, never broken mid-word), [label] under it and [note]
  /// under that. An [accentColor] also washes the card.
  const PortalStatCard.tile({
    super.key,
    required IconData this.icon,
    required this.value,
    required this.label,
    this.note,
    this.accentColor,
    this.onTap,
  })  : delta = null,
        footer = null,
        hero = false,
        valueColor = null,
        backgroundColor = null,
        margin = null,
        _tile = true,
        _skeleton = false;

  /// A [PortalStatCard.tile] while it loads: a mark, a figure bar and a label
  /// bar at the data tile's own heights. Hidden from screen readers.
  const PortalStatCard.skeleton({super.key})
      : value = '',
        label = '',
        icon = null,
        accentColor = null,
        delta = null,
        footer = null,
        onTap = null,
        hero = false,
        valueColor = null,
        backgroundColor = null,
        margin = null,
        note = null,
        _tile = true,
        _skeleton = true;

  final String value;
  final String label;
  final IconData? icon;

  /// Tints the glyph well. Defaults to the app's primary.
  final Color? accentColor;

  /// Change since last period, e.g. `'+12%'` or `'-3 kg'`. A leading `+`
  /// paints it `success`, a leading `-` paints it `danger`, anything else is
  /// muted.
  // ponytail: the sign decides the colour; add a trend enum when an app
  // needs "down is good" (weight loss) — none does yet.
  final String? delta;

  /// What changed lately ('+2 this month'), muted whatever its sign:
  /// [PortalStatCard.tile]'s line, where [delta] is the sign-coloured one.
  final String? note;

  /// Sparkline or any small trailing widget.
  final Widget? footer;

  final VoidCallback? onTap;

  /// Set the value in `hero` (44) instead of `title` (22). For the one figure
  /// a page is about — a balance, a total — not a card in a row of three.
  final bool hero;

  /// Ink of the value, for a figure that carries a state. Defaults to
  /// `onSurface`.
  final Color? valueColor;

  /// Tints the whole card, for a stat that carries a state.
  final Color? backgroundColor;

  final EdgeInsetsGeometry? margin;

  final bool _tile;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    if (_tile) return _buildTile(context);
    final skin = PortalStatCardTheme.of(context);
    final tint = accentColor ?? skin.accentColor ?? portal.primary;

    return PortalCard(
      onTap: onTap,
      margin: margin,
      backgroundColor: backgroundColor ?? skin.backgroundColor,
      padding: skin.padding ?? EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: skin.wellAlpha ?? 0.18),
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: Icon(icon, size: tokens.typeScale.lg, color: tint),
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
          // One line, shrunk to fit: a wrapped amount ("£2,500.0 / 0") reads as
          // a different number. FittedBox for the same reason as the label.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: tokens.textStyles
                  .numeric(
                      hero ? tokens.textStyles.hero : tokens.textStyles.title)
                  .copyWith(
                      color:
                          valueColor ?? skin.valueColor ?? portal.onSurface),
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          // FittedBox, not PortalText: a stat card sits in PortalStatRow's
          // IntrinsicHeight, and AutoSizeText's LayoutBuilder cannot answer it.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: tokens.textStyles.overline
                  .copyWith(color: skin.labelColor ?? portal.onSurfaceVariant),
            ),
          ),
          if (delta != null) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(
              delta!,
              style: tokens.textStyles.caption.copyWith(
                color: switch (delta!.isEmpty ? '' : delta![0]) {
                  '+' => PortalSemanticColors.of(context).success,
                  '-' => PortalSemanticColors.of(context).danger,
                  _ => portal.onSurfaceVariant,
                },
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (footer != null) ...[
            SizedBox(height: tokens.spacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final mark = t.componentSizes.iconContainerSm;
    final tint = accentColor ?? portal.primary;

    if (_skeleton) {
      return PortalCard(
        backgroundColor: portal.card,
        padding: EdgeInsets.all(t.spacing.lg),
        child: ExcludeSemantics(
          child: PortalSkeletonTone(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PortalSkeleton(
                    width: mark, height: mark, shape: BoxShape.circle),
                SizedBox(height: t.spacing.md),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: PortalSkeleton(
                    height: t.textStyles.display.fontSize!,
                    borderRadius: BorderRadius.circular(t.radii.sm),
                  ),
                ),
                SizedBox(height: t.spacing.xs),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: PortalSkeleton(
                    height: t.textStyles.subtitle.fontSize!,
                    borderRadius: BorderRadius.circular(t.radii.sm),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PortalCard(
      onTap: onTap,
      backgroundColor: accentColor == null
          ? portal.card
          : Color.alphaBlend(tint.withValues(alpha: 0.12), portal.surface),
      padding: EdgeInsets.all(t.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PortalIconTile(
            icon!,
            size: mark,
            shape: PortalIconTileShape.circle,
            glyphSize: mark / 2,
            backgroundColor: tint.withValues(alpha: 0.18),
            foregroundColor: tint,
          ),
          SizedBox(height: t.spacing.md),
          // A figure carries its unit on a non-breaking space ('35 min'), so
          // one too wide for its third of the row broke mid-word. One line,
          // scaled down to fit instead.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: t.textStyles.numeric(t.textStyles.display).copyWith(
                    color: portal.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
            ),
          ),
          SizedBox(height: t.spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: t.textStyles.subtitle.copyWith(color: portal.onSurface),
            ),
          ),
          if (note != null)
            Text(
              note!,
              style:
                  t.textStyles.caption.copyWith(color: portal.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Two or three [PortalStatCard.tile]s side by side, each the height of the
/// tallest and a third of the width. [PortalStatRow.skeleton] is the row while
/// it loads.
class PortalStatRow extends StatelessWidget {
  const PortalStatRow({super.key, required this.stats, this.padding})
      : _cells = null;

  /// [cells] [PortalStatCard.skeleton]s.
  const PortalStatRow.skeleton({super.key, int cells = 3, this.padding})
      : stats = const [],
        _cells = cells;

  /// Usually [PortalStatCard]s, but any widget works (an app's own stat-card
  /// wrapper, or a card wrapped in an entrance animation).
  final List<Widget> stats;

  /// Defaults to the page's card gutter: 16 either side, 8 above, none below.
  /// Pass `EdgeInsets.zero` inside a page that already has one.
  final EdgeInsetsGeometry? padding;

  final int? _cells;

  @override
  Widget build(BuildContext context) {
    final sp = PortalUiTheme.of(context).tokens.spacing;
    final n = _cells ?? stats.length;
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            PortalGutterScope.inset(context, sp.lg),
            sp.sm,
            PortalGutterScope.inset(context, sp.lg),
            0,
          ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) SizedBox(width: sp.sm),
              Expanded(
                child:
                    _cells != null ? const PortalStatCard.skeleton() : stats[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
