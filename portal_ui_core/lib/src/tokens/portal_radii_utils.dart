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
  ContinuousRectangleBorder continuousBorder({
    BorderRadius? borderRadius,
    BorderSide side = BorderSide.none,
  }) {
    return ContinuousRectangleBorder(
      borderRadius: borderRadius ?? circular(),
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
