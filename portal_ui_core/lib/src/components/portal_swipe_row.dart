import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
  /// has slid out and collapsed, so remove the item from the list *here*.
  final VoidCallback onTrigger;

  /// Asked before [onTrigger] once the swipe completes; false springs the row
  /// back untouched. The row holds where it was released while this answers. `() => portalConfirm(context, …)` is the usual answer.
  final Future<bool> Function()? confirm;

  /// Whether the row leaves the list. False for a toggle (complete, pin,
  /// snooze): [onTrigger] fires at the release point and the row springs back
  /// from there, carrying the finger's velocity.
  final bool dismisses;
}

/// A list row that swipes to act — the fleet's swipe-to-act row.
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
/// The gesture is the kit's own, not `Dismissible`'s (F3):
///
/// * the settle starts at the drag's velocity, so a fling carries through
///   instead of springing from rest;
/// * past the threshold the row pulls back on a rubber band rather than
///   stopping dead, and can never travel further than its own width;
/// * an interrupted drag — a second finger, the parent list stealing the
///   gesture, the app going to the background — settles the row closed;
/// * a fling over 700 px/s triggers even short of the threshold, the number
///   `Dismissible` uses.
///
/// Takes a required [key] so a row that has been dismissed does not hand its
/// state to the item that moves into its slot.
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

/// What the background needs from the drag, and nothing the child needs.
@immutable
class _Drag {
  const _Drag(this.sign, this.progress, this.reached);
  const _Drag.rest()
      : sign = 0,
        progress = 0,
        reached = false;

  /// 1 pulled toward the end edge, -1 toward the start, 0 at rest.
  final int sign;

  /// Fraction of the row's width the finger has pulled, after resistance.
  final double progress;

  /// Whether letting go now would trigger.
  final bool reached;
}

