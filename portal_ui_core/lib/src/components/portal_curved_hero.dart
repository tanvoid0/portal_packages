import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Bows the bottom edge of its child down by [depth] -- a quadratic bezier
/// with its control point below bottom-centre. [PortalCurvedHero]'s media
/// clip; public because a caller may want the same shape on a plain image.
class PortalCurveClipper extends CustomClipper<Path> {
  const PortalCurveClipper({this.depth = 40});

  final double depth;

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - depth)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + depth,
        size.width,
        size.height - depth,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) =>
      oldClipper is! PortalCurveClipper || oldClipper.depth != depth;
}

/// A `flexibleSpace` for a `PortalSliverAppBar(expandedHeight: ...)`: [media]
/// clipped to [PortalCurveClipper]'s bowed bottom edge, [caption] sitting
/// under the curve on a scrim band (so it reads over any photo), [badge] in
/// the top-end corner.
///
/// Ported from travel_buddy's `CurveClipper` hero shape.
class PortalCurvedHero extends StatelessWidget {
  const PortalCurvedHero({
    super.key,
    required this.media,
    this.caption,
    this.badge,
    this.depth,
  });

  /// Fills the hero -- typically a [PortalNetworkImage].
  final Widget media;

  /// Shown bottom-start, under the curve, on a dark scrim.
  final Widget? caption;

  /// Shown top-end, e.g. a [PortalBadge].
  final Widget? badge;

  /// Defaults to twice `tokens.radii.xl` -- a deeper bow than a card corner,
  /// shallow enough to read as a hero rather than a wave.
  final double? depth;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final d = depth ?? t.radii.xl * 2;
    return Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: PortalCurveClipper(depth: d),
            child: media,
          ),
        ),
        if (badge case final b?)
          PositionedDirectional(top: t.spacing.md, end: t.spacing.md, child: b),
        if (caption case final c?)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: d,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                t.spacing.lg,
                t.spacing.xl,
                t.spacing.lg,
                t.spacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: .45),
                  ],
                ),
              ),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: c,
              ),
            ),
          ),
      ],
    );
  }
}
