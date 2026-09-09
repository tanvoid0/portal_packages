import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  group('DesignTokens presets', () {
    test('default spacing and radii match baseline scale', () {
      const d = DesignTokens.defaults;
      expect(d.spacing.lg, 16);
      expect(d.spacing.md, 12);
      expect(d.spacing.xxxl, 48);
      expect(d.radii.md, 10);
      expect(d.radii.lg, 14);
      expect(d.radii.xl, 20);
      expect(d.typeScale.md, 14);
      expect(d.minTapTarget, 44);
    });

    test('compact tightens spacing, radii, type, and tap target', () {
      const c = DesignTokens.compact;
      const d = DesignTokens.defaults;
      expect(c.spacing.lg, lessThan(d.spacing.lg));
      expect(c.spacing.md, lessThan(d.spacing.md));
      expect(c.spacing.xxxl, lessThan(d.spacing.xxxl));
      expect(c.radii.md, lessThan(d.radii.md));
      expect(c.radii.xl, lessThan(d.radii.xl));
      expect(c.typeScale.md, lessThan(d.typeScale.md));
      expect(c.minTapTarget, lessThan(d.minTapTarget));
    });

    test('rounded increases corner radii but keeps default spacing scale', () {
      const r = DesignTokens.rounded;
      const d = DesignTokens.defaults;
      expect(r.spacing.lg, d.spacing.lg);
      expect(r.radii.sm, greaterThan(d.radii.sm));
      expect(r.radii.md, greaterThan(d.radii.md));
      expect(r.radii.lg, greaterThan(d.radii.lg));
      expect(r.radii.xl, greaterThan(d.radii.xl));
    });

    test('generous has warm/content-app radii with default spacing', () {
      const g = DesignTokens.generous;
      const d = DesignTokens.defaults;
      expect(g.spacing.lg, d.spacing.lg);
      expect(g.radii.sm, 12);
      expect(g.radii.md, 16);
      expect(g.radii.lg, 24);
      expect(g.radii.xl, 32);
    });

    test('motion tokens have sensible defaults', () {
      const d = DesignTokens.defaults;
      expect(d.motion.fast, const Duration(milliseconds: 150));
      expect(d.motion.medium, const Duration(milliseconds: 300));
      expect(d.motion.slow, const Duration(milliseconds: 500));
      expect(d.motion.staggerStep, const Duration(milliseconds: 60));
      expect(d.motion.listRevealDuration, const Duration(milliseconds: 280));
    });

    test('expressive preset enables continuous corners and bold radii', () {
      const e = DesignTokens.expressive;
      expect(e.expressiveCorners, isTrue);
      expect(e.radii.xl, 32);
      expect(e.motion.medium, const Duration(milliseconds: 350));
    });
  });

  group('PortalTextStyles', () {
    test('default text styles have expected font sizes', () {
      const s = PortalTextStyles();
      expect(s.display.fontSize, 34);
      expect(s.headline.fontSize, 28);
      expect(s.title.fontSize, 22);
      expect(s.subtitle.fontSize, 17);
      expect(s.body.fontSize, 16);
      expect(s.caption.fontSize, 13);
      expect(s.overline.fontSize, 11);
    });

    test('can be customised via constructor', () {
      const s = PortalTextStyles(
        display: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
      );
      expect(s.display.fontSize, 40);
      expect(s.headline.fontSize, 28); // unchanged default
    });

    test('tokens carry text styles', () {
      const d = DesignTokens.defaults;
      expect(d.textStyles.display.fontSize, 34);
    });
  });

  group('PortalElevation', () {
    test('default elevation returns non-empty shadow lists', () {
      const e = PortalElevation();
      expect(e.soft(Brightness.light), isNotEmpty);
      expect(e.soft(Brightness.dark), isNotEmpty);
      expect(e.medium(Brightness.light), isNotEmpty);
      expect(e.card(Brightness.dark), isNotEmpty);
    });

    test('can be subclassed to override behaviour', () {
      const flat = _FlatElevation();
      expect(flat.card(Brightness.light), isEmpty);
      expect(flat.soft(Brightness.light), isNotEmpty); // inherited
    });

    test('custom elevation can be passed to DesignTokens', () {
      const tokens = DesignTokens(elevation: _FlatElevation());
      expect(tokens.elevation.card(Brightness.light), isEmpty);
    });
  });

  group('DesignTokens extensibility', () {
    test('can be subclassed to add app-specific token groups', () {
      const app = _AppTokens(
        radii: PortalRadii(sm: 12, md: 16, lg: 24, xl: 32),
        brandAccent: Color(0xFFFF5722),
      );
      expect(app.radii.sm, 12);
      expect(app.brandAccent, const Color(0xFFFF5722));
      expect(app.spacing.lg, 16); // inherited default
    });
  });
}

class _FlatElevation extends PortalElevation {
  const _FlatElevation();

  @override
  List<BoxShadow> card(Brightness brightness) => const [];
}

class _AppTokens extends DesignTokens {
  const _AppTokens({
    super.radii,
    required this.brandAccent,
  });

  final Color brandAccent;
}
