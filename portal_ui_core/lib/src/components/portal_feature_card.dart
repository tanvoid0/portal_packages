import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_badge.dart';
import 'portal_button.dart';
import 'portal_card.dart';

/// The one thing to do now: an overline, a title, a detail line, optional
/// chips, and the action inside the card. [demoted] steps it back to a quiet
/// card with a secondary button, for when something else is the lead.
/// Composed from [PortalCard] + [PortalButton] + [PortalBadge]. Ported from
/// the design kit's `FeatureCard`.
class PortalFeatureCard extends StatelessWidget {
  const PortalFeatureCard({
    super.key,
    required this.overline,
    required this.title,
    this.detail,
    this.chips = const [],
    this.actionLabel,
    this.onAction,
    this.sideLabel,
    this.onSide,
    this.leading,
    this.hue,
    this.demoted = false,
  });

  final String overline;
  final String title;
  final String? detail;
  final List<String> chips;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A small button beside the title ('Preview').
  final String? sideLabel;
  final VoidCallback? onSide;

  /// A mark at the card's start.
  final Widget? leading;
  final Color? hue;
  final bool demoted;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final accent = hue ?? cs.primary;
    return PortalCard(
      gutter: true,
      backgroundColor: demoted ? null : _wash(cs, accent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: t.spacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overline.toUpperCase(),
                  style: t.textStyles.overline.copyWith(
                    color: demoted ? cs.onSurfaceVariant : accent,
                  ),
                ),
                SizedBox(height: t.spacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: t.textStyles.headline.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (sideLabel != null)
                      PortalButton(
                        label: sideLabel!,
                        onPressed: onSide,
                        variant: PortalButtonVariant.secondary,
                        size: PortalButtonSize.sm,
                        expand: false,
                      ),
                  ],
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: t.textStyles.caption.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                if (chips.isNotEmpty) ...[
                  SizedBox(height: t.spacing.md),
                  Wrap(
                    spacing: t.spacing.sm,
                    runSpacing: t.spacing.sm,
                    children: [
                      for (final c in chips)
                        PortalBadge(label: c, onWash: !demoted),
                    ],
                  ),
                ],
                if (actionLabel != null) ...[
                  SizedBox(height: t.spacing.lg),
                  PortalButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    variant: demoted
                        ? PortalButtonVariant.secondary
                        : PortalButtonVariant.primary,
                    size: PortalButtonSize.lg,
                    expand: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The brand wash behind the card: [hue] at 12% over the page. Not a shared
  /// token (tint alphas have none); kept private, as it is this card's own
  /// effect, not a general-purpose helper.
  static Color _wash(ColorScheme cs, Color hue) =>
      Color.alphaBlend(hue.withValues(alpha: 0.12), cs.surface);
}
