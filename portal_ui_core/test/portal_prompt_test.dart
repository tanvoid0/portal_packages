import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
      );

  testWidgets('standard: title, message, one action that fires', (t) async {
    var retried = false;
    await t.pumpWidget(host(PortalPrompt(
      title: 'Backup failed',
      message: 'Check your connection.',
      sentiment: PortalSentiment.negative,
      action: (label: 'Retry now', onPressed: () => retried = true),
    )));
    await t.pumpAndSettle();
    expect(find.text('Backup failed'), findsOneWidget);
    await t.tap(find.text('Retry now'));
    expect(retried, isTrue);
  });

  testWidgets('dismiss is a 48 target named for a screen reader', (t) async {
    var dismissed = false;
    await t.pumpWidget(host(PortalPrompt(
      message: 'Record set',
      sentiment: PortalSentiment.positive,
      onDismiss: () => dismissed = true,
    )));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Close'));
    expect(dismissed, isTrue);
    expect(t.getSize(find.byType(IconButton)).shortestSide, 48);
  });

  testWidgets('visible: false collapses to zero height', (t) async {
    Widget build(bool v) => host(PortalPrompt(message: 'Syncing', visible: v));
    await t.pumpWidget(build(true));
    await t.pumpAndSettle();
    await t.pumpWidget(build(false));
    await t.pumpAndSettle();
    expect(t.getSize(find.byType(SizeTransition)).height, 0);
  });

  testWidgets('compact refuses an action and a dismiss together', (t) async {
    expect(
      () => PortalPrompt(
        message: 'x',
        size: PortalPromptSize.compact,
        action: (label: 'a', onPressed: () {}),
        onDismiss: () {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('the secondary action takes its size from the tokens',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(
        brightness: Brightness.light,
        tokens: const DesignTokens(minTapTarget: 56),
      ),
      home: Scaffold(
        body: PortalPrompt(
          title: 'Backup failed',
          message: 'Check your connection.',
          action: (label: 'Retry', onPressed: () {}),
          secondaryAction: (label: 'Later', onPressed: () {}),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(t.getSize(find.byType(TextButton)).height, 56);
  });
}
