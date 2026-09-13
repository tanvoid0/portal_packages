import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../chat/ai_voice_session.dart';

/// The voice conversation's face: a liquid orb that breathes, wanders, and
/// swells with whoever is talking, with the phase typed out beneath it.
///
/// Ported from agent-platform's E.V. orb. Its constants were measured off a
/// reference loop frame by frame, and they are kept as measured: radius
/// breathes about 8% on a 2-3 s cycle, the orb wanders within a tenth of its
/// radius, the edge is two shells that never breathe in step, and the
/// interior rotates rose, periwinkle and mint rather than lerping through
/// grey. The shader had a fragment per pixel; here the edge is a path of a
/// hundred points and the soft falloffs are gradients, which Flutter's canvas
/// has and iced's did not.
///
/// Energy is the microphone while listening and a synthetic pulse while
/// speaking -- Android's TTS reports no output level. Smoothed on the way up
/// as well as down, because snapping to a consonant stepped the radius by a
/// whole syllable in one frame, which is a visible pop; `beat` is the channel
/// that still carries the transient.
class AiVoiceOrb extends StatefulWidget {
  const AiVoiceOrb({
    super.key,
    required this.phase,
    required this.level,
    required this.label,
    this.size = 340,
  });

  final AiVoicePhase phase;

  /// Microphone loudness, 0 to 1. Only read while listening.
  final ValueListenable<double> level;

  /// Typed out under the orb, and announced to a screen reader when it
  /// changes.
  final String label;

  final double size;

  @override
  State<AiVoiceOrb> createState() => _AiVoiceOrbState();
}