class _PortalSwipeRowState extends State<PortalSwipeRow>
    with TickerProviderStateMixin {
  /// Fraction of the width a swipe must pass to trigger; the icon's growth
  /// and the trigger read the same number.
  static const _threshold = 0.4;

  /// Icon scale at rest and at the threshold; the pop on crossing goes past
  /// [_poppedScale] on the spring.
  static const _restScale = 0.7;
  static const _poppedScale = 1.2;

  /// Rubber band past the threshold: [_travel] is the distance left and
  /// `k` is how hard the row resists, so the offset approaches the row's own
  /// width and never passes it.
  static const _travel = 1 - _threshold;
  static const _resistance = 0.8;

  /// px/s that triggers on its own, short of the threshold — `Dismissible`'s
  /// `_kMinFlingVelocity`.
  static const _flingVelocity = 700.0;

  static final _pop = PortalSpringCurve(PortalMotion.spatialFast);

  /// Signed fraction of the row's width, driven by the finger and then by a
  /// spring. Unbounded because a spring overshoots.
  late final AnimationController _move =
      AnimationController.unbounded(vsync: this)..addListener(_report);

  /// 1 at full height, 0 collapsed — the gap closing after a dismissal.
  late final AnimationController _collapse =
      AnimationController(vsync: this, value: 1);

  /// Only the background listens: the child must not rebuild per drag frame.
  final _drag = ValueNotifier<_Drag>(const _Drag.rest());

  double _dragExtent = 0;
  double _width = 0;
  bool _reached = false;

  /// A pointer cancel — the app going to the background, the platform taking
  /// the touch — reaches the drag recognizer as an *end* with no velocity,
  /// which is indistinguishable from a deliberate release past the threshold.
  /// The [Listener] below sees the cancel first (recognizers are routed after
  /// the hit-test path) and marks it, so the row settles instead of firing.
  bool _cancelled = false;
  TextDirection _textDirection = TextDirection.ltr;
  bool _reduceMotion = false;

  bool get _enabled => widget.leading != null || widget.trailing != null;

  /// Which action a pull in [sign] reveals, or null if that way is not armed.
  PortalSwipeAction? _actionFor(int sign) {
    if (sign == 0) return null;
    final startToEnd = (sign > 0) == (_textDirection == TextDirection.ltr);
    return startToEnd ? widget.leading : widget.trailing;
  }

  /// The banded offset for a raw drag fraction: linear to the threshold, then
  /// `o·d·k / (d + k·o)`, which approaches [_travel] as the finger keeps
  /// going.
  double _resist(double raw) {
    final over = raw.abs() - _threshold;
    if (over <= 0) return raw;
    final band = over * _travel * _resistance / (_travel + _resistance * over);
    return (raw.isNegative ? -1 : 1) * (_threshold + band);
  }

  void _report() {
    final value = _move.value;
    final sign = value == 0 ? 0 : (value > 0 ? 1 : -1);
    _drag.value = _Drag(sign, value.abs().clamp(0.0, 1.0), _reached);
  }

  void _onDragStart(DragStartDetails _) {
    _cancelled = false;
    _move.stop();
    _dragExtent = _move.value * (_width == 0 ? 1 : _width);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // No measured width yet means no fraction to compute: the row holds.
    if (_width <= 0) return;
    final width = _width;
    _dragExtent += details.primaryDelta ?? 0;
    final raw = _dragExtent / width;
    final sign = raw == 0 ? 0 : (raw > 0 ? 1 : -1);
    // A pull the row is not armed for does not move it, and does not bank
    // distance for when the finger comes back the other way.
    if (_actionFor(sign) == null) {
      _dragExtent = 0;
      _setReached(false);
      _move.value = 0;
      return;
    }
    _setReached(raw.abs() >= _threshold);
    _move.value = _resist(raw);
  }

  void _setReached(bool reached) {
    if (reached == _reached) return;
    if (reached) PortalHaptics.medium();
    _reached = reached;
  }

  /// Spring back to rest from wherever the finger left the row. A spring
  /// stops within a tolerance of its target, so the row is snapped the last
  /// sub-pixel home: an interrupted drag must leave no offset at all.
  TickerFuture _settle(double velocity) {
    _setReached(false);
    final settled = _animate(0, velocity, PortalMotion.spatialDefault);
    settled.orCancel.then(
      (_) {
        if (mounted) _move.value = 0;
      },
      // Cancelled means a new drag took the row over; it owns the offset now.
      onError: (_) {},
    );
    return settled;
  }

  TickerFuture _animate(
    double target,
    double velocity,
    SpringDescription spring,
  ) {
    if (_reduceMotion) {
      _move.value = target;
      _report();
      return TickerFuture.complete();
    }
    return _move.animateWith(
      SpringSimulation(spring, _move.value, target, velocity),
    );
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final width = _width <= 0 ? 1.0 : _width;
    final pixels = details.velocity.pixelsPerSecond.dx;
    final velocity = pixels / width;
    final value = _move.value;
    final sign = value == 0 ? 0 : (value > 0 ? 1 : -1);
    final action = _actionFor(sign);
    // A fling counts only while it is still travelling the way the row is
    // pulled — a flick back is a cancel, not a trigger.
    final flung = pixels.abs() >= _flingVelocity && (pixels > 0) == (value > 0);
    if (_cancelled || action == null || !(value.abs() >= _threshold || flung)) {
      _settle(velocity);
      return;
    }
    if (action.confirm != null && !await action.confirm!()) {
      if (mounted) _settle(velocity);
      return;
    }
    if (!mounted) return;
    if (!action.dismisses) {
      action.onTrigger();
      _settle(velocity);
      return;
    }
    _setReached(false);
    await _animate(sign.toDouble(), velocity, PortalMotion.spatialFast);
    if (!mounted) return;
    if (_reduceMotion) {
      _collapse.value = 0;
    } else {
      await _collapse.reverse(from: 1);
    }
    if (mounted) action.onTrigger();
  }

  void _onDragCancel() {
    _cancelled = true;
    _settle(0);
  }

  void _onPointerCancel(PointerCancelEvent _) => _cancelled = true;

  Future<void> _fromSemantics(PortalSwipeAction action) async {
    if (action.confirm == null || await action.confirm!()) action.onTrigger();
  }

  @override
  void dispose() {
    _move.dispose();
    _collapse.dispose();
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    _textDirection = Directionality.of(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _collapse.duration = tokens.motion.medium;
    final actions = {
      for (final action in [widget.leading, widget.trailing].nonNulls)
        CustomSemanticsAction(label: action.label): () =>
            _fromSemantics(action),
    };

    return Semantics(
      customSemanticsActions: actions.isEmpty ? null : actions,
      child: SizeTransition(
        sizeFactor: _collapse,
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth.isFinite ? constraints.maxWidth : 0;
            return Listener(
              onPointerCancel: _enabled ? _onPointerCancel : null,
              child: GestureDetector(
                onHorizontalDragStart: _enabled ? _onDragStart : null,
                onHorizontalDragUpdate: _enabled ? _onDragUpdate : null,
                onHorizontalDragEnd: _enabled ? _onDragEnd : null,
                onHorizontalDragCancel: _enabled ? _onDragCancel : null,
                child: Stack(
                  children: [
                    Positioned.fill(child: _backgroundLayer(tokens)),
                    AnimatedBuilder(
                      animation: _move,
                      child: widget.child,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_move.value * _width, 0),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _backgroundLayer(DesignTokens tokens) {
    return ValueListenableBuilder<_Drag>(
      valueListenable: _drag,
      builder: (context, drag, _) {
        final action = _actionFor(drag.sign);
        if (action == null) return const SizedBox.shrink();
        final startToEnd =
            (drag.sign > 0) == (_textDirection == TextDirection.ltr);
        return _background(action, startToEnd, drag, tokens);
      },
    );
  }

  Widget _background(
    PortalSwipeAction action,
    bool startToEnd,
    _Drag drag,
    DesignTokens tokens,
  ) {
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
        alignment: startToEnd
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
        decoration: BoxDecoration(
          color: action.foregroundColor.withValues(alpha: 0.18),
          borderRadius: widget.borderRadius,
        ),
        child: AnimatedScale(
          scale: drag.reached ? _poppedScale : 1,
          duration: _reduceMotion ? Duration.zero : _pop.duration,
          curve: _pop,
          child: Transform.scale(
            scale: lerpDouble(
              _restScale,
              1,
              (drag.progress / _threshold).clamp(0, 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (startToEnd) icon else label,
                SizedBox(width: tokens.spacing.sm),
                if (startToEnd) label else icon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
