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
}
