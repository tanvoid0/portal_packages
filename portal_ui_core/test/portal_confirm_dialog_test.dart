import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('renders title/message and fires onConfirm/onCancel',
      (t) async {
    var confirmed = false;
    var cancelled = false;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        body: PortalConfirmDialog(
          title: 'Remove this item?',
          message: 'This cannot be undone.',
          confirmLabel: 'Remove',
          isDestructive: true,
          onConfirm: () => confirmed = true,
          onCancel: () => cancelled = true,
        ),
      ),
    ));

    expect(find.text('Remove this item?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await t.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
    await t.tap(find.text('Remove'));
    expect(confirmed, isTrue);
  });

  testWidgets('portalConfirm resolves true/false via the extracted body',
      (t) async {
    late BuildContext ctx;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));

    bool? result;
    unawaited(
      portalConfirm(ctx, title: 'Delete this recipe?', confirmLabel: 'Delete')
          .then((v) => result = v),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('otherLabel adds a third action that fires onOther', (t) async {
    var discarded = false;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Scaffold(
        body: PortalConfirmDialog(
          title: 'Workout already in progress',
          confirmLabel: 'Resume',
          otherLabel: 'Discard',
          onConfirm: () {},
          onOther: () => discarded = true,
        ),
      ),
    ));

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await t.tap(find.text('Discard'));
    expect(discarded, isTrue);
  });

  testWidgets('null callbacks disable confirm/other (static book preview)',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: const Scaffold(
        body: PortalConfirmDialog(
          title: 'Static preview',
          confirmLabel: 'Resume',
          otherLabel: 'Discard',
        ),
      ),
    ));

    TextButton button(String label) =>
        t.widget<TextButton>(find.widgetWithText(TextButton, label));
    expect(button('Resume').onPressed, isNull);
    expect(button('Discard').onPressed, isNull);
  });
}
