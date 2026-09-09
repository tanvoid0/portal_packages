import 'package:flutter/material.dart';

/// Wave bottom edge for hub / section headers.
class PortalWaveHeaderClipper extends CustomClipper<Path> {
  const PortalWaveHeaderClipper({
    this.amplitude = 12,
    this.phase = 0,
    this.waves = 2,
  });

  final double amplitude;
  final double phase;
  final int waves;

  @override
  Path getClip(Size size) {
    // moveTo, not a bare lineTo: an empty path implies a start at (0, 0), and
    // the contour below has to close back to that corner for the header's own
    // content to be inside the clip.
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - amplitude);

    final waveLength = size.width / waves;
    for (var i = 0; i < waves; i++) {
      final startX = i * waveLength;
      final midX = startX + waveLength / 2;
      final endX = startX + waveLength;
      final yOffset = (i.isEven ? 0.0 : amplitude * 0.5) + phase;
      path.quadraticBezierTo(
        midX,
        size.height - amplitude - yOffset,
        endX,
        size.height - amplitude,
      );
    }

    // Up the right edge and closed along the top: the wave is the *bottom*
    // edge, so everything above it is kept. Running along `size.height`
    // instead enclosed only the wave band itself, clipping the header's
    // content away -- and `RenderClipPath` hit-tests against the clip, so the
    // back button was both invisible and untappable.
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant PortalWaveHeaderClipper oldClipper) {
    return amplitude != oldClipper.amplitude ||
        phase != oldClipper.phase ||
        waves != oldClipper.waves;
  }
}
