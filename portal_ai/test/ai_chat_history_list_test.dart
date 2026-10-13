import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

AiChatSessionSummary _summary(
  String id, {
  String title = '',
  String preview = '',
  String searchText = '',
  bool pinned = false,
  DateTime? updatedAt,
}) => AiChatSessionSummary(
  id: id,
  title: title.isEmpty ? id : title,
  updatedAt: updatedAt ?? DateTime.now(),
  turnCount: 2,
  preview: preview,
  searchText: searchText,
  pinned: pinned,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<AiChatSessionSummary> sessions,
  Future<void> Function(String id)? onDelete,
  Future<void> Function(String id, String title)? onRename,
  Future<void> Function(String id, bool pinned)? onSetPinned,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Scaffold(
      body: AiChatHistoryList(
        sessions: sessions,
        onSelect: (_) {},
        onNewChat: () {},
        onDelete: onDelete,
        onRename: onRename,
        onSetPinned: onSetPinned,
      ),
    ),
  ),
);

Future<void> _openMenu(WidgetTester tester, String rowTitle) async {
  await tester.longPress(find.text(rowTitle));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('delete waits for the undo snackbar and undo cancels it', (
    tester,
  ) async {
    final deleted = <String>[];
    await _pump(
      tester,
      sessions: [_summary('a'), _summary('b')],
      onDelete: (id) async => deleted.add(id),
    );

    await _openMenu(tester, 'a');
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    // Hidden, but the host has not been told yet.
    expect(find.text('a'), findsNothing);
    expect(deleted, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('a'), findsOneWidget);
    expect(deleted, isEmpty);
  });

  testWidgets('delete commits once the undo window passes', (tester) async {
    final deleted = <String>[];
    await _pump(
      tester,
      sessions: [_summary('a'), _summary('b')],
      onDelete: (id) async => deleted.add(id),
    );

    await _openMenu(tester, 'a');
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(deleted, ['a']);
  });

  testWidgets('search matches a line buried in the transcript', (tester) async {
    await _pump(
      tester,
      sessions: [
        _summary('a', searchText: 'we talked about kettlebells'),
        _summary('b', searchText: 'nothing of the sort'),
      ],
    );

    await tester.enterText(find.byType(TextField), 'kettlebell');
    await tester.pumpAndSettle();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsNothing);
  });

  testWidgets('search and New chat are always offered', (tester) async {
    await _pump(tester, sessions: const []);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('New chat'), findsOneWidget);
  });

  testWidgets('pinned threads sit in their own group above the days', (
    tester,
  ) async {
    await _pump(
      tester,
      sessions: [
        _summary('old', updatedAt: DateTime.now()),
        _summary(
          'kept',
          pinned: true,
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ],
      onSetPinned: (_, _) async {},
    );

    expect(find.text('Pinned'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('kept')).dy,
      lessThan(tester.getTopLeft(find.text('old')).dy),
    );
  });

  testWidgets('rename reports the typed title', (tester) async {
    final renamed = <String, String>{};
    await _pump(
      tester,
      sessions: [_summary('a')],
      onRename: (id, title) async => renamed[id] = title,
    );

    await _openMenu(tester, 'a');
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Leg day plan');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(renamed, {'a': 'Leg day plan'});
  });

  testWidgets('pin toggles against what the row already is', (tester) async {
    final pins = <String, bool>{};
    await _pump(
      tester,
      sessions: [_summary('a', pinned: true)],
      onSetPinned: (id, pinned) async => pins[id] = pinned,
    );

    await _openMenu(tester, 'a');
    await tester.tap(find.text('Unpin').last);
    await tester.pumpAndSettle();

    expect(pins, {'a': false});
  });

  testWidgets('no menu at all when the host wires nothing', (tester) async {
    await _pump(tester, sessions: [_summary('a')]);
    await _openMenu(tester, 'a');
    expect(find.text('Delete'), findsNothing);
  });
}
