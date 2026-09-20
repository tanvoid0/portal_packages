import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Border-radius and shape helpers for [PortalRadii].
extension PortalRadiiUtils on PortalRadii {
  /// Top-heavy corners (hub headers, stacked cards).
  BorderRadius asymmetric({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft ?? xl),
      topRight: Radius.circular(topRight ?? xl),
      bottomLeft: Radius.circular(bottomLeft ?? sm),
      bottomRight: Radius.circular(bottomRight ?? sm),
    );
  }

  /// Uniform corner radius.
  BorderRadius circular([double? value]) =>
      BorderRadius.circular(value ?? lg);

  /// iOS-style continuous corners for [Material] / [Card].
  ///
  /// The radius is doubled on the way in: Flutter draws a continuous corner
  /// as a cubic with both handles on the corner, so its apex sits r/8 in
  /// against a circle's 0.29r and a nominal 20 reads *tighter* than the
  /// rounded rect it replaces. At 2r the apex lands at 0.25r — the squircle
  /// that is as full as the circle, then softer into the straight edge.
  ContinuousRectangleBorder continuousBorder({
    BorderRadius? borderRadius,
    BorderSide side = BorderSide.none,
  }) {
    return ContinuousRectangleBorder(
      borderRadius: (borderRadius ?? circular()) * 2,
      side: side,
    );
  }

  /// Standard rounded rect border.
  RoundedRectangleBorder roundedBorder({
    BorderRadius? borderRadius,
    BorderSide side = BorderSide.none,
  }) {
    return RoundedRectangleBorder(
      borderRadius: borderRadius ?? circular(),
      side: side,
    );
  }
}
