import 'package:flutter/widgets.dart';

/// Says whether the page around a widget has already applied the page gutter.
///
/// The kit has one rule: **the page gutter is applied once.** A component that
/// carries its own 16dp gutter for use on a bare screen (a card with
/// `gutter: true`, a stat row, an inset list section and its header) adds it
/// only when nothing above has, so on a [PortalScrollPage] they sit on the same
/// left edge as the page's own content instead of 16dp inside it.
/// [PortalScrollPage] publishes this when it pads its children itself; a page
/// that brings its own `padding`, or a custom body, does not, and its
/// components keep their own gutter.
class PortalGutterScope extends InheritedWidget {
  const PortalGutterScope({
    super.key,
    required this.applied,
    required super.child,
  });

  final bool applied;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortalGutterScope>()?.applied ??
      false;

  /// The horizontal inset a component adds for itself: [own] on a bare screen,
  /// nothing where the page already padded.
  static double inset(BuildContext context, double own) =>
      of(context) ? 0 : own;

  @override
  bool updateShouldNotify(PortalGutterScope old) => applied != old.applied;
}
