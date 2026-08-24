import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalDivider extends StatelessWidget {
  const PortalDivider({
    super.key,
    this.indent = 0,
    this.thickness,
    this.spacing,
  });

  final double indent;
  final double? thickness;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final gap = spacing ?? t.spacing.sm;
    final thick = thickness ?? t.borderWidth;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap),
      child: Divider(
        height: thick,
        thickness: thick,
        indent: indent,
        color: portal.subtleBorderSide().color,
      ),
    );
  }
}
