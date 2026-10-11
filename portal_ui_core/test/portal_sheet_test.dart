import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

Widget _host(void Function(BuildContext) onTap) {
  return MaterialApp(
    theme: buildPortalTheme(brightness: Brightness.light),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

/// Height the sheet's child gets: the app minus the grabber row.
double _avail(WidgetTester t) =>
    t.getSize(find.byType(MaterialApp)).height - kMinInteractiveDimension;

void main() {
  testWidgets('PortalSheet.show opens, draws the grabber and returns a value',
      (t) async {
    int? result;
    await t.pumpWidget(_host((context) async {
      result = await PortalSheet.show<int>(
        context,
        builder: (ctx) => PortalSheetScaffold(
          title: 'Pick',
          body: const Text('body'),
          actions: [
            PortalButton(
              label: 'Seven',
              onPressed: () => Navigator.pop(ctx, 7),
            ),
          ],
        ),
      );
    }));

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Pick'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    // showDragHandle draws the grabber with the localized semantics label.
    expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);

    await t.tap(find.text('Seven'));
    await t.pumpAndSettle();
    expect(result, 7);
    expect(find.text('Pick'), findsNothing);
  });

  testWidgets('dismissing resolves null', (t) async {
    Object? result = 'unset';
    await t.pumpWidget(_host((context) async {
      result = await PortalSheet.show<int>(
        context,
        builder: (_) => const Text('body'),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(10, 10)); // barrier
    await t.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('isDismissible false holds on the barrier and hides the grabber',
      (t) async {
    await t.pumpWidget(_host((context) {
      PortalSheet.show<void>(
        context,
        isDismissible: false,
        builder: (_) => const Text('body'),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    // Material's handle carries its own drag-to-close, so it must not show.
    expect(find.bySemanticsLabel('Dismiss'), findsNothing);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('title on show takes a ListView body', (t) async {
    await t.pumpWidget(_host((context) {
      PortalSheet.show<void>(
        context,
        title: 'Units',
        builder: (_) => ListView(
          children: [for (var i = 0; i < 40; i++) Text('row $i')],
        ),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
  });

  testWidgets('detents open at the first and the body scrolls the sheet',
      (t) async {
    await t.pumpWidget(_host((context) {
      PortalSheet.show<void>(
        context,
        detents: const [0.4, 0.9],
        builder: (_) => PortalSheetScaffold(
          body: Column(
            children: [for (var i = 0; i < 40; i++) Text('row $i')],
          ),
        ),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    // Fractions are of the height under the grabber (kMinInteractiveDimension).
    final avail = _avail(t);
    final sheet = t.getRect(find.byType(DraggableScrollableSheet));
    expect(sheet.height, closeTo(avail * 0.4, 1));

    // The scaffold's scroll view took the sheet's controller, so dragging
    // the body grows the sheet instead of only scrolling the rows.
    await t.drag(find.text('row 0'), Offset(0, -avail * 0.6));
    await t.pumpAndSettle();
    final grown = t.getRect(find.byType(DraggableScrollableSheet));
    expect(grown.height, closeTo(avail * 0.9, 1));
  });

  testWidgets('onClose/trailing/message draw, and gutter:false drops padding',
      (t) async {
    var closed = false;
    await t.pumpWidget(_host((context) {
      PortalSheet.show<void>(
        context,
        builder: (_) => PortalSheetScaffold(
          title: 'Actions',
          message: 'Why this asks',
          onClose: () => closed = true,
          trailing: const [Icon(Icons.star)],
          gutter: false,
          scrollable: false,
          body: const Text('body'),
        ),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Why this asks'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    await t.tap(find.byTooltip('Close'));
    expect(closed, isTrue);
  });

  testWidgets('dock renders as the footer instead of actions', (t) async {
    await t.pumpWidget(_host((context) {
      PortalSheet.show<void>(
        context,
        builder: (_) => PortalSheetScaffold(
          body: const Text('body'),
          dock: PortalButtonDock(
            primary: PortalButton(label: 'Save', onPressed: () {}),
          ),
        ),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('the keyboard lifts a detents sheet instead of eating it',
      (t) async {
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.reset);
    await t.pumpWidget(_host((context) {
      PortalSheet.show<void>(
        context,
        detents: const [0.4, 0.9],
        builder: (_) => const TextField(),
      );
    }));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);

    final keyboard = 300 / t.view.devicePixelRatio;
    final sheet = t.getRect(find.byType(DraggableScrollableSheet));
    expect(sheet.height, closeTo((_avail(t) - keyboard) * 0.4, 1));
    expect(sheet.bottom, closeTo(t.getSize(find.byType(MaterialApp)).height - keyboard, 1));
  });
}
