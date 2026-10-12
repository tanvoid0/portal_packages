import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// A form's fields stacked and stretched, 16 apart, inset 8 16 12 (spacing
/// sm / lg / md). Layout only; each field names itself. Ported from the
/// design kit's `FormStack`.
class PortalFormStack extends StatelessWidget {
  const PortalFormStack({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spacing.lg,
        t.spacing.sm,
        t.spacing.lg,
        t.spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: t.spacing.lg,
        children: children,
      ),
    );
  }
}
