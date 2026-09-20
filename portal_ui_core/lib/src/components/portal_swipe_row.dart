import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../motion/portal_haptics.dart';
import '../motion/portal_spring_curve.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';

/// One thing a swipe can do: what it shows while the row is pulled, and what
/// happens when it is let go past the threshold.
class PortalSwipeAction {
  const PortalSwipeAction({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.onTrigger,
    this.confirm,
    this.dismisses = true,
  });

  final IconData icon;

  /// Drawn beside the icon and read out as the custom semantics action.
  final String label;

  /// Paints the icon and label, and tints the revealed background — pass a
  /// role (`PortalSemanticColors.of(context).danger`, `colorScheme.primary`),
  /// never a hex.
  final Color foregroundColor;

  /// Fires once per trigger. For a [dismisses] action it fires after the row
  /// has slid out and collapsed, so remove the item from the list *here* —
  /// `Dismissible` throws if the row is still in the tree on the next build.
  final VoidCallback onTrigger;

  /// Asked before [onTrigger] once the swipe completes; false springs the row
  /// back untouched. `() => portalConfirm(context, …)` is the usual answer.
  final Future<bool> Function()? confirm;

  /// Whether the row leaves the list. False for a toggle (complete, pin,
  /// snooze): the row completes its slide-out, [onTrigger] fires, and it
  /// slides back — `Dismissible` only asks `confirmDismiss` once the row is
  /// fully out, so a toggle is a blink, not a settle from the release point.
  final bool dismisses;
}

/// A list row that swipes to act — the fleet's `Dismissible`.
///
/// [leading] answers a swipe from the start edge, [trailing] one from the end
/// edge; either may be omitted, and with neither the row does not move. The
/// revealed background is a tint of the action's colour with its icon and
/// label; the icon grows as the finger nears the threshold (40% of the width)
/// and pops on the spatial spring, with one medium haptic, the moment it is
/// crossed. Both actions are exposed as custom semantics actions, so a screen
/// reader triggers them without the gesture — which only lands on the row's
/// node if [child] is not a semantics boundary: `PortalCard` and `ListTile`
/// are fine, a Material `Card` needs `semanticContainer: false`.
///
/// Built over [Dismissible] — the gesture, fling detection, threshold and
/// slide-out are Material's. That also means the row's own settle after a
/// release is Material's linear [Dismissible.movementDuration] (here
/// `tokens.motion.fast`), not a spring: the spring is on the icon.
///
/// Takes a required [key] for the same reason `Dismissible` does: a row that
/// has been dismissed must not have its state handed to the item that moves
/// into its slot.
class PortalSwipeRow extends StatefulWidget {
  const PortalSwipeRow({
    required Key key,
    required this.child,
    this.leading,
    this.trailing,
    this.borderRadius,
  }) : super(key: key);

  final Widget child;

  /// Revealed by a start-to-end swipe (rightward in LTR).
  final PortalSwipeAction? leading;

  /// Revealed by an end-to-start swipe.
  final PortalSwipeAction? trailing;

  /// Rounds the revealed background to match a card [child]. Null is square,
  /// for a plain list row.
  final BorderRadius? borderRadius;

  @override
  State<PortalSwipeRow> createState() => _PortalSwipeRowState();
}

class _PortalSwipeRowState extends State<PortalSwipeRow> {
  /// Same fraction `Dismissible` uses when none is given; passed explicitly
  /// so the icon's growth and the trigger agree.
  static const _threshold = 0.4;

  /// Icon scale at rest and at the threshold; the pop on crossing goes past
  /// [_poppedScale] on the spring.
  static const _restScale = 0.7;
  static const _poppedScale = 1.2;

  static final _pop = PortalSpringCurve(PortalMotion.spatialFast);

  /// Only the background listens: the child must not rebuild per drag frame.
  final _drag = ValueNotifier<DismissUpdateDetails?>(null);

  PortalSwipeAction? _actionFor(DismissDirection direction) =>
      switch (direction) {
        DismissDirection.startToEnd => widget.leading,
        DismissDirection.endToStart => widget.trailing,
        _ => null,
      };

