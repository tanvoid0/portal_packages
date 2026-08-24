import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Browser chrome wrapper for web dashboard mockups.
class BrowserFrame extends StatelessWidget {
  const BrowserFrame({
    required this.child,
    super.key,
    this.url = 'portal_ui_kit.dev/dashboard',
    this.maxWidth = 1100,
    this.contentHeight = 560,
  });

  final Widget child;
  final String url;
  final double maxWidth;
  final double contentHeight;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final brightness = Theme.of(context).brightness;
    final shadows = t.elevation.card(brightness);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(t.radii.lg),
          border: Border.all(color: portal.outline.withValues(alpha: 0.35)),
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(t.radii.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrowserChrome(url: url),
              SizedBox(
                height: contentHeight,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserChrome extends StatelessWidget {
  const _BrowserChrome({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: portal.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.sm,
        ),
        child: Row(
          children: [
            const _TrafficLights(),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(t.radii.full),
                  border: Border.all(
                    color: portal.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spacing.md,
                    vertical: t.spacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: portal.onSurfaceVariant,
                      ),
                      SizedBox(width: t.spacing.xs),
                      Expanded(
                        child: Text(
                          url,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: portal.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficLights extends StatelessWidget {
  const _TrafficLights();

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;

    return Row(
      children: [
        const _Dot(color: Color(0xFFFF5F57)),
        SizedBox(width: t.spacing.xs),
        const _Dot(color: Color(0xFFFEBC2E)),
        SizedBox(width: t.spacing.xs),
        const _Dot(color: Color(0xFF28C840)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
