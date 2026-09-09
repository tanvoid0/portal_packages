import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// A titled break inside a scroll page.
///
/// Extracted from portal_gym so every app labels its sections the same way.
/// Type comes from `tokens.textStyles.subtitle` — an app that wants a heavier
/// or tighter section title changes it once, in its token bundle, not here.
class PortalSectionHeader extends StatelessWidget {
  const PortalSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.foregroundColor,
  });

  final String title;

  /// Optional leading glyph. Sized to the title's line, not a fixed constant.
  final IconData? icon;

  /// Right-aligned affordance — a "See all", a count, an action.
  final Widget? trailing;

  /// Overrides icon and title colour. Defaults to `onSurface`.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final ink = foregroundColor ?? portal.onSurface;
    final style = tokens.textStyles.subtitle.copyWith(color: ink);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: style.fontSize, color: ink),
          SizedBox(width: tokens.spacing.sm),
        ],
        Expanded(child: Text(title, style: style)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
