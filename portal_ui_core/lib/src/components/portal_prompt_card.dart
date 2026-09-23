import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';

/// A single suggested prompt: a small tinted icon tile over a title and an
/// optional one-line subtitle -- the deck shown before the first question,
/// or restated inline in place of a plain chip.
///
/// Built on [PortalPressable] directly (not [PortalCard], which has no
/// haptic hook) so a tap gets the kit's press state and a light haptic.
class PortalPromptCard extends StatelessWidget {
  const PortalPromptCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tileColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;

  /// One line; omitted entirely when null or empty, closing the card up
  /// around the title.
  final String? subtitle;
  final VoidCallback? onTap;

  /// Fill behind [icon]. Defaults to a tint of `primaryContainer`.
  final Color? tileColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radii.lg);
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return PortalPressable(
      onTap: onTap,
      haptic: PortalHapticKind.light,
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: radius,
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tileColor ?? scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.radii.sm),
                ),
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacing.xs),
                  child: Icon(
                    icon,
                    size: tokens.typeScale.xl,
                    color: iconColor ?? scheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              Text(
                title,
                maxLines: hasSubtitle ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: tokens.textStyles.emphasized(tokens.textStyles.caption)
                    .copyWith(color: scheme.onSurface),
              ),
              if (hasSubtitle) ...[
                SizedBox(height: tokens.spacing.xs),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.textStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays a row of [PortalPromptCard]s out, either as a horizontal scroller
/// (the default -- a strip above a transcript) or [wrapped] two-up, the grid
/// a full-page opening deck uses so every card is visible at a glance
/// instead of half of them sitting off the right edge of a scroller.
class PortalPromptCardRow extends StatelessWidget {
  const PortalPromptCardRow({
    super.key,
    required this.children,
    this.wrapped = false,
    this.padding,
    this.itemWidth = 200,
  });

  final List<Widget> children;
  final bool wrapped;
  final EdgeInsetsGeometry? padding;

  /// Card width in the horizontal-scroll layout. Ignored when [wrapped].
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final gap = tokens.spacing.sm;
    final edgePadding = padding ??
        EdgeInsets.symmetric(horizontal: tokens.layout.pageHorizontal);

    if (wrapped) {
      return Padding(
        padding: edgePadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? (constraints.maxWidth - gap) / 2
                : itemWidth;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final child in children)
                  SizedBox(width: width, child: child),
              ],
            );
          },
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: edgePadding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            SizedBox(width: itemWidth, child: children[i]),
          ],
        ],
      ),
    );
  }
}
