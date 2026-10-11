import 'package:flutter/material.dart';
import '../theme/portal_ui_theme.dart';

/// Pulsing placeholder block (shadcn Skeleton).
class PortalSkeleton extends StatefulWidget {
  const PortalSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  State<PortalSkeleton> createState() => _PortalSkeletonState();
}

class _PortalSkeletonState extends State<PortalSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final radius = widget.shape == BoxShape.circle 
        ? null 
        : widget.borderRadius ?? BorderRadius.circular(t.radii.sm);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final a = Curves.easeInOut.transform(_c.value);
        final base = portal.muted;
        final hi = portal.surfaceVariant.withValues(alpha: 0.9);
        final c = Color.lerp(base, hi, a)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c,
            borderRadius: radius,
            shape: widget.shape,
          ),
        );
      },
    );
  }
}

/// [PortalSkeleton] pulses portal.muted to surfaceVariant, which on a card
/// is barely there (and darker than a dark card). Re-points those two tones
/// for the skeletons under it, so the skeleton keeps its own look
/// everywhere else. On a surface that is already high (a grouped page,
/// where portal.muted can be the page itself) the blocks hold portal.card,
/// where neutral fills sit: any pulse toward the darker tone would cross
/// the page tone and vanish. [PortalSkeletonTone.grouped] leaves the normal
/// pulse alone everywhere but such a page.
class PortalSkeletonTone extends StatelessWidget {
  const PortalSkeletonTone({super.key, required this.child})
      : _groupedOnly = false;

  const PortalSkeletonTone.grouped({super.key, required this.child})
      : _groupedOnly = true;

  final Widget child;
  final bool _groupedOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final portal = PortalUiTheme.of(context);
    final grouped = Material.maybeOf(context)?.color == cs.surfaceContainerHigh;
    if (_groupedOnly && !grouped) return child;
    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final e in theme.extensions.values)
            if (e is! PortalUiTheme) e,
          portal.copyWith(
            muted: grouped ? portal.card : cs.surfaceContainerHigh,
            surfaceVariant: grouped ? portal.card : cs.surfaceContainerHighest,
          ),
        ],
      ),
      child: child,
    );
  }
}
