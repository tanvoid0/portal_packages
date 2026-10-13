import 'package:flutter/widgets.dart';

/// Window size classes, Material 3's breakpoints. Read via
/// [PortalResponsive] on [BuildContext]; everything responsive in the kit
/// keys off these four buckets rather than a raw width, so a screen never
/// invents its own cutoff.
enum PortalSizeClass { compact, medium, expanded, large }

/// Width cutoffs (logical px). M3: compact <600, medium 600–839,
/// expanded 840–1199, large ≥1200.
abstract final class PortalBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  static PortalSizeClass classFor(double width) {
    if (width >= large) return PortalSizeClass.large;
    if (width >= expanded) return PortalSizeClass.expanded;
    if (width >= medium) return PortalSizeClass.medium;
    return PortalSizeClass.compact;
  }
}

/// The readable column cap per size class. A phone reads full width; a tablet
/// or web window stops content stretching into an unreadable measure and
/// centres it instead. `infinity` on [PortalSizeClass.compact] means "no cap".
double portalMaxContentWidth(PortalSizeClass sizeClass) => switch (sizeClass) {
      PortalSizeClass.compact => double.infinity,
      PortalSizeClass.medium => 672,
      PortalSizeClass.expanded => 760,
      PortalSizeClass.large => 840,
    };

extension PortalResponsive on BuildContext {
  double get portalWidth => MediaQuery.sizeOf(this).width;

  PortalSizeClass get portalSizeClass =>
      PortalBreakpoints.classFor(portalWidth);

  bool get isCompact => portalSizeClass == PortalSizeClass.compact;

  bool get isExpandedOrWider =>
      portalSizeClass == PortalSizeClass.expanded ||
      portalSizeClass == PortalSizeClass.large;

  /// Pick a value per size class. Only [compact] is required; a wider class
  /// falls back to the nearest smaller one that was given.
  T portalResponsive<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    switch (portalSizeClass) {
      case PortalSizeClass.large:
        return large ?? expanded ?? medium ?? compact;
      case PortalSizeClass.expanded:
        return expanded ?? medium ?? compact;
      case PortalSizeClass.medium:
        return medium ?? compact;
      case PortalSizeClass.compact:
        return compact;
    }
  }
}

/// Caps and centres [child] at the size class's readable width. A no-op on a
/// phone (compact has no cap). Use on screens that own their own scroll — the
/// standard [PortalScrollPage] applies the same cap itself.
class PortalMaxWidth extends StatelessWidget {
  const PortalMaxWidth({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// Overrides the size-class default when set.
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? portalMaxContentWidth(context.portalSizeClass);
    if (!cap.isFinite) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: child,
      ),
    );
  }
}
