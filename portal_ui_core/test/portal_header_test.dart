import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

const _tokens = DesignTokens();

Widget _host(Widget child) => MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light, tokens: _tokens),
      home: child,
    );

/// The copy of the title that lives in the toolbar — the collapsed one.
Finder _toolbarTitle(String text) => find.descendant(
      of: find.byType(NavigationToolbar),
      matching: find.text(text),
    );

void main() {
  testWidgets('large header collapses into the compact title on scroll',
      (t) async {
    await t.pumpWidget(_host(PortalScrollPage(
      header: PortalHeader.large(
        title: 'Library',
        subtitle: 'Cookbook',
        actions: [
          PortalAction(icon: Icons.star, label: 'Star', onPressed: () {}),
        ],
      ),
      children: List.generate(
        40,
        (i) => SizedBox(height: 48, child: Text('row $i')),
      ),
    )));

    // Material hands the title to two slots: the expanded one is large, the
    // toolbar one is the compact bar's title and starts hidden.
    final expanded = t.widgetList<Text>(find.text('Library')).singleWhere(
        (w) => w.style?.fontSize == _tokens.textStyles.headline.fontSize);
    expect(expanded.data, 'Library');
    final collapsedStyle =
        t.renderObject<RenderParagraph>(_toolbarTitle('Library')).text.style!;
    expect(collapsedStyle.fontSize, _tokens.typeScale.xl);
    expect(find.byIcon(Icons.star), findsOneWidget);

    AnimatedOpacity toolbarFade() => t.widget<AnimatedOpacity>(find
        .ancestor(
            of: _toolbarTitle('Library'), matching: find.byType(AnimatedOpacity))
        .first);
    expect(toolbarFade().opacity, 0);

    await t.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await t.pumpAndSettle();

    expect(toolbarFade().opacity, 1);
    expect(_toolbarTitle('Library'), findsOneWidget);
    expect(_toolbarTitle('Cookbook'), findsOneWidget);
    // Pinned at the fleet's compact height, not M3's 64.
    expect(t.getSize(find.byType(AppBar)).height, kToolbarHeight);

    // Glass on the bar: translucent tint over a backdrop blur, no
    // scrolled-under tint.
    final bar = t.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(bar.scrolledUnderElevation, 0);
    expect(bar.backgroundColor!.a, lessThan(1));
    expect(t.layers.whereType<BackdropFilterLayer>(), hasLength(1));
  });
}
