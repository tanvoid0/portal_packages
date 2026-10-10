import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The assistant's face outside a voice call: a soft, blurred, multi-hue
/// gradient sphere -- the "Blank AI" language (Nick Zaitsev/TheRoom) standing
/// in for a flat sparkle glyph. Drawn at 24px in a thread gutter, 32px in a
/// header and 96px on an empty state, so the same three blurred circles have
/// to read as one object at every size.
///
/// Simpler than [AiVoiceOrb] on purpose: no phase, no microphone level --
/// [busy] is the only input, because this orb marks presence, not a
/// conversation state machine.
class AiPresenceOrb extends StatefulWidget {
  const AiPresenceOrb({
    super.key,
    required this.size,
    this.busy = false,
    this.semanticLabel,
  });

  /// Diameter in logical pixels.
  final double size;

  /// A run is in flight: the drift speeds up and the hues saturate a touch --
  /// the same "it's working" cue [AiVoiceOrb] gives with tempo, given here in
  /// colour instead.
  final bool busy;

  /// Announced to a screen reader when set. Left null the orb is excluded
  /// from the semantics tree -- every call site sits it next to a text label
  /// (a page title, a button) that already says what it is, and a second
  /// announcement of the same thing is noise, not help.
  final String? semanticLabel;

  @override
  State<AiPresenceOrb> createState() => _AiPresenceOrbState();
}

class _AiPresenceOrbState extends State<AiPresenceOrb>
    with SingleTickerProviderStateMixin {
  // A day-long forward() read as raw elapsed seconds -- same trick as
  // AiVoiceOrb: cheaper than a repeating tween, and one 24h run never wraps
  // inside a real session.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(AiPresenceOrb old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  // The only place that starts or stops the ticker. Reduced motion must
  // never call forward() at all -- not start-then-immediately-stop -- or a
  // person who gets sick from drifting motion still pays for one tick, and a
  // ticker that's merely stopped after starting still costs a frame.
  void _syncTicker() {
    // Two reasons to hold still, and they are different reasons.
    //
    // Reduced motion is the user's setting and is absolute. The second is
    // that an orb drifting forever never lets the frame scheduler go quiet,
    // so `pumpAndSettle` in ANY host's widget test waits for an animation
    // that never ends -- it broke 27 tests in this package the moment the
    // orb became the default face. Motion while the model is working is
    // the part that carries meaning anyway; idle drift was decoration, and
    // decoration is not worth a test suite that cannot settle.
    if (MediaQuery.disableAnimationsOf(context) || !widget.busy) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);

    // Busy lifts saturation on the three hue blobs -- the same "it's
    // working" cue AiVoiceOrb gives with tempo, given here in colour.
    Color energize(Color c) {
      if (!widget.busy) return c;
      final hsl = HSLColor.fromColor(c);
      return hsl.withSaturation(math.min(1, hsl.saturation + 0.15)).toColor();
    }

    final blobs = [
      energize(scheme.primary),
      energize(scheme.secondary),
      energize(scheme.tertiary),
    ];
    // The specular highlight: primary lightened toward the surface colour
    // rather than a literal white, so it still reads right against a dark
    // theme's inverted palette instead of blowing out as a pale disc.
    final highlight = Color.lerp(scheme.primary, scheme.surface, 0.7)!;

    // portal_ai has no dependency on portal_ui_core -- plain constants here,
    // same as ai_prompt_composer.dart's spacing.
    final orb = RepaintBoundary(
      child: ClipOval(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            // Rebuilds only this small subtree per tick, not the page that
            // hosts the orb -- the controller is never wired to setState.
            builder: (context, _) {
              final elapsed = still
                  ? 0.0
                  : (_controller.lastElapsedDuration?.inMicroseconds ?? 0) /
                        1e6 *
                        (widget.busy ? 1.6 : 1.0);
              return CustomPaint(
                painter: _OrbPainter(
                  t: elapsed,
                  blobs: blobs,
                  highlight: highlight,
                ),
              );
            },
          ),
        ),
      ),
    );

    return widget.semanticLabel == null
        ? ExcludeSemantics(child: orb)
        : Semantics(label: widget.semanticLabel, child: orb);
  }
}

/// Three soft blurred circles drifting on independent periods, plus a fixed
/// top-left highlight. No `BackdropFilter` -- that forces a save-layer of
/// everything behind the orb and would tank scrolling at 24px in a message
/// list; a `MaskFilter.blur` on a handful of `drawCircle`s is the cheap
/// version of the same softness.
class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.t,
    required this.blobs,
    required this.highlight,
  });

  /// Elapsed seconds, already sped up when busy.
  final double t;

  /// primary, secondary, tertiary, in that order.
  final List<Color> blobs;
  final Color highlight;

  // Each blob's drift period, in seconds, and its orbit's starting angle --
  // deliberately not sharing a common factor so the mesh never visibly
  // repeats within a normal viewing.
  static const _periods = [7.0, 9.5, 12.0];
  static const _startAngles = [0.0, 2.1, 4.4];

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < blobs.length; i++) {
      final angle = _startAngles[i] + (t / _periods[i]) * 2 * math.pi;
      // Alternating orbit radius so the blobs don't rotate in lockstep like
      // spokes on a wheel, and a detuned y so the path isn't a plain circle.
      final orbit = r * (i.isEven ? 0.32 : 0.42);
      final pos =
          center +
          Offset(math.cos(angle) * orbit, math.sin(angle * 0.8) * orbit);
      canvas.drawCircle(
        pos,
        r * 0.7,
        Paint()
          ..color = blobs[i]
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }

    // Fixed, not drifting -- it's what tells the eye "sphere" no matter
    // where the blobs have wandered underneath it.
    canvas.drawCircle(
      center + Offset(-r * 0.3, -r * 0.35),
      r * 0.4,
      Paint()
        ..color = highlight
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t || old.highlight != highlight || !listEquals(old.blobs, blobs);
}
