import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_card.dart';

/// A photo tile with `tokens.gradients.imageScrim` for legibility: corner
/// badges ([topStart]/[bottomEnd]), a bottom [overlay] (a label living in the
/// scrim's own white-on-photo ink), or a [footer] panel below the photo
/// instead (title/meta in the page's own ink) — gym's explore-program cards
/// and quick-start tiles, and lifestyle's outfit picks, each drew their own
/// copy of this scrim before folding onto this component.
class PortalMediaTile extends StatelessWidget {
  const PortalMediaTile({
    super.key,
    required this.photo,
    this.scrim = true,
    this.topStart,
    this.bottomEnd,
    this.overlay,
    this.footer,
    this.gradient,
    this.onTap,
    this.borderRadius,
  });

  /// The image (or a placeholder) filling the tile; pad/inset it yourself if
  /// it should sit inside [gradient] rather than bleed to the tile's edge.
  final Widget photo;

  /// `tokens.gradients.imageScrim` over [photo]. Off only when nothing is
  /// drawn over it ([topStart]/[bottomEnd]/[overlay] all null).
  final bool scrim;

  /// Badges pinned to the photo's corners (a 'Top Picks'/'Preview' mark).
  final Widget? topStart;
  final Widget? bottomEnd;

  /// Laid over the scrim at the bottom — the tile's own label, meant to read
  /// in the scrim's white-on-photo ink, not the page's.
  final Widget? overlay;

  /// A panel below the photo, outside the scrim, in the page's own ink (a
  /// title plus a meta row too long to live in [overlay]). When set, the
  /// photo+scrim stage fills the remaining space, so the tile needs a
  /// bounded height from its parent (a shelf item, a grid cell). A footer
  /// taller than three quarters of the tile is clipped there, so the photo
  /// keeps a quarter of the height instead of being squeezed to nothing.
  final Widget? footer;

  /// Paints behind [photo] — a category's brand gradient showing past an
  /// inset image (gym's quick-start tiles).
  final Gradient? gradient;

  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;

    final stage = Stack(
      fit: StackFit.expand,
      children: [
        photo,
        if (scrim)
          DecoratedBox(
            decoration: BoxDecoration(gradient: t.gradients.imageScrim(cs)),
          ),
        if (topStart != null)
          PositionedDirectional(
            start: t.spacing.sm,
            top: t.spacing.sm,
            child: topStart!,
          ),
        if (bottomEnd != null)
          PositionedDirectional(
            end: t.spacing.sm,
            bottom: t.spacing.sm,
            child: bottomEnd!,
          ),
        if (overlay != null)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.all(t.spacing.md),
              child: overlay!,
            ),
          ),
      ],
    );

    return PortalCard(
      padding: EdgeInsets.zero,
      gradient: gradient,
      onTap: onTap,
      borderRadius: borderRadius,
      child: footer == null
          ? stage
          : LayoutBuilder(
              builder: (context, c) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: stage),
                  // The scroll view lays the footer out at its natural height
                  // and clips it to the cap (no gesture: it never scrolls),
                  // so a footer's own Column cannot overflow a short tile.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: c.maxHeight * 3 / 4),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: footer!,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// [tiles] in rows of [columns], [gap] apart — a grid of [PortalMediaTile]s
/// (a catalogue, a photo collection). Each cell is locked to [aspectRatio]
/// so a Row gives it a bounded height; a short last row keeps its cells'
/// width.
class PortalMediaGrid extends StatelessWidget {
  const PortalMediaGrid({
    super.key,
    required this.tiles,
    this.columns = 2,
    this.aspectRatio = 4 / 3,
    this.gap,
  }) : assert(columns > 0);

  final List<Widget> tiles;
  final int columns;
  final double aspectRatio;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final spacing = gap ?? PortalUiTheme.of(context).tokens.spacing.md;
    return Column(
      spacing: spacing,
      children: [
        for (var i = 0; i < tiles.length; i += columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing,
            children: [
              for (var j = i; j < i + columns; j++)
                Expanded(
                  child: j < tiles.length
                      ? AspectRatio(aspectRatio: aspectRatio, child: tiles[j])
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}
