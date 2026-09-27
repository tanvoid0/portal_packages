import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';

/// Where a reviewable id stands against `review/status.json`.
enum PortalReviewStatus { todo, changes, approved }

DesignTokens _tokensOf(BuildContext context) =>
    PortalUiTheme.maybeOf(context)?.tokens ?? DesignTokens.defaults;

/// Turns the [PortalReviewTag] badges beneath it on or off, coloured from
/// [statuses]. A plain switch: the caller owns [enabled] -- the demo drives
/// it from Widgetbook's side panel, so nothing is drawn over the page.
///
/// A shipped app never wraps its tree in this, so [PortalReviewTag] has no
/// scope to find and returns its child untouched -- the review machinery
/// costs nothing outside the design-review demo it was built for
/// (`apps/portal_design`).
class PortalReviewScope extends StatelessWidget {
  const PortalReviewScope({
    super.key,
    required this.enabled,
    required this.child,
    this.statuses = const {},
  });

  final bool enabled;
  final Widget child;
  final Map<String, PortalReviewStatus> statuses;

  @override
  Widget build(BuildContext context) => _PortalReviewInherited(
        enabled: enabled,
        statuses: statuses,
        child: child,
      );
}

class _PortalReviewInherited extends InheritedWidget {
  const _PortalReviewInherited({
    required this.enabled,
    required this.statuses,
    required super.child,
  });

  final bool enabled;
  final Map<String, PortalReviewStatus> statuses;

  static _PortalReviewInherited? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PortalReviewInherited>();

  @override
  bool updateShouldNotify(_PortalReviewInherited oldWidget) =>
      enabled != oldWidget.enabled || statuses != oldWidget.statuses;
}

/// Badges [child] with [id] when a [PortalReviewScope] ancestor is enabled;
/// otherwise returns [child] unchanged -- no ancestor, no scope enabled, no
/// extra pixel. The badge is [IgnorePointer] and never resizes [child]: it
/// paints in the corner of a [Stack] sized by [child] alone.
class PortalReviewTag extends StatelessWidget {
  const PortalReviewTag({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = _PortalReviewInherited.maybeOf(context);
    if (scope == null || !scope.enabled) return child;

    final tokens = _tokensOf(context);
    final scheme = Theme.of(context).colorScheme;
    final status = scope.statuses[id] ?? PortalReviewStatus.todo;
    final (bg, fg) = switch (status) {
      PortalReviewStatus.todo => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
      PortalReviewStatus.changes => (scheme.error, scheme.onError),
      PortalReviewStatus.approved => (scheme.primary, scheme.onPrimary),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -tokens.spacing.xs,
          right: -tokens.spacing.xs,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(tokens.radii.full),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.xs,
                  vertical: 1,
                ),
                child: Text(
                  id,
                  style: tokens.textStyles.overline.copyWith(color: fg),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
