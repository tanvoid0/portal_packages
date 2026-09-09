import 'package:flutter/material.dart';

/// One named piece of startup work.
///
/// The label is what the person waiting reads, so name the thing being done
/// ("Checking your session"), not the code doing it ("PortalBootstrap.init").
class PortalStartupStep {
  const PortalStartupStep(this.label, this.run);

  final String label;
  final Future<void> Function() run;
}

/// The screen shown while an app boots.
///
/// Every Portal app used to do its whole bootstrap before `runApp`, which
/// means the native splash sat frozen for as long as that took and a slow
/// session check was indistinguishable from a hang. This shows a breathing
/// mark, a progress bar and the name of the step actually running, so the
/// wait reads as work.
class PortalStartupSplash extends StatefulWidget {
  const PortalStartupSplash({
    super.key,
    required this.icon,
    required this.title,
    required this.stepCount,
    required this.stepIndex,
    required this.stepLabel,
    this.subtitle,
    this.error,
    this.traceId,
    this.traceIdLabel,
    this.onCopyTraceId,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Total steps, and the index of the one running now (0-based).
  final int stepCount;
  final int stepIndex;
  final String stepLabel;

  final Object? error;
  final String? traceId;

  /// Overrides the default "Trace ID: x" line, for apps that translate it.
  final String? traceIdLabel;

  /// Adds a copy button under the trace id.
  final VoidCallback? onCopyTraceId;

  final VoidCallback? onRetry;

  @override
  State<PortalStartupSplash> createState() => _PortalStartupSplashState();
}

class _PortalStartupSplashState extends State<PortalStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(PortalStartupSplash old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  /// Breathes only while the app is still starting: a failed run is a screen
  /// to read, not one to animate, and it never settles for a widget test.
  void _syncPulse() {
    final wanted =
        widget.error == null && !MediaQuery.disableAnimationsOf(context);
    if (wanted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!wanted && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final failed = widget.error != null;
    final still = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            children: [
              const Spacer(flex: 3),
              _Mark(
                icon: failed ? Icons.error_outline : widget.icon,
                color: failed ? colors.error : colors.primary,
                pulse: still || failed ? null : _pulse,
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(flex: 4),
              if (failed)
                _Failure(
                  error: widget.error!,
                  traceId: widget.traceId,
                  traceIdLabel: widget.traceIdLabel,
                  onCopyTraceId: widget.onCopyTraceId,
                  onRetry: widget.onRetry,
                )
              else
                _Progress(
                  stepCount: widget.stepCount,
                  stepIndex: widget.stepIndex,
                  stepLabel: widget.stepLabel,
                  animate: !still,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app glyph, breathing inside a soft well.
class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.color, this.pulse});

  final IconData icon;
  final Color color;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    final well = Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 52, color: color),
    );

    final animation = pulse;
    if (animation == null) return well;

    final curve = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      child: well,
      builder: (context, child) => Transform.scale(
        scale: 0.94 + curve.value * 0.10,
        child: Opacity(opacity: 0.80 + curve.value * 0.20, child: child),
      ),
    );
  }
}

/// Bar, current step name, and how far through we are.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.stepCount,
    required this.stepIndex,
    required this.stepLabel,
    required this.animate,
  });

  final int stepCount;
  final int stepIndex;
  final String stepLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Fills as each step *completes*, so the bar never claims to be done
    // while the last step is still running.
    final value = stepCount == 0 ? 0.0 : stepIndex / stepCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: Duration(milliseconds: animate ? 400 : 0),
            curve: Curves.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: colors.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: Duration(milliseconds: animate ? 220 : 0),
          child: Text(
            stepLabel,
            key: ValueKey(stepLabel),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Step ${(stepIndex + 1).clamp(1, stepCount)} of $stepCount',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.error,
    this.traceId,
    this.traceIdLabel,
    this.onCopyTraceId,
    this.onRetry,
  });

  final Object error;
  final String? traceId;
  final String? traceIdLabel;
  final VoidCallback? onCopyTraceId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Could not start the app', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (traceId != null) ...[
          const SizedBox(height: 12),
          SelectableText(
            traceIdLabel ?? 'Trace ID: $traceId',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: colors.onSurfaceVariant,
            ),
          ),
          if (onCopyTraceId != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCopyTraceId,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy trace ID'),
            ),
          ],
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ],
    );
  }
}
