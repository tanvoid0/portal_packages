import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(PreferredSizeWidget bar) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(appBar: bar),
      );

  Finder liveRegion() => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.liveRegion == true);

  testWidgets('status renders its icon and text as a live region', (t) async {
    await t.pumpWidget(host(const PortalAppBar(
      title: 'Settings',
      status: 'Synced just now',
      statusIcon: Icons.cloud_done,
    )));
    expect(find.text('Synced just now'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(t.widget<Icon>(find.byIcon(Icons.cloud_done)).size, 14);
    expect(liveRegion(), findsOneWidget);
  });

  testWidgets('no status leaves the bar as it was', (t) async {
    await t.pumpWidget(host(const PortalAppBar(title: 'Settings')));
    expect(liveRegion(), findsNothing);
    await t.pumpWidget(
        host(const PortalAppBar(title: 'Settings', subtitle: 'Account')));
    expect(find.text('Account'), findsOneWidget);
    expect(liveRegion(), findsNothing);
  });

  testWidgets('the sliver bar takes a status too', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const Scaffold(
        body: CustomScrollView(slivers: [
          PortalSliverAppBar(title: 'Settings', status: 'Offline'),
        ]),
      ),
    ));
    expect(find.text('Offline'), findsOneWidget);
    expect(liveRegion(), findsOneWidget);
  });

  test('a subtitle and a status together assert', () {
    expect(
      () => PortalAppBar(title: 'A', subtitle: 'b', status: 'c'),
      throwsAssertionError,
    );
    expect(
      () => PortalSliverAppBar(title: 'A', subtitle: 'b', status: 'c'),
      throwsAssertionError,
    );
  });
}