class _AiVoiceOrbState extends State<AiVoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  double _energy = 0;
  double _beat = 0;

  /// Animation clock. Advanced faster while thinking, so the churn reads as
  /// work without the orb having a notion of phase.
  double _time = 0;
  double _last = 0;

  /// Seconds since the phase last changed; the label types itself in from
  /// zero on every change, so a new state needs no extra reveal state.
  double _elapsed = 0;

  /// The previous phase's hue, mixed toward the current one over [_mix].
  Color? _fromHue;
  double _mix = 1;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_step)
      ..forward();
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AiVoiceOrb old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) {
      _fromHue = _hue(old.phase, Theme.of(context).colorScheme);
      _mix = 0;
      _elapsed = 0;
    }
  }

  void _step() {
    final now = (_tick.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = math.min(now - _last, 0.1);
    _last = now;
    _time += dt * (widget.phase == AiVoicePhase.thinking ? 1.9 : 1.0);
    _elapsed += dt;
    _mix = math.min(1, _mix + dt * 2.5);

    final loud = switch (widget.phase) {
      AiVoicePhase.listening => (widget.level.value * 1.2).clamp(0.0, 1.0),
      AiVoicePhase.thinking => 0.15 + 0.1 * math.sin(_time * 2),
      // A syllable-ish pulse: two rates beating against each other so it
      // never reads as a metronome.
      AiVoicePhase.speaking =>
        0.35 +
            0.3 *
                (0.5 + 0.5 * math.sin(_time * 6.1)) *
                (0.6 + 0.4 * math.sin(_time * 1.7)),
    };
    final jump = math.max(0.0, loud - _energy);
    _energy += (loud - _energy) * (loud > _energy ? 0.35 : 0.08);
    _beat = math.max(_beat * 0.88, math.min(1, jump * 5));
    setState(() {});
  }

  static Color _hue(AiVoicePhase phase, ColorScheme scheme) => switch (phase) {
    AiVoicePhase.listening => scheme.error,
    AiVoicePhase.thinking => scheme.tertiary,
    AiVoicePhase.speaking => scheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _tick.isAnimating) _tick.stop();
    if (!still && !_tick.isAnimating) _tick.forward();

    final target = _hue(widget.phase, scheme);
    final eased = 1 - math.pow(1 - _mix, 3).toDouble();
    final accent = Color.lerp(_fromHue ?? target, target, eased)!;
    final dark = theme.brightness == Brightness.dark;
    // In light mode every hue is inked a little toward black, or the halo
    // vanishes into the paper.
    Color ink(Color c) => dark ? c : Color.lerp(c, Colors.black, 0.18)!;
    // The partners lean far harder toward their own hue than the mode's: a
    // monochrome orb read as a flat disc, not glass.
    final cool = ink(Color.lerp(accent, const Color(0xFF3FE0FF), 0.72)!);
    final warm = ink(Color.lerp(accent, const Color(0xFFFF6BD1), 0.72)!);

    final typed = still
        ? widget.label
        : widget.label.substring(
            0,
            math.min(widget.label.length, (_elapsed * 18).floor()),
          );

    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _OrbPainter(
                  time: still ? 0 : _time,
                  energy: still ? 0.2 : _energy,
                  beat: still ? 0 : _beat,
                  accent: ink(accent),
                  cool: cool,
                  warm: warm,
                  paper: scheme.surface,
                ),
              ),
            ),
          ),
          SizedBox(height: widget.size * 0.08),
          // Fixed height so the line does not jump as the label types in.
          SizedBox(
            height: 28,
            child: Text(typed, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.time,
    required this.energy,
    required this.beat,
    required this.accent,
    required this.cool,
    required this.warm,
    required this.paper,
  });

  final double time;
  final double energy;
  final double beat;
  final Color accent;
  final Color cool;
  final Color warm;
  final Color paper;

  static const _points = 100;

  /// The liquid edge: integer harmonics in the angle, phases drifting at
  /// unrelated rates so the shape never visibly repeats. Each harmonic is
  /// voiced by a different part of the signal -- speaking does not just
  /// inflate the orb: the slow two-lobe stretch swells with energy, the
  /// three-lobe roll with it too, and a transient snaps the fine ripple.
  static double _morph(double a, double t, double e, double k) {
    final n2 = math.sin(2 * a + t * 0.61) * (0.55 + 0.45 * e);
    final n3 = math.sin(3 * a - t * 0.47 + 1.3) * (0.35 + 0.35 * e);
    final n4 = math.sin(4 * a + t * 0.33 + 2.7) * (0.18 + 0.40 * k);
    return (n2 + n3 + n4) / 1.9;
  }

  Path _shell(Offset c, double r, double amp, double tOffset) {
    final path = Path();
    for (var i = 0; i <= _points; i++) {
      final a = i / _points * 2 * math.pi;
      final rr = r * (1 + amp * _morph(a, time + tOffset, energy, beat));
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time;
    final unit = size.shortestSide / 2;
    final centre = Offset(size.width / 2, size.height / 2);

    // The whole orb wanders about a tenth of its radius. Wider reads as the
    // widget sliding, not the orb breathing.
    final drift = Offset(
      math.sin(t * 0.23) * 0.6 + math.sin(t * 0.41 + 1.7) * 0.4,
      math.cos(t * 0.19 + 0.8) * 0.6 + math.sin(t * 0.31 + 2.3) * 0.4,
    );
    // Radius breathes about 8% on a 2-3 s cycle, and swells with the voice.
    final r = unit * 0.38 * (1 + 0.08 * math.sin(t * 0.5) + 0.15 * energy);
    final c = centre + drift * 0.10 * r;
    // Eccentricity: longest over shortest radius about 1.15 at rest, half
    // again as much on a loud syllable.
    final amp = 0.075 + 0.125 * energy;

    // -- Halo: reaches ~2.1 radii, brighter on a transient -----------------
    final haloR = r * 2.1;
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.28 + 0.25 * beat),
            accent.withValues(alpha: 0.08),
            accent.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: haloR)),
    );

    // -- Second shell: fainter, fatter, offset, out of step --------------------
    final c2 = c + Offset(math.sin(t * 0.17 + 1.1), math.cos(t * 0.21 + 0.4)) * 0.10 * r;
    canvas.drawPath(
      _shell(c2, r * 1.03, amp * 1.3, 11),
      Paint()
        ..color = cool.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
    );

    // -- The orb ------------------------------------------------------------
    final edge = _shell(c, r, amp, 0);
    // A sweep across the sphere carries the hue; three weights rotated over
    // time rather than a lerp, which walks through grey in the middle.
    final ic = t * 0.30;
    Color at(double sweep) {
      final k = sweep * 2.6 + ic;
      final v1 = 0.5 + 0.5 * math.sin(k);
      final v2 = 0.5 + 0.5 * math.sin(k + 2.0944);
      final v3 = 0.5 + 0.5 * math.sin(k + 4.1888);
      final sum = v1 + v2 + v3;
      return Color.fromARGB(
        255,
        ((warm.r * v1 + cool.r * v2 + accent.r * v3) / sum * 255).round(),
        ((warm.g * v1 + cool.g * v2 + accent.g * v3) / sum * 255).round(),
        ((warm.b * v1 + cool.b * v2 + accent.b * v3) / sum * 255).round(),
      );
    }

    final mass = Offset(math.sin(t * 0.11) * 0.45, math.cos(t * 0.09 + 3.7) * 0.45);
    canvas.drawPath(
      edge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-0.45 + mass.dx, 0.72 + mass.dy),
          end: Alignment(0.45 - mass.dx, -0.72 - mass.dy),
          colors: [at(0), at(0.5), at(1)],
        ).createShader(edge.getBounds()),
    );
    // Glass: a soft light toward the top-left, and the paper showing through
    // at the rim so the orb reads as a volume rather than a sticker.
    canvas.drawPath(
      edge,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0),
            paper.withValues(alpha: 0.25),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(edge.getBounds()),
    );
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.02)
        ..color = accent.withValues(alpha: 0.5 + 0.4 * beat),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => true;
}
