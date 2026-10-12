import 'package:flutter/material.dart';

import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_pressable.dart';

/// A text control with a chevron (opening it is navigation): muted 500 15,
/// 48 tall. [semanticLabel] carries what the eye gets from the context
/// around it. A null [onTap] dims it to the disabled ink and is heard as
/// disabled. Ported from the design kit's `ChevronLink`.
class PortalChevronLink extends StatelessWidget {
  const PortalChevronLink({
    super.key,
    required this.label,
    required this.semanticLabel,
    this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;

  static const double _disabledOpacity = .38;
  static const double _chevron = 20;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final on = onTap != null;
    final muted = on
        ? cs.onSurfaceVariant
        : cs.onSurface.withValues(alpha: _disabledOpacity);
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: on,
        child: PortalPressable(
          onTap: onTap,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: t.minTapTarget),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: t.textStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ),
                  Icon(
                    PortalIcons.chevron_right_rounded,
                    size: _chevron,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
