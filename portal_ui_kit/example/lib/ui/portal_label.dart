import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Label for form controls (shadcn Label).
class PortalLabel extends StatelessWidget {
  const PortalLabel({
    required this.text,
    super.key,
    this.requiredIndicator = false,
  });

  final String text;
  final bool requiredIndicator;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.xs),
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: portal.onSurface,
                fontWeight: FontWeight.w600,
              ),
          children: [
            TextSpan(text: text),
            if (requiredIndicator)
              TextSpan(
                text: ' *',
                style: TextStyle(color: portal.destructive),
              ),
          ],
        ),
      ),
    );
  }
}
