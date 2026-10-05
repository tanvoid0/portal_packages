import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Tells a [PortalButtonDock] whether content scrolls beneath it. A
/// `PortalScrollPage(bottom:)` provides it; a dock outside one passes
/// `showRule` itself.
class PortalDockRule extends InheritedWidget {
  const PortalDockRule({super.key, required this.showRule, required super.child});

  final bool showRule;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortalDockRule>()?.showRule ??
      false;

  @override
  bool updateShouldNotify(PortalDockRule old) => showRule != old.showRule;
}

/// Sticky bottom actions: a primary `PortalButton` (large) and an optional
/// secondary under it, full width, on the page's tone.
///
/// A 1 dp top rule shows only while content scrolls beneath it. Padding is
/// 12 16 32 at rest and drops to 12 at the bottom when the keyboard is open,
/// when the dock rides on top of it. Never inside a section card.
class PortalButtonDock extends StatelessWidget {
  const PortalButtonDock({
    super.key,
    required this.primary,
    this.secondary,
    this.showRule,
  });

  final Widget primary;

  /// Under the primary; a ghost or tonal `PortalButton`, 48 painted.
  final Widget? secondary;

  /// Overrides what an enclosing `PortalScrollPage` reports.
  final bool? showRule;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom > 0;
    // 32 clears the gesture bar's own inset plus breathing room.
    final bottom = keyboard ? 12.0 : math.max(32.0, mq.viewPadding.bottom + 16);
    final rule = showRule ?? PortalDockRule.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: portal.surface,
        border: Border(
          top: BorderSide(
            color: rule ? cs.outlineVariant : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            if (secondary != null) ...[const SizedBox(height: 8), secondary!],
          ],
        ),
      ),
    );
  }
}
