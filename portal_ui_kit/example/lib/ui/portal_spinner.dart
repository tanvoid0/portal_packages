import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Animated loading indicator themed with [PortalUiTheme].
///
/// Requires `flutter_spinkit` in your app's `pubspec.yaml`.
enum PortalSpinnerStyle {
  ring,
  fadingCircle,
  wave,
}

class PortalSpinner extends StatelessWidget {
  const PortalSpinner({
    super.key,
    this.size = 40,
    this.color,
    this.style = PortalSpinnerStyle.ring,
  });

  final double size;
  final Color? color;
  final PortalSpinnerStyle style;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final c = color ?? portal.primary;

    return switch (style) {
      PortalSpinnerStyle.ring => SpinKitRing(
          color: c,
          size: size,
          lineWidth: 3,
        ),
      PortalSpinnerStyle.fadingCircle => SpinKitFadingCircle(
          color: c,
          size: size,
        ),
      PortalSpinnerStyle.wave => SpinKitWave(
          color: c,
          size: size,
        ),
    };
  }
}
