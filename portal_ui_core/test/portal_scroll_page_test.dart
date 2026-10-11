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
}
