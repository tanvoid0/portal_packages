import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildPortalTheme(brightness: Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _card = AiCard(
  app: 'finance',
  eyebrow: 'Finance · September',
  openLabel: 'Open Finance',
  summary: AiCardSummary('£412.60', of: 'of £600', caption: '£187.40 left'),
  rows: [
    AiCardRow('Groceries', subtitle: 'Food', value: '£182.10'),
    AiCardRow(
      'Northwind card',
      value: '£90',
      unit: 'due',
      openLabel: 'Open Northwind card in Finance',
    ),
  ],
  receipt: AiCardReceipt('Added to your list', openLabel: 'Open Shopping'),
);

void main() {
  test('card and ask blocks round-trip through JSON', () {
    final card = AiBlock.fromJson(AiBlock.card(_card).toJson()).card;
    expect(card.eyebrow, 'Finance · September');
    expect(card.summary?.of, 'of £600');
    expect(card.rows.last.openLabel, 'Open Northwind card in Finance');
    expect(card.receipt?.label, 'Added to your list');

    const ask = AiAsk(
      title: 'Remove Northwind card?',
      app: 'finance',
      args: {'Balance': '£90', 'Kind': 'Credit'},
      state: AiAskState.failed,
      failure: 'No connection.',
      destructive: true,
    );
    final back = AiBlock.fromJson(AiBlock.ask(ask).toJson()).ask;
    expect(back.args.keys, ['Balance', 'Kind']);
    expect(back.state, AiAskState.failed);
    expect(back.destructive, isTrue);
    // A thread saved by a newer build, with a state this one lacks.
    expect(
      AiAsk.fromJson({'title': 'x', 'state': 'later'}).state,
      AiAskState.waiting,
    );
  });

  testWidgets('app card draws head, figure, rows and receipt; Open fires', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        AiAppCard(
          card: _card,
          mark: const Icon(Icons.savings_rounded),
          onOpen: () => opened.add('app'),
          onOpenRow: (r) => opened.add(r.title),
        ),
      ),
    );

    expect(find.text('Finance · September'), findsOneWidget);
    expect(find.textContaining('£412.60'), findsOneWidget);
    expect(find.text('£187.40 left'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Added to your list'), findsOneWidget);
    // The head and the receipt each have an Open, named for a screen reader.
    expect(find.bySemanticsLabel('Open Finance'), findsOneWidget);
    expect(find.bySemanticsLabel('Open Shopping'), findsOneWidget);

    await tester.tap(find.text('Northwind card'));
    await tester.tap(find.bySemanticsLabel('Open Finance'));
    expect(opened, ['Northwind card', 'app']);
  });

  testWidgets('a row with no openLabel is inert; no onOpen draws no Open', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const AiAppCard(card: _card)));
    expect(find.text('Open'), findsNothing);
    // The generic mark stands in for an app the host has no glyph for.
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
  });

  testWidgets('ask card: head, rows, failure with Retry in the solid slot', (
    tester,
  ) async {
    var accepted = 0;
    await tester.pumpWidget(
      _app(
        AiConfirmCard(
          toolName: 'plan',
          args: const {'Where': 'Today'},
          previewTitle: 'Add 2 tasks',
          eyebrow: 'Task',
          mark: const Icon(Icons.task_alt_rounded),
          rows: const [AiCardRow('Stretch'), AiCardRow('Run')],
          failure: "Couldn't save: no connection.",
          onAccept: () => accepted++,
          onDecline: () {},
        ),
      ),
    );

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Add 2 tasks'), findsOneWidget);
    expect(find.text('Stretch'), findsOneWidget);
    expect(find.text("Couldn't save: no connection."), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(accepted, 1);
  });

  testWidgets('ask card: a saved ask is its receipt, never the answers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const AiConfirmCard(
          toolName: 'plan',
          args: {},
          previewTitle: 'Add 2 tasks',
          receipt: AiCardReceipt('Added to Tasks'),
        ),
      ),
    );
    expect(find.text('Added to Tasks'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
  });

  testWidgets('ask card: destructive override and disabled buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const AiConfirmCard(
          toolName: 'finance.update_account',
          args: {},
          previewTitle: 'Remove Northwind card',
          destructive: true,
        ),
      ),
    );
    final accept = tester.widget<PortalButton>(
      find.widgetWithText(PortalButton, 'Accept'),
    );
    expect(accept.variant, PortalButtonVariant.destructive);
    expect(accept.onPressed, isNull);
  });

  testWidgets('the page draws turn cards and asks, and routes the answers', (
    tester,
  ) async {
    final answers = <(String, AiAskAnswer)>[];
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: AiAssistantPage(
            fill: true,
            onSend: (_) async {},
            appMark: (app) => Icon(Icons.pets_rounded, semanticLabel: app),
            onOpenApp: opened.add,
            onAsk: (ask, a) => answers.add((ask.title, a)),
            turns: [
              const AiChatTurn(role: 'user', content: 'budget?'),
              AiChatTurn(
                role: 'assistant',
                content: 'Here it is.',
                payload: {
                  'blocks': [
                    AiBlock.card(_card).toJson(),
                    AiBlock.ask(
                      const AiAsk(
                        title: 'Add 2 tasks',
                        app: 'task',
                        eyebrow: 'Task',
                      ),
                    ).toJson(),
                  ],
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('£412.60'), findsOneWidget);
    expect(find.byIcon(Icons.pets_rounded), findsNWidgets(2));
    await tester.tap(find.bySemanticsLabel('Open Finance'));
    expect(opened, ['finance']);
    await tester.ensureVisible(find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Edit'));
    expect(answers, [
      ('Add 2 tasks', AiAskAnswer.accept),
      ('Add 2 tasks', AiAskAnswer.edit),
    ]);
  });
}
