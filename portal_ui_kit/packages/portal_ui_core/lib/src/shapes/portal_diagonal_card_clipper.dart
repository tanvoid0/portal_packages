import 'package:flutter/material.dart';

/// Diagonal cut on the trailing-bottom corner (hero / marketing cards).
class PortalDiagonalCardClipper extends CustomClipper<Path> {
  const PortalDiagonalCardClipper({this.cut = 28});

  /// Size of the diagonal notch in logical pixels.
  final double cut;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant PortalDiagonalCardClipper oldClipper) {
    return cut != oldClipper.cut;
  }
}
