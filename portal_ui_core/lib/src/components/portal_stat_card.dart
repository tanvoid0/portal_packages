import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_card.dart';

/// One metric: glyph, value, label, optional footer.
///
/// The value carries the weight — tabular figures in `textStyles.title`, or
/// `textStyles.hero` when [hero] is set; the label is `overline`. Anything
/// richer than a footer belongs in a real card, not here.
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
  });

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

  /// Sparkline or any small trailing widget.
  final Widget? footer;

  final VoidCallback? onTap;

  /// Set the value in `hero` (44) instead of `title` (22). For the one figure
  /// a page is about — a balance, a total — not a card in a row of three.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalStatCardTheme.of(context);
    final tint = accentColor ?? skin.accentColor ?? portal.primary;

    return PortalCard(
      onTap: onTap,
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
          Text(
            value,
            style: tokens.textStyles
                .numeric(hero ? tokens.textStyles.hero : tokens.textStyles.title)
                .copyWith(color: skin.valueColor ?? portal.onSurface),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            label,
            style: tokens.textStyles.overline
                .copyWith(color: skin.labelColor ?? portal.onSurfaceVariant),
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
}
