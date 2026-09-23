import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// Three dots that say the assistant is composing a reply.
///
/// Driven by [DesignTokens.motion]: one loop takes `motion.slow`, and each
/// dot's pulse starts `motion.staggerStep` after the one before it -- no
/// magic durations. Under [MediaQuery.disableAnimations] the ticker never
/// starts and the three dots hold still at full opacity, which still
/// announces "typing" without asking a reduce-motion device to animate.
class PortalTypingDots extends StatefulWidget {
  const PortalTypingDots({
    super.key,
    this.size,
    this.dotColor,
    this.semanticsLabel = 'Typing',
  });

  /// Dot diameter. Defaults to `tokens.spacing.sm`.
  final double? size;

  /// Defaults to `onSurfaceVariant`.
  final Color? dotColor;
  final String semanticsLabel;

  @override
  State<PortalTypingDots> createState() => _PortalTypingDotsState();
}

class _PortalTypingDotsState extends State<PortalTypingDots>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller == null) {
      final tokens = PortalUiTheme.of(context).tokens;
      _controller = AnimationController(
        vsync: this,
        duration: tokens.motion.slow,
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final dotSize = widget.size ?? tokens.spacing.sm;
    final dotColor = widget.dotColor ?? scheme.onSurfaceVariant;
    final controller = _controller;
    final staggerFraction =
        tokens.motion.staggerStep.inMilliseconds / tokens.motion.slow.inMilliseconds;

    Widget dot(int index) {
      if (controller == null) {
        return _Dot(size: dotSize, color: dotColor, opacity: 1, rise: 0);
      }
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          // One pulse per full loop, staggered by phase rather than by a
          // second timer -- a single controller stays in step under
          // hot-reload and never drifts between dots.
          final phase = (controller.value - index * staggerFraction) % 1.0;
          final bump = math.sin(phase * math.pi);
          return _Dot(
            size: dotSize,
            color: dotColor,
            opacity: 0.3 + bump * 0.7,
            rise: -bump * dotSize * 0.4,
          );
        },
      );
    }

    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) SizedBox(width: dotSize * 0.6),
            dot(i),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.size,
    required this.color,
    required this.opacity,
    required this.rise,
  });

  final double size;
  final Color color;
  final double opacity;
  final double rise;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, rise),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: SizedBox(width: size, height: size),
        ),
      ),
    );
  }
}
