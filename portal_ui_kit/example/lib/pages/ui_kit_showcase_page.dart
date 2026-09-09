import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../showcase/screens/finance_mobile_screen.dart';
import '../showcase/screens/healthcare_mobile_screen.dart';
import '../showcase/screens/social_mobile_screen.dart';
import '../showcase/screens/web_dashboard_screen.dart';
import '../widgets/browser_frame.dart';
import '../widgets/showcase_device_frame.dart';

class UiKitShowcasePage extends StatelessWidget {
  const UiKitShowcasePage({super.key});

  static const _mobileBreakpoint = 800.0;
  static const _wideBreakpoint = 1100.0;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        final isMedium = constraints.maxWidth >= _mobileBreakpoint;

        return ListView(
          padding: EdgeInsets.all(t.spacing.lg),
          children: [
            PortalStaggeredChild(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UI Kit Showcase',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: t.spacing.sm),
                  Text(
                    'Reference-inspired mobile screens and a web dashboard composed from '
                    'Portal bricks. Use the sidebar theme controls to preview palettes, '
                    'visual styles, and light/dark mode.',
                    style: textTheme.bodyLarge?.copyWith(color: portal.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(height: t.spacing.xl),
            PortalStaggeredChild(
              index: 1,
              child: Text(
                'Mobile screens',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: t.spacing.md),
            PortalStaggeredChild(
              index: 2,
              child: _MobileFrames(
                isWide: isWide,
                isMedium: isMedium,
              ),
            ),
            SizedBox(height: t.spacing.xxxl),
            PortalStaggeredChild(
              index: 3,
              child: Text(
                'Web dashboard',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: t.spacing.md),
            const PortalStaggeredChild(
              index: 4,
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrowserFrame(
                  child: WebDashboardScreen(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileFrames extends StatelessWidget {
  const _MobileFrames({
    required this.isWide,
    required this.isMedium,
  });

  final bool isWide;
  final bool isMedium;

  static const _frames = [
    ('Finance', FinanceMobileScreen()),
    ('Healthcare', HealthcareMobileScreen()),
    ('Social', SocialMobileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _frames.length; i++) ...[
            if (i > 0) SizedBox(width: t.spacing.lg),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ShowcaseDeviceFrame(
                  label: _frames[i].$1,
                  screen: _frames[i].$2,
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (isMedium) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _frames.length; i++) ...[
              if (i > 0) SizedBox(width: t.spacing.lg),
              ShowcaseDeviceFrame(
                label: _frames[i].$1,
                screen: _frames[i].$2,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _frames.length; i++) ...[
          if (i > 0) SizedBox(height: t.spacing.xl),
          Align(
            alignment: Alignment.center,
            child: ShowcaseDeviceFrame(
              label: _frames[i].$1,
              screen: _frames[i].$2,
            ),
          ),
        ],
      ],
    );
  }
}
