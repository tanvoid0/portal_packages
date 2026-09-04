import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  group('DesignTokens.expressive', () {
    test('has bold radii and motion', () {
      const e = DesignTokens.expressive;
      expect(e.radii.sm, 12);
      expect(e.radii.lg, 24);
      expect(e.radii.xl, 32);
      expect(e.motion.medium, const Duration(milliseconds: 350));
      expect(e.motion.staggerStep, const Duration(milliseconds: 60));
      expect(e.motion.listRevealDuration, const Duration(milliseconds: 280));
      expect(e.expressiveCorners, isTrue);
    });
  });

  group('PortalRadiiUtils', () {
    test('asymmetric uses xl on top and sm on bottom by default', () {
      const r = PortalRadii(sm: 6, xl: 20);
      final br = r.asymmetric();
      expect(br.topLeft, const Radius.circular(20));
      expect(br.bottomLeft, const Radius.circular(6));
    });

    test('continuousBorder returns ContinuousRectangleBorder', () {
      const r = PortalRadii();
      expect(r.continuousBorder(), isA<ContinuousRectangleBorder>());
    });
  });

  group('PortalWaveHeaderClipper', () {
    test('getClip produces closed path within bounds', () {
      const clipper = PortalWaveHeaderClipper(amplitude: 10, waves: 2);
      final path = clipper.getClip(const Size(200, 80));
      expect(path.getBounds().width, 200);
      expect(path.getBounds().height, greaterThanOrEqualTo(70));
    });

    test('keeps the header content, notches only the bottom edge', () {
      // The wave is decoration on the bottom edge; RenderClipPath hit-tests
      // against this path, so anything the header draws -- the back button
      // most of all -- has to be inside it.
      const clipper = PortalWaveHeaderClipper(amplitude: 14, waves: 2);
      final path = clipper.getClip(const Size(400, 100));
      expect(path.contains(const Offset(28, 20)), isTrue);
      expect(path.contains(const Offset(200, 50)), isTrue);
      expect(path.contains(const Offset(200, 99)), isFalse);
    });

    test('shouldReclip when amplitude changes', () {
      const a = PortalWaveHeaderClipper(amplitude: 10);
      const b = PortalWaveHeaderClipper(amplitude: 12);
      expect(a.shouldReclip(b), isTrue);
    });
  });

  group('PortalDiagonalCardClipper', () {
    test('getClip includes diagonal notch', () {
      const clipper = PortalDiagonalCardClipper(cut: 24);
      final path = clipper.getClip(const Size(100, 100));
      expect(path.getBounds().width, 100);
      expect(path.getBounds().height, 100);
    });
  });

  group('PortalStaggeredChild', () {
    testWidgets('returns child without animation when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PortalStaggeredChild(
              index: 2,
              child: Text('item'),
            ),
          ),
        ),
      );
      expect(find.text('item'), findsOneWidget);
    });

    testWidgets('wraps child when animations enabled', (tester) async {
      final theme = PortalThemePalette.violet.toConfig().build().light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const PortalStaggeredChild(
            index: 0,
            child: Text('item'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('item'), findsOneWidget);
    });
  });

  group('wrapStaggeredList', () {
    test('returns same length with PortalStaggeredChild wrappers', () {
      final wrapped = wrapStaggeredList([
        const Text('a'),
        const Text('b'),
      ]);
      expect(wrapped, hasLength(2));
      expect(wrapped.every((w) => w is PortalStaggeredChild), isTrue);
    });
  });

  group('PortalShimmer', () {
    testWidgets('returns child without shimmer when animations disabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PortalShimmer(
              child: SizedBox(key: Key('block'), width: 40, height: 12),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('block')), findsOneWidget);
    });

    testWidgets('wraps child when animations enabled', (tester) async {
      final theme = PortalThemePalette.violet.toConfig().build().light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const PortalShimmer(
            child: SizedBox(width: 40, height: 12),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PortalShimmer), findsOneWidget);
    });
  });
}
