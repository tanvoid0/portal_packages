import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// The three avatar steps; the diameters are `tokens.avatarSizes`.
enum PortalAvatarMarkSize { sm, md, lg }

/// A person or thing as a circle: their photo, or their initials on
/// `primaryContainer` when there is none or it fails to load.
///
/// This is the paint only. `portal_platform`'s `PortalAvatar(user:)` keeps
/// its name and its job — resolving a session user to a photo URL and
/// initials — and is what an app reaches for to show the signed-in user;
/// this one is for everything else that wears a face or a mark (a program
/// owner, a merchant, a household member) and, later, for that wrapper to
/// draw with.
///
/// [image] goes in `foregroundImage`: when the URL 404s or the device is
/// offline Flutter keeps painting the initials underneath, so a stale photo
/// degrades to letters instead of an error box.
///
/// [statusColor] draws a ring in a semantic colour just inside the edge —
/// `PortalSemanticColors.of(context).success` for online, `warning` for away.
/// The ring fits inside the token size, so a row of avatars stays aligned
/// whether or not one carries a status.
class PortalAvatarMark extends StatelessWidget {
  const PortalAvatarMark({
    super.key,
    required this.initials,
    this.image,
    this.size = PortalAvatarMarkSize.md,
    this.statusColor,
  });

  /// Up to two characters, upper-cased. Also what a screen reader says, so
  /// pass the real initials rather than an emoji.
  final String initials;
  final ImageProvider? image;
  final PortalAvatarMarkSize size;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final sizes = tokens.avatarSizes;
    final styles = tokens.textStyles;
    // Each step's initials are the type style that sits at ~0.4 of it.
    final (dimension, style) = switch (size) {
      PortalAvatarMarkSize.sm => (sizes.sm, styles.caption),
      PortalAvatarMarkSize.md => (sizes.md, styles.subtitle),
      PortalAvatarMarkSize.lg => (sizes.lg, styles.title),
    };
    final text = initials.trim();
    final shown = (text.length > 2 ? text.substring(0, 2) : text).toUpperCase();

    // Ring width and its gap to the photo are both the hairline doubled: a
    // 2 px ring at 2 px off a 32 px avatar leaves a 24 px face, still a face.
    final ring = statusColor == null ? 0.0 : tokens.borderWidth * 2;

    Widget avatar = CircleAvatar(
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      foregroundImage: image,
      // Best-effort read: a failed photo is the initials by design.
      onForegroundImageError: image == null ? null : (_, __) {},
      child: Text(shown, style: styles.emphasized(style)),
    );

    if (statusColor != null) {
      avatar = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: statusColor!, width: ring),
        ),
        child: Padding(padding: EdgeInsets.all(ring * 2), child: avatar),
      );
    }

    return SizedBox.square(dimension: dimension, child: avatar);
  }
}

/// A dot or a count in a corner of [child], in a semantic colour.
///
/// Material's [Badge] underneath: it owns the offset, the 6 dp dot and the
/// 16 dp pill, and the `999+` cap. This adds what every call site wrote by
/// hand — `count: 0` hides — and takes a semantic pair for the colour, so
/// `PortalCountBadge(count: 3, backgroundColor: s.success,
/// foregroundColor: s.onSuccess, child: …)` is the whole call.
///
/// Not `PortalBadge`: the `portal_badge` brick seeds a label chip by that name
/// into apps (gym has one), and ui_core's barrel would make it ambiguous.
class PortalCountBadge extends StatelessWidget {
  const PortalCountBadge({
    super.key,
    required this.child,
    this.count,
    this.visible,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget child;

  /// Null draws a dot; a number draws it, capped at `999+`.
  final int? count;

  /// Defaults to `count != 0` — a dot shows, a zero count hides.
  final bool? visible;

  /// Theme `error` when null; pass a `PortalSemanticColors` role otherwise.
  final Color? backgroundColor;

  /// Theme `onError` when null; pass the role's `on*` pair with
  /// [backgroundColor] — the contrast is already tested there.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final show = visible ?? count != 0;
    if (count == null) {
      return Badge(
        isLabelVisible: show,
        backgroundColor: backgroundColor,
        textColor: foregroundColor,
        child: child,
      );
    }
    return Badge.count(
      count: count!,
      isLabelVisible: show,
      backgroundColor: backgroundColor,
      textColor: foregroundColor,
      child: child,
    );
  }
}

/// A determinate arc with its value set in the centre, for a completion
/// figure — workouts this week, tasks done, budget spent.
///
/// [value] is 0..1 and springs to each new value on `tokens.motion.standard`
/// (the effects spring, so a full ring never overshoots and wraps) over
/// `tokens.motion.medium`; under reduce-motion it jumps. The arc is
/// Material's [CircularProgressIndicator] with a round cap, the track from
/// `progressIndicatorTheme`, in [color] (theme `primary` when null). The
/// [label] defaults to the animated percentage in tabular figures so the
/// digits do not jitter as they count up; pass your own for `3 / 5`. The
/// centre text is excluded from semantics — the indicator announces the
/// label itself, once.
class PortalProgressRing extends StatelessWidget {
  const PortalProgressRing({
    super.key,
    required this.value,
    this.size,
    this.strokeWidth,
    this.label,
    this.color,
  });

  final double value;

  /// Diameter; `tokens.avatarSizes.lg` when null.
  final double? size;

  /// `tokens.spacing.xs` when null.
  final double? strokeWidth;

  /// Shown in the centre; the rounded percentage when null.
  final String? label;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final dimension = size ?? tokens.avatarSizes.lg;
    final stroke = strokeWidth ?? tokens.spacing.xs;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final style = tokens.textStyles
        .numeric(tokens.textStyles.emphasized(tokens.textStyles.caption))
        .copyWith(color: portal.onSurface);

    return SizedBox.square(
      dimension: dimension,
      child: TweenAnimationBuilder<double>(
        // `begin: 0` so the first frame counts up from empty; a later value
        // still springs from wherever the arc is, not from zero.
        tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
        duration: reduceMotion ? Duration.zero : tokens.motion.medium,
        curve: tokens.motion.standard,
        builder: (context, v, _) {
          final text = label ?? '${(v * 100).round()}%';
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                color: color,
                // Same 15% recipe as the theme's track, in the arc's colour.
                backgroundColor: color?.withValues(alpha: 0.15),
                semanticsValue: text,
              ),
              // scaleDown only shrinks: default-scale text is untouched, a
              // large text scale or a long custom label stays inside the arc.
              Padding(
                padding: EdgeInsets.all(stroke * 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ExcludeSemantics(
                    child: Text(text, style: style, maxLines: 1),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
