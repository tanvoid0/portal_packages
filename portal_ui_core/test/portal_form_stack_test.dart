import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('stacks every child in order', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const Scaffold(
        body: PortalFormStack(
          children: [Text('Title'), Text('Notes')],
        ),
      ),
    ));

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(
      t.getTopLeft(find.text('Title')).dy < t.getTopLeft(find.text('Notes')).dy,
      isTrue,
    );
  });
}
