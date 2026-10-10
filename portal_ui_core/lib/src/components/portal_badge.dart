import 'package:flutter/material.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_semantic_colors.dart';
import '../theme/portal_ui_theme.dart';

/// Which colour a [PortalBadge] speaks in.
enum PortalBadgeTone {
  neutral,
  primary,
  secondary,
  success,
  warning,
  danger,
  info;

  /// A 1-based priority or difficulty [level] of [max] as a tone: the top third
  /// shouts (danger), the middle warns, the rest stays neutral. The label must
  /// still say the level; colour is never the only signal.
  static PortalBadgeTone ofLevel(int level, {int max = 3}) {
    final f = level / max;
    return f > 2 / 3
        ? danger
        : f > 1 / 3
            ? warning
            : neutral;
  }
}

/// True when two fills would be taken for each other at badge size: the same
/// hue family. Hue carries the meaning here, so it is the hue that is compared.
bool _tooAlike(Color a, Color b) {
  final x = HSVColor.fromColor(a), y = HSVColor.fromColor(b);
  final d = (x.hue - y.hue).abs();
  return (d < 40 || d > 320) && (x.saturation > .05 || y.saturation > .05);
}

/// Status label: Paid, Overdue, In progress.
///
/// A tinted pill: the tone at a low alpha behind the tone as text, so it reads
/// on glass and solid surfaces alike. [outlined] adds a hairline in the tone
/// for a status that must not read by colour alone. [containerTone] swaps the
/// tint for the tone's solid container behind its on-container ink; [compact]
/// is the denser pill for a row's chip. Not [PortalCountBadge],
/// which sits on another widget's corner; this one is a word. Re-skin
/// app-wide with [PortalBadgeTheme].
class PortalBadge extends StatelessWidget {
  const PortalBadge({
    super.key,
    required this.label,
    this.tone = PortalBadgeTone.neutral,
    this.icon,
    this.leading,
    this.outlined = false,
    this.foregroundColor,
    this.backgroundColor,
    this.compact = false,
    this.containerTone = false,
  });

  /// A badge for a 1-based priority or difficulty [level] of [max]; see
  /// [PortalBadgeTone.ofLevel].
  factory PortalBadge.ofLevel(
    int level, {
    int max = 3,
    required String label,
    IconData? icon,
    bool outlined = false,
    bool compact = false,
    bool containerTone = false,
  }) =>
      PortalBadge(
        label: label,
        tone: PortalBadgeTone.ofLevel(level, max: max),
        icon: icon,
        outlined: outlined,
        compact: compact,
        containerTone: containerTone,
      );

  final String label;
  final PortalBadgeTone tone;
  final IconData? icon;

  /// Any glyph (a `FaIcon`, an SVG) in place of [icon]; it paints itself, so
  /// size and tint it with the ink [PortalBadge] sets through `IconTheme`.
  final Widget? leading;
  final bool outlined;

  /// Replaces the tone's colour, for a domain hue the semantic set lacks
  /// (a journey status). The tint behind it is derived unless
  /// [backgroundColor] is set.
  final Color? foregroundColor;
  final Color? backgroundColor;

  /// A row's chip: no vertical padding, a smaller glyph. Wins over
  /// [PortalBadgeTheme.padding], which is sized for the regular pill.
  final bool compact;

  /// Paint the tone's container behind its on-container ink instead of the
  /// alpha tint. A [foregroundColor] has no container, so it keeps the tint.
  final bool containerTone;

  /// The container and ink for [tone]. Primary, secondary and info are the
  /// "not done" tones: a skin whose container sits at success's hue ('Active'
  /// beside 'Paid') would draw both the same pale green, so they fall back to
  /// the primary container, then the neutral fill.
  (Color, Color) _container(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final semantic = PortalSemanticColors.of(context);
    final neutral = (
      // On a surface that is already high the card is the neutral fill.
      Material.maybeOf(context)?.color == cs.surfaceContainerHigh
          ? portal.card
          : cs.surfaceContainerHigh,
      cs.onSurfaceVariant,
    );
    (Color, Color) notDone((Color, Color) pending) {
      final done = semantic.successContainer;
      if (!_tooAlike(pending.$1, done)) return pending;
      final accent = (cs.primaryContainer, cs.onPrimaryContainer);
      return _tooAlike(accent.$1, done) ? neutral : accent;
    }

    return switch (tone) {
      PortalBadgeTone.neutral => neutral,
      PortalBadgeTone.primary =>
        notDone((cs.primaryContainer, cs.onPrimaryContainer)),
      PortalBadgeTone.secondary =>
        notDone((cs.secondaryContainer, cs.onSecondaryContainer)),
      PortalBadgeTone.success =>
        (semantic.successContainer, semantic.onSuccessContainer),
      PortalBadgeTone.warning =>
        (semantic.warningContainer, semantic.onWarningContainer),
      PortalBadgeTone.danger =>
        (semantic.dangerContainer, semantic.onDangerContainer),
      PortalBadgeTone.info =>
        notDone((semantic.infoContainer, semantic.onInfoContainer)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalBadgeTheme.of(context);
    final semantic = PortalSemanticColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final toned = switch (tone) {
      PortalBadgeTone.neutral => portal.onMuted,
      PortalBadgeTone.primary => portal.primary,
      PortalBadgeTone.secondary => portal.secondary,
      PortalBadgeTone.success => semantic.success,
      PortalBadgeTone.warning => semantic.warning,
      PortalBadgeTone.danger => semantic.danger,
      PortalBadgeTone.info => semantic.info,
    };
    final container =
        containerTone && foregroundColor == null ? _container(context) : null;
    final fg = foregroundColor ?? container?.$2 ?? toned;
    final bg = backgroundColor ??
        container?.$1 ??
        (tone == PortalBadgeTone.neutral && foregroundColor == null
            ? portal.muted
            : fg.withValues(alpha: skin.tintAlpha ?? (dark ? 0.22 : 0.14)));

    final glyph = compact ? tokens.typeScale.xs : tokens.typeScale.sm;
    final style = (skin.textStyle ??
            tokens.textStyles.caption.copyWith(fontWeight: FontWeight.w600))
        .copyWith(color: fg);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            skin.borderRadius ?? BorderRadius.circular(tokens.radii.full),
        border:
            outlined ? Border.all(color: fg, width: tokens.borderWidth) : null,
      ),
      child: Padding(
        padding: compact
            ? EdgeInsets.symmetric(horizontal: tokens.spacing.sm)
            : skin.padding ??
                EdgeInsets.symmetric(
                  horizontal: tokens.spacing.md,
                  vertical: tokens.spacing.xs,
                ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: fg, size: glyph),
                child: leading!,
              ),
              SizedBox(width: tokens.spacing.xs),
            ] else if (icon != null) ...[
              Icon(icon, size: glyph, color: fg),
              SizedBox(width: tokens.spacing.xs),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}
