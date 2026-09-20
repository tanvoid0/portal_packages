import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_app_bar.dart';

/// The fleet's pull-to-refresh over [RefreshIndicator].
///
/// Material's defaults are the spinner disc every app ships by accident:
/// a 2dp shadow, the default stroke, and a disc that draws over the app bar.
/// This one is flat (`elevation` 0) on the theme's elevated surface — the
/// disc colour is `progressIndicatorTheme.refreshBackgroundColor`, so a bare
/// `RefreshIndicator` wears it too — spins `primary` at a 2.5 stroke, plays
/// [PortalHaptics.light] the moment the pull is released past the threshold,
/// and takes an [edgeOffset] so the disc drops out from under a pinned bar
/// instead of over it.
///
/// `PortalScrollPage.onRefresh` already wraps its scroll view in one; reach
/// for this directly when the scroll view is your own.
class PortalRefresh extends StatelessWidget {
  const PortalRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  /// Where the disc appears from, measured from the child's top. Zero for a
  /// scroll view with no bar; [belowBar] for one that starts with a pinned
  /// [PortalSliverAppBar] or a [PortalHeader.large].
  final double edgeOffset;

  /// The [edgeOffset] that puts the disc under the status bar and a pinned
  /// [PortalSliverAppBar], or under the expanded [PortalHeader.large] when
  /// [large] — the header's height at rest, which is where it is when the
  /// pull begins.
  static double belowBar(BuildContext context, {bool large = false}) =>
      MediaQuery.paddingOf(context).top +
      (large ? PortalHeader.expandedHeight : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    return RefreshIndicator(
      color: portal.primary,
      strokeWidth: 2.5,
      elevation: 0,
      edgeOffset: edgeOffset,
      onRefresh: () {
        PortalHaptics.light();
        return onRefresh();
      },
      child: child,
    );
  }
}
