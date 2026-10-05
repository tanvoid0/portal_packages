import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/portal_ui_theme.dart';

/// A spot illustration: an SVG whose colours are `{{role}}` placeholders
/// filled from the live theme, so one drawing follows light and dark and the
/// app's seed. Each app's art is generated into `<app>_art.dart` by
/// `scripts/export-art.py` from the kit viewer; pass the result to the art
/// slot of `PortalEmptyState` or `PortalResultScreen`.
///
/// Roles: primary, primaryContainer, secondary, surfaceContainerHigh, outlineVariant,
/// card, onPrimary, surface, error, onError, onSurface, tertiary, outline,
/// onSurfaceVariant, and artInk / artMuted / artOutline (the neutrals, 30%
/// toward the primary). Keep literals out of the drawing: they do not follow a
/// changed primary.
class PortalArt extends StatelessWidget {
  const PortalArt(
    this.svg, {
    super.key,
    this.width = 160,
    this.semanticLabel,
  });

  final String svg;

  /// Drawn 4:3, so the height follows.
  final double width;

  /// Decorative unless set: the copy beside the art says what happened.
  final String? semanticLabel;

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// Substitutes every `{{role}}` in [svg] from [context]'s theme.
  static String resolve(BuildContext context, String svg) {
    final cs = Theme.of(context).colorScheme;
    final colors = <String, Color>{
      'primary': cs.primary,
      'primaryContainer': cs.primaryContainer,
      'secondary': cs.secondary,
      'surfaceContainerHigh': cs.surfaceContainerHigh,
      'outlineVariant': cs.outlineVariant,
      'card': PortalUiTheme.of(context).card,
      'onPrimary': cs.onPrimary,
      'surface': PortalUiTheme.of(context).surface,
      'error': cs.error,
      'onError': cs.onError,
      'onSurface': cs.onSurface,
      // The drawing's neutrals lean toward the primary, so a new seed tints
      // the ink and the greys too instead of leaving them a fixed grey.
      'artInk': Color.lerp(cs.onSurface, cs.primary, .3)!,
      'artMuted': Color.lerp(cs.onSurfaceVariant, cs.primary, .3)!,
      'artOutline': Color.lerp(cs.outline, cs.primary, .3)!,
      'tertiary': cs.tertiary,
      'outline': cs.outline,
      'onSurfaceVariant': cs.onSurfaceVariant,
    };
    return svg.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (m) => _hex(colors[m[1]] ?? (throw ArgumentError('unknown art role ${m[1]}'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picture = SvgPicture.string(
      resolve(context, svg),
      width: width,
      height: width * .75,
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: picture)
        : Semantics(label: semanticLabel, image: true, child: picture);
  }
}
