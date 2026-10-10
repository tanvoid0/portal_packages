import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('result screen: progress draws a meter, none by default',
      (t) async {
    Widget screen({double? progress}) => MaterialApp(
          theme: buildPortalTheme(brightness: Brightness.light),
          home: PortalResultScreen(
            state: PortalResultState.pending,
            title: 'Downloading',
            body: 'Keep the app open.',
            progress: progress,
          ),
        );
    await t.pumpWidget(screen());
    expect(find.byType(PortalProgress), findsNothing);
    await t.pumpWidget(screen(progress: 0.6));
    expect(find.byType(PortalProgress), findsOneWidget);
  });

  testWidgets('empty state: error shows its message and a working Retry',
      (t) async {
    var retried = false;
    await t.pumpWidget(host(PortalEmptyState.error(
      message: 'Check your connection.',
      onRetry: () => retried = true,
    )));
    expect(find.text("Couldn't load this"), findsOneWidget);
    expect(find.text('Check your connection.'), findsOneWidget);
    await t.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('empty state: secondary action renders under the primary',
      (t) async {
    var cleared = false;
    await t.pumpWidget(host(PortalEmptyState(
      title: 'No matches',
      actionLabel: 'Add item',
      onAction: () {},
      secondaryActionLabel: 'Clear search',
      onSecondaryAction: () => cleared = true,
    )));
    expect(find.text('Add item'), findsOneWidget);
    await t.tap(find.text('Clear search'));
    expect(cleared, isTrue);
  });
}
