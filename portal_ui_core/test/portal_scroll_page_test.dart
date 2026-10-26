import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets(
      '.custom renders a regular bar over its own-scroll body, with a dock',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: PortalScrollPage.custom(
        title: 'Chat',
        bottom: PortalButtonDock(
          primary: PortalButton(label: 'Send', onPressed: () {}),
        ),
        body: ListView(children: const [Text('row')]),
      ),
    ));
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('row'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsNothing);
  });

  testWidgets('a tab page FAB clears a shell nav floating over the body',
      (t) async {
    // The shell (PortalTabShell, recipe's home) extends its body under the
    // pill; the tab page inside is its own PortalScrollPage with the FAB.
    Widget shell({required bool extendBody}) => MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
          home: Scaffold(
            extendBody: extendBody,
            bottomNavigationBar: const SizedBox(height: 86),
            body: PortalScrollPage(
              title: 'Trips',
              floatingActionButton:
                  PortalFab(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
              children: const [Text('row')],
            ),
          ),
        );
    final screen = t.view.physicalSize / t.view.devicePixelRatio;
    double fabBottom() => t.getRect(find.byType(Ink)).bottom;

    await t.pumpWidget(shell(extendBody: true));
    expect(fabBottom(), screen.height - 86 - 16);

    // Body already ends above the nav: no second lift.
    await t.pumpWidget(shell(extendBody: false));
    expect(fabBottom(), screen.height - 86 - 16);
  });
}
