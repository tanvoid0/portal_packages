import 'dart:async';

import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../motion/portal_spring_curve.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/design_tokens.dart';

/// Press state for anything tappable: shrinks to `tokens.motion.pressScale`
/// while held and springs back on release. A skin can also dip the opacity
/// on press (`PortalUiTheme.dip`) and suppress the overlay wash
/// (`PortalUiTheme.wash`); both default to "off" (dip 1, wash on), so a skin
/// that never sets them sees today's behavior unchanged.
///
/// Hosts the [InkWell] itself so the scale tracks Material's own notion of
/// "pressed" — a press that turns into a scroll releases; a hold stays pressed
/// until release, and with [onLongPress] set it releases when the long-press
/// fires. A tap always plays the press curve out before springing back, even
/// one so quick that Material's highlight came and went in a single event.
/// By default there is no ripple: the scale *is* the feedback. Pass [ripple]
/// for a control that should keep Material's splash as well; its child then
/// has to be an [Ink] (not a `DecoratedBox`) or the splash paints under the
/// background — and so does the focus/hover overlay when the child is opaque
/// (a [PortalCard]), which the touch fleet never sees but a desktop target
/// would want drawn as a focus border on the card instead.
///
/// Announces as a button when it has a handler (and as disabled when
/// [enabled] is false); with no handler it is plain content, so a display-only
/// pill stays a pill.
class PortalPressable extends StatefulWidget {
  const PortalPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.button,
    this.haptic,
    this.ripple = false,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// False refuses taps and announces disabled, keeping the layout. For "not
  /// a button at all" pass no handlers instead.
  final bool enabled;

  /// Announce as a button even with no handler (a disabled one), instead of
  /// as plain content. Null follows whether there is a handler.
  final bool? button;

  /// Played on tap, before [onTap]. Off by default: a card in a list should
  /// not buzz, a chip that changes selection should.
  final PortalHapticKind? haptic;

  /// Keep Material's splash on top of the scale. Off, the ink is [NoSplash]
  /// and the pressed overlay transparent.
  final bool ripple;

  /// Clips the ink (and hover/focus overlay) to the child's shape.
  final BorderRadius? borderRadius;

  /// Only read with [ripple].
  final Color? splashColor;
  final Color? highlightColor;

  @override
  State<PortalPressable> createState() => _PortalPressableState();
}

class _PortalPressableState extends State<PortalPressable> {
  // Press runs on the effects spring (never overshoots on the way down),
  // release on the spatial one so it lands with a little bounce.
  static final _press = PortalSpringCurve(PortalMotion.effectsFast);
  static final _release = PortalMotion.spatial;

  bool _pressed = false;

  // The press curve is still playing; a release that lands meanwhile waits for
  // it. Inside a scrollable the highlight is deferred until the arena resolves,
  // so a quick tap delivers down and up in one event and would otherwise never
  // render a pressed frame — no ripple, no scale, no feedback at all.
  Timer? _pulse;
  bool _releaseQueued = false;

  void _highlight(bool down) {
    if (down) {
      _pulse?.cancel();
      _releaseQueued = false;
      _pulse = Timer(_press.duration, () {
        _pulse = null;
        if (_releaseQueued) _settle();
      });
      setState(() => _pressed = true);
    } else if (_pulse != null) {
      _releaseQueued = true;
    } else {
      _settle();
    }
  }

  void _settle() {
    if (mounted) setState(() => _pressed = false);
  }

  void _tap() {
    if (widget.haptic case final kind?) PortalHaptics.play(kind);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _pulse?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portalUi = PortalUiTheme.of(context);
    final tokens = portalUi.tokens;
    final hasHandler = widget.onTap != null || widget.onLongPress != null;
    final interactive = widget.enabled && hasHandler;
    final curve = _pressed ? _press : _release;

    final isButton = widget.button ?? hasHandler;
    return Semantics(
      button: isButton,
      enabled: isButton ? widget.enabled : null,
      child: AnimatedOpacity(
        opacity: _pressed ? portalUi.dip : 1,
        duration: curve.duration,
        curve: curve,
        child: AnimatedScale(
          scale: _pressed ? tokens.motion.pressScale : 1,
          duration: curve.duration,
          curve: curve,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: interactive && widget.onTap != null ? _tap : null,
              onLongPress: interactive ? widget.onLongPress : null,
              onHighlightChanged: _highlight,
              borderRadius: widget.borderRadius,
              splashFactory: widget.ripple ? null : NoSplash.splashFactory,
              splashColor: widget.ripple ? widget.splashColor : null,
              highlightColor: !portalUi.wash
                  ? Colors.transparent
                  : (widget.ripple ? widget.highlightColor : Colors.transparent),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
