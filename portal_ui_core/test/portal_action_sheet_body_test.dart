import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('renders every action and fires onPressed, then onClose',
      (t) async {
    var closed = false;
    var pressed = false;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        body: PortalActionSheetBody(
          title: 'Middlemarch',
          onClose: () => closed = true,
          actions: [
            PortalAction(
              icon: Icons.edit,
              label: 'Edit',
              onPressed: () => pressed = true,
            ),
          ],
        ),
      ),
    ));

    expect(find.text('Middlemarch'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    await t.tap(find.text('Edit'));
    expect(pressed, isTrue);
    expect(closed, isTrue);
  });
}
