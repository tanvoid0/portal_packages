import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('runs steps in order, shows each label, then builds the app', (
    tester,
  ) async {
    final first = Completer<void>();
    final ran = <String>[];

    await tester.pumpWidget(
      PortalStartupGate(
        icon: Icons.check,
        title: 'Test App',
        steps: [
          PortalStartupStep('Step one', () {
            ran.add('one');
            return first.future;
          }),
          PortalStartupStep('Step two', () async => ran.add('two')),
        ],
        builder: (_) => const MaterialApp(home: Text('booted')),
      ),
    );
    await tester.pump();

    expect(find.text('Step one'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(ran, ['one']);

    first.complete();
    await tester.pumpAndSettle();

    expect(ran, ['one', 'two']);
    expect(find.text('booted'), findsOneWidget);
  });

  testWidgets('a failing step stops the run and retries from the top', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      PortalStartupGate(
        icon: Icons.check,
        title: 'Test App',
        steps: [
          PortalStartupStep('Step one', () async {
            attempts++;
            if (attempts == 1) throw StateError('nope');
          }),
          PortalStartupStep('Step two', () async {}),
        ],
        builder: (_) => const MaterialApp(home: Text('booted')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not start the app'), findsOneWidget);
    expect(find.text('booted'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('booted'), findsOneWidget);
  });
}
