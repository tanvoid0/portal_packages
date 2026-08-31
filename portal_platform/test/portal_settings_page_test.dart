import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:portal_platform/portal_platform.dart';

/// The page's own logic is which groups it builds and in what order — the rows
/// themselves are already-tested services. `include` and `order` decide what a
/// migrating app can leave out, so they are the part worth pinning.
void main() {
  setUp(Get.reset);

  Future<void> pump(WidgetTester tester, Widget page) =>
      tester.pumpWidget(GetMaterialApp(home: page));

  testWidgets('builds only the groups it was given', (tester) async {
    await pump(
      tester,
      const PortalSettingsPage(
        include: [PortalSettingsGroup.custom],
        sections: [
          PortalSettingsSection(title: 'Only me', children: [Text('row')]),
        ],
      ),
    );

    expect(find.text('ONLY ME'), findsOneWidget);
    // Status is in the default order but not in `include`.
    expect(find.text('STATUS'), findsNothing);
    expect(find.text('ABOUT'), findsNothing);
  });

  testWidgets('respects order, and skips what include leaves out',
      (tester) async {
    await pump(
      tester,
      PortalSettingsPage(
        include: const [PortalSettingsGroup.custom, PortalSettingsGroup.about],
        order: const [PortalSettingsGroup.about, PortalSettingsGroup.custom],
        sections: const [
          PortalSettingsSection(title: 'Mine', children: [Text('row')]),
        ],
        sectionBuilder: (title, children) =>
            Column(children: [Text('<$title>'), ...children]),
      ),
    );

    final about = tester.getTopLeft(find.text('<About>')).dy;
    final mine = tester.getTopLeft(find.text('<Mine>')).dy;
    expect(about, lessThan(mine));
  });

  testWidgets('sectionBuilder replaces the default chrome', (tester) async {
    await pump(
      tester,
      PortalSettingsPage(
        include: const [PortalSettingsGroup.custom],
        sections: const [
          PortalSettingsSection(title: 'Accounts', children: [Text('row')]),
        ],
        sectionBuilder: (title, children) =>
            Column(children: [Text('~$title~'), ...children]),
      ),
    );

    expect(find.text('~Accounts~'), findsOneWidget);
    expect(find.text('ACCOUNTS'), findsNothing);
  });

  testWidgets('labels drive every heading it renders', (tester) async {
    await pump(
      tester,
      const PortalSettingsPage(
        labels: PortalSettingsLabels(title: 'Réglages', about: 'À propos'),
        include: [PortalSettingsGroup.about],
      ),
    );

    expect(find.text('Réglages'), findsOneWidget);
    expect(find.text('À PROPOS'), findsOneWidget);
  });

  testWidgets('appearance section is absent without a theme controller',
      (tester) async {
    await pump(
      tester,
      const PortalSettingsPage(include: [PortalSettingsGroup.appearance]),
    );

    expect(find.text('APPEARANCE'), findsNothing);
  });
}
