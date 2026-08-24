import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

enum PortalSeparatorOrientation { horizontal, vertical }

/// Thin rule; use horizontal in columns, vertical in rows (shadcn Separator).
class PortalSeparator extends StatelessWidget {
  const PortalSeparator({
    super.key,
    this.orientation = PortalSeparatorOrientation.horizontal,
    this.thickness,
    this.spacing,
    this.length,
  });

  final PortalSeparatorOrientation orientation;
  final double? thickness;
  final double? spacing;
  final double? length;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final thick = thickness ?? t.borderWidth;
    final gap = spacing ?? t.spacing.sm;
    final color = portal.subtleBorderSide().color;

    switch (orientation) {
      case PortalSeparatorOrientation.horizontal:
        final bar = DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(t.radii.full),
          ),
          child: SizedBox(height: thick, width: length),
        );
        return Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: length == null
              ? Divider(height: thick, thickness: thick, color: color)
              : Align(alignment: Alignment.centerLeft, child: bar),
        );
      case PortalSeparatorOrientation.vertical:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gap),
          child: SizedBox(
            width: thick,
            height: length ?? 24,
            child: DecoratedBox(decoration: BoxDecoration(color: color)),
          ),
        );
    }
  }
}
