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
    final path = Path()..lineTo(0, size.height - amplitude);

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

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
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
