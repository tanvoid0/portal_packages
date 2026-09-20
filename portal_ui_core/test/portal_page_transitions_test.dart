import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Counts the status listeners hung on it, so a test can see a leaked curve.
class _CountingAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _CountingAnimation(this.parent);

  @override
  final Animation<double> parent;

  int statusListeners = 0;

  @override
  double get value => parent.value;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners++;
    parent.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners--;
    parent.removeStatusListener(listener);
  }
}

void main() {
  // `expressive` sets medium to 350 ms; the SDK's own default is 300, so a
  // theme on default tokens could not tell the override apart from nothing.
  final theme = buildPortalTheme(
    brightness: Brightness.light,
    tokens: DesignTokens.expressive,
  );

  Widget app(Widget home) => MaterialApp(theme: theme, home: home);

  group('PortalPageTransitionsBuilder', () {
    test('is the theme builder on every platform', () {
      for (final platform in TargetPlatform.values) {
        expect(
          theme.pageTransitionsTheme.builders[platform],
          isA<PortalPageTransitionsBuilder>(),
          reason: platform.name,
        );
      }
    });

    testWidgets('a plain MaterialPageRoute slides on the shared axis',
        (tester) async {
      await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const Text('second')),
          ),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SharedAxisTransition), findsWidgets);
      final route = ModalRoute.of(tester.element(find.text('second')))!;
      expect(
        (route as TransitionRoute).transitionDuration,
        const Duration(milliseconds: 350),
      );
    });

    testWidgets('owns one curve per route across per-frame rebuilds',
        (tester) async {
      final controller = AnimationController(vsync: tester);
      final animation = _CountingAnimation(controller);
      const builder =
          PortalPageTransitionsBuilder(duration: Duration(milliseconds: 300));
      Widget frame() => Builder(
            builder: (context) => builder.buildTransitions(
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
              context,
              animation,
              kAlwaysDismissedAnimation,
              const SizedBox(),
            ),
          );

      await tester.pumpWidget(app(frame()));
      final once = animation.statusListeners;
      await tester.pumpWidget(app(frame()));
      await tester.pumpWidget(app(frame()));
      expect(animation.statusListeners, once, reason: 'rebuilds reuse it');

      await tester.pumpWidget(const SizedBox());
      expect(animation.statusListeners, 0, reason: 'disposed with the route');
      controller.dispose();
    });
  });

  group('PortalHero', () {
    testWidgets('flight clips to a radius between the two ends, on a Material',
        (tester) async {
      const from = BorderRadius.all(Radius.circular(20));
      await tester.pumpWidget(app(Builder(
        builder: (context) => Column(children: [
          const PortalHero(
            tag: 'card',
            borderRadius: from,
            child: SizedBox(width: 80, height: 80),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PortalHero(
                  tag: 'card',
                  borderRadius: BorderRadius.zero,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Text('flying'),
                  ),
                ),
              ),
            ),
            child: const Text('go'),
          ),
        ]),
      )));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final radii = tester
          .widgetList<ClipRRect>(find.byType(ClipRRect))
          .map((c) => (c.borderRadius as BorderRadius).topLeft.x)
          .where((r) => r > 0 && r < 20);
      expect(radii, hasLength(1), reason: 'one shuttle, mid-lerp');
      expect(
        find.ancestor(
          of: find.text('flying'),
          matching: find.byType(Material),
        ),
        findsOneWidget,
        reason: 'the overlay has no Material; text would fly underlined',
      );
    });

    testWidgets('PortalCard(heroTag:) wraps itself in a PortalHero',
        (tester) async {
      await tester.pumpWidget(app(
        const PortalCard(heroTag: 'c', child: Text('x')),
      ));
      expect(
        find.ancestor(of: find.text('x'), matching: find.byType(PortalHero)),
        findsOneWidget,
      );
    });
  });
}
