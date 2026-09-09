import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_card.dart';

/// One metric: glyph, value, label, optional footer.
///
/// The value carries the weight — it is set in `textStyles.headline`, the
/// label in `overline`. Anything richer than a footer belongs in a real card,
/// not here.
class PortalStatCard extends StatelessWidget {
  const PortalStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accentColor,
    this.footer,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;

  /// Tints the glyph well. Defaults to the app's primary.
  final Color? accentColor;

  /// Sparkline, delta, or any small trailing widget.
  final Widget? footer;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final tint = accentColor ?? portal.primary;

    return PortalCard(
      onTap: onTap,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: Icon(icon, size: tokens.typeScale.lg, color: tint),
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
          Text(
            value,
            style: tokens.textStyles.headline.copyWith(
              color: portal.onSurface,
              height: 1,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            label,
            style: tokens.textStyles.overline
                .copyWith(color: portal.onSurfaceVariant),
          ),
          if (footer != null) ...[
            SizedBox(height: tokens.spacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}
