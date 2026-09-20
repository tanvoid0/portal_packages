import 'package:flutter/material.dart';

import 'portal_semantic_colors.dart';

/// Transient feedback variants. Palettes always resolve to **opaque**
/// [ColorScheme] roles so toasts stay readable on any visual theme, including
/// glass.
enum PortalToastVariant { neutral, success, destructive }

/// Solid fill + ink for a floating toast. Alpha on [background] / [foreground]
/// / [icon] / [action] is always 1.0.
@immutable
class PortalToastColors {
  const PortalToastColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
    required this.action,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color icon;
  final Color action;
}

/// Forces a color to full opacity without changing its hue.
Color portalOpaque(Color color) => color.withValues(alpha: 1);

/// Toast fills from [ColorScheme] / [PortalSemanticColors] — never from
/// glass-tinted [PortalUiTheme] surfaces. Neutral is cream/surface chrome;
/// success and destructive are the semantic `success` and `danger` roles.
PortalToastColors portalToastColors(
  BuildContext context,
  PortalToastVariant variant,
) {
  final cs = Theme.of(context).colorScheme;
  final semantic = PortalSemanticColors.of(context);
  switch (variant) {
    case PortalToastVariant.success:
      return PortalToastColors(
        background: portalOpaque(semantic.success),
        foreground: portalOpaque(semantic.onSuccess),
        border: portalOpaque(semantic.success),
        icon: portalOpaque(semantic.onSuccess),
        action: portalOpaque(semantic.onSuccess),
      );
    case PortalToastVariant.destructive:
      return PortalToastColors(
        background: portalOpaque(semantic.danger),
        foreground: portalOpaque(semantic.onDanger),
        border: portalOpaque(semantic.danger),
        icon: portalOpaque(semantic.onDanger),
        action: portalOpaque(semantic.onDanger),
      );
    case PortalToastVariant.neutral:
      return PortalToastColors(
        background: portalOpaque(cs.surface),
        foreground: portalOpaque(cs.onSurface),
        border: cs.outline.withValues(alpha: 0.65),
        icon: portalOpaque(cs.onSurfaceVariant),
        action: portalOpaque(cs.primary),
      );
  }
}
