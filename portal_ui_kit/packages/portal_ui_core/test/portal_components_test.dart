import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    expect(t.getSemantics(find.text('Chest')).hasFlag(SemanticsFlag.isSelected),
        isFalse);

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
    expect(find.byIcon(Icons.search), findsOneWidget);

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
