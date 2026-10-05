import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  late BuildContext ctx;

  Future<void> host(WidgetTester t) => t.pumpWidget(MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Builder(builder: (c) {
          ctx = c;
          return const Scaffold();
        }),
      ));

  testWidgets('input dialog: validator keeps it open, then returns trimmed',
      (t) async {
    await host(t);
    String? result = 'unset';
    unawaited(portalInputDialog(
      ctx,
      title: 'Rename',
      label: 'Name',
      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
    ).then((v) => result = v));
    await t.pumpAndSettle();

    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    expect(result, 'unset');

    await t.enterText(find.byType(TextFormField), '  Rent  ');
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(result, 'Rent');
  });

  testWidgets('input dialog: cancel resolves to null', (t) async {
    await host(t);
    String? result = 'unset';
    unawaited(portalInputDialog(ctx, title: 'Rename')
        .then((v) => result = v));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('choice dialog returns the tapped value, null on cancel',
      (t) async {
    await host(t);
    int? result = -1;
    unawaited(portalChoiceDialog<int>(
      ctx,
      title: 'Sort by',
      choices: const [
        PortalChoice(value: 1, label: 'Date'),
        PortalChoice(value: 2, label: 'Amount'),
        PortalChoice(value: 3, label: 'Name', isDestructive: true),
      ],
    ).then((v) => result = v));
    await t.pumpAndSettle();
    await t.tap(find.text('Amount'));
    await t.pumpAndSettle();
    expect(result, 2);

    unawaited(portalChoiceDialog<int>(
      ctx,
      title: 'Sort by',
      choices: const [PortalChoice(value: 1, label: 'Date')],
    ).then((v) => result = v));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('blocking progress: not dismissible, closes on return and throw',
      (t) async {
    await host(t);
    final done = Completer<int>();
    int? out;
    unawaited(PortalBlockingProgress.run(ctx, () => done.future,
        message: 'Saving').then((v) => out = v));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Saving'), findsOneWidget);

    // Barrier tap and back do nothing.
    await t.tapAt(const Offset(2, 2));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Saving'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Saving'), findsOneWidget);

    done.complete(7);
    await t.pumpAndSettle();
    expect(find.text('Saving'), findsNothing);
    expect(out, 7);

    Object? err;
    unawaited(PortalBlockingProgress.run<void>(
      ctx,
      () async => throw StateError('boom'),
      message: 'Saving',
    ).catchError((Object e) => err = e));
    await t.pumpAndSettle();
    expect(find.text('Saving'), findsNothing);
    expect(err, isA<StateError>());
  });
}