  DismissDirection get _direction {
    if (widget.leading != null && widget.trailing != null) {
      return DismissDirection.horizontal;
    }
    if (widget.leading != null) return DismissDirection.startToEnd;
    if (widget.trailing != null) return DismissDirection.endToStart;
    return DismissDirection.none;
  }

  void _onUpdate(DismissUpdateDetails details) {
    if (details.reached && !details.previousReached) PortalHaptics.medium();
    _drag.value = details;
  }

  Future<bool> _allowed(PortalSwipeAction action) async =>
      action.confirm == null || await action.confirm!();

  /// Dismissible has already slid the row out when it asks. A dismissing
  /// action fires from [Dismissible.onDismissed] once the row has collapsed;
  /// a toggle fires now and returns false so the row slides back.
  Future<bool> _confirmDismiss(DismissDirection direction) async {
    final action = _actionFor(direction);
    if (action == null || !await _allowed(action)) return false;
    if (action.dismisses) return true;
    action.onTrigger();
    return false;
  }

  Future<void> _fromSemantics(PortalSwipeAction action) async {
    if (await _allowed(action)) action.onTrigger();
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final leading = widget.leading;
    final trailing = widget.trailing;
    final actions = {
      for (final action in [leading, trailing].nonNulls)
        CustomSemanticsAction(label: action.label): () =>
            _fromSemantics(action),
    };

    return Semantics(
      customSemanticsActions: actions.isEmpty ? null : actions,
      child: Dismissible(
        key: const ValueKey('portal_swipe_row'),
        direction: _direction,
        dismissThresholds: const {
          DismissDirection.startToEnd: _threshold,
          DismissDirection.endToStart: _threshold,
        },
        movementDuration: tokens.motion.fast,
        resizeDuration: tokens.motion.medium,
        onUpdate: _onUpdate,
        confirmDismiss: _confirmDismiss,
        onDismissed: (direction) => _actionFor(direction)?.onTrigger(),
        // `secondaryBackground` needs `background`; a trailing-only row
        // shows its one background for its one direction.
        background: leading != null
            ? _background(leading, DismissDirection.startToEnd, tokens)
            : trailing != null
                ? _background(trailing, DismissDirection.endToStart, tokens)
                : null,
        secondaryBackground: leading != null && trailing != null
            ? _background(trailing, DismissDirection.endToStart, tokens)
            : null,
        child: widget.child,
      ),
    );
  }

  Widget _background(
    PortalSwipeAction action,
    DismissDirection direction,
    DesignTokens tokens,
  ) {
    final start = direction == DismissDirection.startToEnd;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final icon = Icon(action.icon, color: action.foregroundColor);
    final label = Text(
      action.label,
      style: tokens.textStyles
          .emphasized(tokens.textStyles.body)
          .copyWith(color: action.foregroundColor),
    );
    // Decorative: the label would otherwise merge into the row's own
    // semantics; the custom action already carries it.
    return ExcludeSemantics(
      child: Container(
        alignment: start
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
        decoration: BoxDecoration(
          color: action.foregroundColor.withValues(alpha: 0.18),
          borderRadius: widget.borderRadius,
        ),
        child: ValueListenableBuilder<DismissUpdateDetails?>(
          valueListenable: _drag,
          builder: (context, drag, content) {
            final active = drag != null && drag.direction == direction;
            final progress = active ? drag.progress : 0.0;
            final reached = active && drag.reached;
            return AnimatedScale(
              scale: reached ? _poppedScale : 1,
              duration: reduceMotion ? Duration.zero : _pop.duration,
              curve: _pop,
              child: Transform.scale(
                scale: lerpDouble(
                  _restScale,
                  1,
                  (progress / _threshold).clamp(0, 1),
                ),
                child: content,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (start) icon else label,
              SizedBox(width: tokens.spacing.sm),
              if (start) label else icon,
            ],
          ),
        ),
      ),
    );
  }
}
