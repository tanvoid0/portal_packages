import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// One tile on a vertical timeline: a [node] sitting on a connecting rail, with
/// [child] (the entry's content) beside it. [isFirst]/[isLast] trim the rail so
/// the line starts and ends at the first and last node of a run.
///
/// A lightweight, domain-free timeline primitive — the caller supplies the node
/// (a dot, a [PortalIconTile], a ring) and the body, so it serves an itinerary,
/// an agenda, an activity feed. The richer task timeline (duration capsules,
/// progress-fill spine, now-cap) can fold onto this as a second consumer.
///
/// The line is two fixed-geometry [PositionedDirectional] segments (above and
/// below the node centre) sized off the Stack's own height, so no
/// `IntrinsicHeight` is needed — the content decides the row height and the rail
/// fills it.
class PortalTimelineTile extends StatelessWidget {
  const PortalTimelineTile({
    super.key,
    required this.node,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.lineColor,
  });

  /// The marker on the rail — a dot, a `PortalIconTile`, a ring. Sized to
  /// [nodeSize].
  final Widget node;

  /// The entry beside the node (a title, time, detail, actions).
  final Widget child;
  final bool isFirst;
  final bool isLast;

  /// The rail colour; defaults to the theme's `outlineVariant`.
  final Color? lineColor;

  static const double _railWidth = 40;
  static const double nodeSize = 36;
  static const double _nodeTop = 2;
  static const double _nodeCentre = _nodeTop + nodeSize / 2; // 20
  static const double _lineX = _railWidth / 2 - 1; // 19

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final line = lineColor ?? Theme.of(context).colorScheme.outlineVariant;

    return Stack(
      children: [
        // Line above the node (omitted on the first tile).
        if (!isFirst)
          PositionedDirectional(
            start: _lineX,
            top: 0,
            height: _nodeCentre,
            width: 2,
            child: ColoredBox(color: line),
          ),
        // Line below the node, running into this tile's bottom gap so it meets
        // the next tile's top segment (omitted on the last tile).
        if (!isLast)
          PositionedDirectional(
            start: _lineX,
            top: _nodeCentre,
            bottom: 0,
            width: 2,
            child: ColoredBox(color: line),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _railWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: _nodeTop),
                  child: SizedBox.square(dimension: nodeSize, child: node),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(left: t.spacing.xs, bottom: t.spacing.md),
                child: child,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
