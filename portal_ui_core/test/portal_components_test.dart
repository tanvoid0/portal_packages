import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Tokens with values distinct from the defaults, so a component that
/// hardcodes instead of reading the bundle fails visibly.
const _tokens = DesignTokens(
  radii: PortalRadii(sm: 7, md: 11, lg: 17, xl: 23, full: 999),
  spacing: PortalSpacing(xs: 3, sm: 5, md: 9, lg: 13, xl: 21, xxl: 27),
  layout: PortalLayoutInsets(
    pageHorizontal: 20,
    sectionGap: 24,
    listBottomInset: 108,
  ),
  minTapTarget: 48,
  motion: PortalMotion(pressScale: 0.9),
);

Widget _host(Widget child) {
  final theme = buildPortalTheme(
    brightness: Brightness.light,
    tokens: _tokens,
  );
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('section header renders title, icon and trailing', (t) async {
    await t.pumpWidget(_host(const PortalSectionHeader(
      title: 'This Week',
      icon: Icons.calendar_today,
      trailing: Text('See all'),
    )));

    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
  });

  testWidgets('empty state hides the action unless both label and callback '
      'are given', (t) async {
    await t.pumpWidget(_host(const PortalEmptyState(
      icon: Icons.inbox,
      title: 'Nothing yet',
      message: 'Add your first item.',
      actionLabel: 'Add',
    )));

    expect(find.text('Nothing yet'), findsOneWidget);
    expect(find.text('Add your first item.'), findsOneWidget);
    expect(find.byType(PortalButton), findsNothing);

    var tapped = false;
    await t.pumpWidget(_host(PortalEmptyState(
      icon: Icons.inbox,
      title: 'Nothing yet',
      actionLabel: 'Add',
      onAction: () => tapped = true,
    )));

    expect(find.byType(PortalButton), findsOneWidget);
    await t.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('list skeleton renders one block per item', (t) async {
    await t.pumpWidget(_host(
      const PortalListSkeleton(itemCount: 4, itemHeight: 40),
    ));
    await t.pump(const Duration(milliseconds: 100));

    expect(find.byType(PortalSkeleton), findsNWidgets(4));
  });

  testWidgets('stat card shows value and label', (t) async {
    await t.pumpWidget(_host(const PortalStatCard(
      value: '12',
      label: 'WORKOUTS',
      icon: Icons.fitness_center,
      footer: Text('+3'),
    )));

    expect(find.text('12'), findsOneWidget);
    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('a card is tonal and borderless by default, outlined has an edge',
      (t) async {
    OutlinedBorder shapeOf(String label) => t
        .widget<Material>(find.ancestor(
          of: find.text(label),
          matching: find.byType(Material),
        ).first)
        .shape! as OutlinedBorder;

    await t.pumpWidget(_host(const Column(children: [
      PortalCard(child: Text('tonal')),
      PortalCard(variant: PortalCardVariant.outlined, child: Text('edge')),
    ])));

    final scheme = Theme.of(t.element(find.text('tonal'))).colorScheme;
    final tonal = shapeOf('tonal');
    expect(tonal.side, BorderSide.none);
    expect(tonal, isA<ContinuousRectangleBorder>());
    expect(
      t
          .widget<Material>(find.ancestor(
            of: find.text('tonal'),
            matching: find.byType(Material),
          ).first)
          .color,
      scheme.surfaceContainerLow,
    );
    expect(shapeOf('edge').side.width, _tokens.borderWidth);
  });

  test('the card theme is tonal with no border; inputs have no resting edge',
      () {
    for (final brightness in Brightness.values) {
      final base = buildPortalTheme(brightness: brightness, tokens: _tokens);
      final theme = applyPortalComponentThemes(
        base: base,
        colorScheme: base.colorScheme,
        tokens: _tokens,
        textTheme: base.textTheme,
      );
      final cs = base.colorScheme;
      expect(
        theme.cardTheme.color,
        brightness == Brightness.dark
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerLow,
      );
      expect((theme.cardTheme.shape! as OutlinedBorder).side, BorderSide.none);
      expect(
        (theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
            .borderSide,
        BorderSide.none,
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        cs.primary,
      );
      // No resting edge, so the fill is what makes a field visible: it must
      // differ from every surface a field sits on.
      expect(theme.inputDecorationTheme.fillColor, cs.surfaceContainerHighest);
      expect(theme.inputDecorationTheme.fillColor,
          isNot(theme.dialogTheme.backgroundColor));
      expect(theme.inputDecorationTheme.fillColor, isNot(theme.cardTheme.color));
    }
  });

  test('on the palette path the input fill still differs from card and panel',
      () {
    // A surface palette maps surfaceContainerHighest and cardColor to the same
    // colour, so the field steps to surfaceContainerHigh there.
    const config = PortalThemeConfig();
    for (final theme in [config.light(), config.dark()]) {
      expect(theme.inputDecorationTheme.fillColor,
          theme.colorScheme.surfaceContainerHigh);
      expect(theme.inputDecorationTheme.fillColor,
          isNot(theme.dialogTheme.backgroundColor));
      expect(theme.inputDecorationTheme.fillColor, isNot(theme.cardTheme.color));
      expect(theme.inputDecorationTheme.fillColor,
          isNot(theme.scaffoldBackgroundColor));
    }
  });

  testWidgets('a sheen card paints the surface sheen behind its content',
      (t) async {
    await t.pumpWidget(_host(const PortalCard(
      sheen: true,
      child: Text('lift'),
    )));

    final scheme = Theme.of(t.element(find.text('lift'))).colorScheme;
    final sheen = t
        .widgetList<DecoratedBox>(find.descendant(
          of: find.byType(PortalCard),
          matching: find.byType(DecoratedBox),
        ))
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .singleWhere(
          (g) => g.colors.first == scheme.onSurface.withValues(alpha: 0.04),
        );
    expect(sheen.colors.last.a, 0);
    expect(find.text('lift'), findsOneWidget);
  });

  test('gradients: accent runs primary to primaryContainer, scrim is 60% scrim',
      () {
    const g = PortalGradients();
    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    expect(g.accent(scheme).colors, [scheme.primary, scheme.primaryContainer]);
    expect(g.imageScrim(scheme).colors.first.a, closeTo(0.6, 0.01));
    expect(g.imageScrim(scheme).begin, Alignment.bottomCenter);
  });

  testWidgets('filter chip meets the tap-target floor and reports taps',
      (t) async {
    var taps = 0;
    await t.pumpWidget(_host(Align(
      child: PortalFilterChip(
        label: 'Chest',
        selected: true,
        onTap: () => taps++,
      ),
    )));
    await t.pumpAndSettle();

    expect(
      t.getSize(find.byType(PortalFilterChip)).height,
      greaterThanOrEqualTo(_tokens.minTapTarget),
    );
    await t.tap(find.text('Chest'));
    expect(taps, 1);
  });

  testWidgets('a loading button shows a spinner and refuses taps', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(Align(
      child: PortalButton(
        label: 'Save',
        isLoading: true,
        leading: const Icon(Icons.check),
        onPressed: () => taps++,
      ),
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    await t.tap(find.text('Save'));
    expect(taps, 0);

    await t.pumpWidget(_host(Align(
      child: PortalButton(label: 'Save', onPressed: () => taps++),
    )));
    await t.tap(find.text('Save'));
    expect(taps, 1);
  });

  testWidgets('pressable scales down while held and springs back to 1',
      (t) async {
    await t.pumpWidget(_host(Center(
      child: PortalPressable(
        onTap: () {},
        child: const SizedBox(width: 120, height: 48),
      ),
    )));
    // Scaffold has a ScaleTransition of its own (the FAB slot).
    final pressable = find.byType(PortalPressable);
    Finder inside(Type type) =>
        find.descendant(of: pressable, matching: find.byType(type));
    double scale() =>
        t.widget<ScaleTransition>(inside(ScaleTransition)).scale.value;
    expect(scale(), 1);

    final gesture = await t.startGesture(t.getCenter(pressable));
    await t.pump();
    expect(
      t.widget<AnimatedScale>(inside(AnimatedScale)).scale,
      0.9,
      reason: 'target is the pressScale token, not a literal',
    );
    await t.pump(const Duration(milliseconds: 50));
    expect(scale(), lessThan(1));

    await gesture.up();
    await t.pumpAndSettle();
    expect(scale(), 1);
  });

  testWidgets('a quick tap in a scrollable still shows the press', (t) async {
    // In a ListView the highlight waits for the arena, so down and up arrive
    // in one event; the press has to be held for the tap to be visible.
    await t.pumpWidget(_host(ListView(children: [
      PortalPressable(onTap: () {}, child: const SizedBox(height: 48)),
    ])));
    final target = find.descendant(
      of: find.byType(PortalPressable),
      matching: find.byType(AnimatedScale),
    );
    await t.tap(find.byType(PortalPressable));
    await t.pump();
    expect(t.widget<AnimatedScale>(target).scale, 0.9);
    await t.pumpAndSettle();
    expect(t.widget<AnimatedScale>(target).scale, 1);
  });

  testWidgets('filter chip announces its selected state', (t) async {
    final handle = t.ensureSemantics();

    await t.pumpWidget(_host(Align(
      child: PortalFilterChip(label: 'Chest', selected: true, onTap: () {}),
    )));
    expect(
      t.getSemantics(find.text('Chest')),
      matchesSemantics(
        label: 'Chest',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );

    await t.pumpWidget(_host(Align(
      child: PortalFilterChip(label: 'Chest', selected: false, onTap: () {}),
    )));
    expect(
      t.getSemantics(find.text('Chest')),
      matchesSemantics(
        label: 'Chest',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );

    handle.dispose();
  });

  testWidgets('segmented tabs report the tapped index', (t) async {
    int? picked;
    await t.pumpWidget(_host(PortalSegmentedTabs(
      labels: const ['Exercises', 'Equipment', 'Programs'],
      index: 0,
      onChanged: (i) => picked = i,
    )));

    await t.tap(find.text('Programs'));
    expect(picked, 2);
  });

  testWidgets('scroll page insets content to the layout gutter and clearance',
      (t) async {
    await t.pumpWidget(_host(const PortalScrollPage(
      title: 'Library',
      children: [SizedBox(height: 40, child: Text('row'))],
    )));

    final padding = t.widget<SliverPadding>(find.byType(SliverPadding)).padding
        as EdgeInsets;
    expect(padding.left, _tokens.layout.pageHorizontal);
    expect(padding.right, _tokens.layout.pageHorizontal);
    expect(padding.bottom, _tokens.layout.listBottomInset);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('app bar keeps two actions inline and overflows the third',
      (t) async {
    PortalAction action(String label, VoidCallback? f) =>
        PortalAction(icon: Icons.star, label: label, onPressed: f);

    // Two fit: both inline, no More button.
    await t.pumpWidget(_host(Scaffold(
      appBar: PortalAppBar(
        title: 'Recipes',
        subtitle: 'Cookbook',
        actions: [action('Share', () {}), action('Edit', () {})],
      ),
    )));
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('More'), findsNothing);
    expect(find.text('Cookbook'), findsOneWidget);

    // Three: first stays, the rest move to the sheet, disabled stays disabled.
    var deleted = false;
    await t.pumpWidget(_host(Scaffold(
      appBar: PortalAppBar(
        title: 'Recipes',
        actions: [
          action('Share', () {}),
          action('Edit', null),
          PortalAction(
            icon: Icons.delete,
            label: 'Delete',
            destructive: true,
            onPressed: () => deleted = true,
          ),
        ],
      ),
    )));
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('More'), findsOneWidget);

    await t.tap(find.byTooltip('More'));
    await t.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(t.widget<ListTile>(find.widgetWithText(ListTile, 'Edit')).enabled,
        isFalse);
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(deleted, isTrue);
    expect(find.byType(ListTile), findsNothing, reason: 'sheet closed');
  });

  testWidgets('list skeleton survives an unbounded sliver when shrinkWrap is set',
      (t) async {
    // How every recipe list uses it. Without shrinkWrap the ListView gets
    // unbounded height inside SliverToBoxAdapter and throws at runtime —
    // which the analyzer cannot see.
    await t.pumpWidget(_host(const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PortalListSkeleton(itemCount: 3, shrinkWrap: true),
        ),
      ],
    )));
    await t.pump(const Duration(milliseconds: 100));

    expect(t.takeException(), isNull);
    expect(find.byType(PortalSkeleton), findsNWidgets(3));
  });

  testWidgets('search field shows hint text and reports changes', (t) async {
    String? changed;
    await t.pumpWidget(_host(PortalSearchField(
      hintText: 'Search recipes',
      onChanged: (value) => changed = value,
    )));

    expect(find.text('Search recipes'), findsOneWidget);
    expect(find.byIcon(Symbols.search_rounded), findsOneWidget);

    await t.enterText(find.byType(TextField), 'pasta');
    expect(changed, 'pasta');
  });

  testWidgets('empty state paints a well behind the glyph when asked',
      (t) async {
    await t.pumpWidget(_host(const PortalEmptyState(
      icon: Icons.inbox,
      title: 'Nothing yet',
    )));
    expect(find.byType(CircleAvatar), findsNothing);

    await t.pumpWidget(_host(const PortalEmptyState(
      icon: Icons.inbox,
      title: 'Nothing yet',
      iconWellColor: Color(0xFFEADFD0),
    )));
    expect(find.byType(CircleAvatar), findsOneWidget);
  });
}
