import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class _ApiError implements Exception {
  _ApiError(this.message);
  final String message;
}

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  tearDown(() {
    PortalAppFeedback.errorMessageResolver = null;
    AppToast.dismiss();
  });

  test('failure: resolver text, error tone, undo action carried', () {
    PortalAppFeedback.errorMessageResolver =
        (e) => e is _ApiError ? e.message : null;
    var undone = false;

    PortalAppFeedback.failure(
      _ApiError('Server said no'),
      title: 'Could not save',
      actionLabel: 'Retry',
      onAction: () => undone = true,
    );

    final toast = AppToast.current.value!;
    expect(toast.title, 'Could not save');
    expect(toast.description, 'Server said no');
    expect(toast.variant, PortalToastVariant.destructive);
    toast.onAction!();
    expect(undone, isTrue);
  });

  test('messageFrom: null and blank fall back, others use toString', () {
    expect(PortalAppFeedback.messageFrom(null, fallback: 'x'), 'x');
    expect(PortalAppFeedback.messageFrom(' '), 'Something went wrong.');
    expect(PortalAppFeedback.messageFrom('boom'), 'boom');
  });

  testWidgets('back button: named, pops the route by default', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              appBar: null,
              body: Center(child: PortalBackToRootButton()),
            ),
          )),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('confirm: one-button ack, optional message, barrier lock',
      (t) async {
    bool? result;
    await t.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await portalConfirm(
          context,
          title: 'Done',
          confirmLabel: 'OK',
          cancelLabel: null,
          barrierDismissible: false,
        ),
        child: const Text('go'),
      ),
    )));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Cancel'), findsNothing);

    await t.tapAt(const Offset(2, 2));
    await t.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);

    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(result, isTrue);
  });
}
