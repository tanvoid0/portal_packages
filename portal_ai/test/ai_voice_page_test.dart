import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  testWidgets('a denied microphone says so and offers settings', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: AiVoicePage(
          session: AiVoiceSession(ask: (_) async => null),
          labels: const AiChatLabels(),
          micDenied: true,
          onOpenSettings: () => opened = true,
        ),
      ),
    );

    expect(find.textContaining('needs the microphone'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    expect(opened, isTrue);
  });

  testWidgets('a card takes the page, with its hint and one caption line', (
    tester,
  ) async {
    final session = AiVoiceSession(ask: (_) async => null)
      ..heard = 'Move it to Friday';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: AiVoicePage(
          session: session,
          labels: const AiChatLabels(),
          card: const Text('The card'),
          cardHint: 'Say yes, no, or what to change',
        ),
      ),
    );

    expect(find.text('The card'), findsOneWidget);
    expect(find.text('Say yes, no, or what to change'), findsOneWidget);
    expect(find.text('Move it to Friday'), findsOneWidget);
  });

  testWidgets('a session error is its own state, not a caption', (
    tester,
  ) async {
    final session = AiVoiceSession(ask: (_) async => null)
      ..error = 'The speech service did not answer.';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: AiVoicePage(session: session, labels: const AiChatLabels()),
      ),
    );

    expect(find.text("Voice isn't available right now"), findsOneWidget);
    expect(find.text('The speech service did not answer.'), findsOneWidget);
  });
}
