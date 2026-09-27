import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';

/// Where a reviewable id stands against `review/status.json`.
enum PortalReviewStatus { todo, changes, approved }

DesignTokens _tokensOf(BuildContext context) =>
    PortalUiTheme.maybeOf(context)?.tokens ?? DesignTokens.defaults;

/// Mounts the design-review overlay over [child]: a "Review" pill (top
/// right, above everything) shows or hides the [PortalReviewTag] badges
/// beneath it, coloured from [statuses].
///
/// A shipped app never wraps its tree in this, so [PortalReviewTag] has no
/// scope to find and returns its child untouched -- the review machinery
/// costs nothing outside the design-review demo it was built for
/// (`apps/portal_design`).
class PortalReviewScope extends StatefulWidget {
  const PortalReviewScope({
    super.key,
    required this.child,
    this.statuses = const {},
    this.initiallyEnabled = false,
  });

  final Widget child;
  final Map<String, PortalReviewStatus> statuses;
  final bool initiallyEnabled;

  @override
  State<PortalReviewScope> createState() => _PortalReviewScopeState();
}

class _PortalReviewScopeState extends State<PortalReviewScope> {
  late bool _enabled = widget.initiallyEnabled;

  void _toggle() => setState(() => _enabled = !_enabled);

  @override
  Widget build(BuildContext context) {
    final tokens = _tokensOf(context);
    return _PortalReviewInherited(
      enabled: _enabled,
      statuses: widget.statuses,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.sm),
                child: _ReviewTogglePill(enabled: _enabled, onTap: _toggle),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

class _ReviewTogglePill extends StatelessWidget {
  const _ReviewTogglePill({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = _tokensOf(context);
    final scheme = Theme.of(context).colorScheme;
    final label = enabled ? 'Hide review badges' : 'Show review badges';
    final fg = enabled ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: tokens.minTapTarget,
                minWidth: tokens.minTapTarget,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: tokens.typeScale.md, color: fg),
                      SizedBox(width: tokens.spacing.xs),
                      Text('Review',
                          style: tokens.textStyles.caption.copyWith(color: fg)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
