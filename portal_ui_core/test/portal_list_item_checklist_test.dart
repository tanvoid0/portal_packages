import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('default checklist is still a switch with no remove button',
      (t) async {
    await t.pumpWidget(host(PortalListItem.checklist(
      title: 'Buy milk',
      done: false,
      onChanged: (_) {},
    )));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byIcon(PortalIcons.close_rounded), findsNothing);
  });

  testWidgets('checkbox checklist flips done, strikes the title, says checked',
      (t) async {
    final h = t.ensureSemantics();
    var done = false;
    await t.pumpWidget(host(StatefulBuilder(
      builder: (context, set) => PortalListItem.checklist(
        title: 'Buy milk',
        done: done,
        checkbox: true,
        onChanged: (v) => set(() => done = v),
      ),
    )));
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    TextDecoration? line() =>
        t.widget<Text>(find.text('Buy milk')).style!.decoration;
    final row = find.byType(PortalListItem);
    expect(line(), isNull);
    expect(t.getSemantics(row),
        isSemantics(label: 'Buy milk', hasCheckedState: true, isChecked: false));

    await t.tap(find.byType(Checkbox));
    await t.pump();
    expect(done, isTrue);
    expect(line(), TextDecoration.lineThrough);
    expect(t.getSemantics(row),
        isSemantics(label: 'Buy milk', hasCheckedState: true, isChecked: true));

    await t.tap(find.text('Buy milk'));
    await t.pump();
    expect(done, isFalse);
    h.dispose();
  });

  testWidgets('onRemove adds a named X after the control that only removes',
      (t) async {
    var removed = 0;
    var changed = 0;
    await t.pumpWidget(host(PortalListItem.checklist(
      title: 'Buy milk',
      done: false,
      checkbox: true,
      onChanged: (_) => changed++,
      onRemove: () => removed++,
      removeTooltip: 'Remove subtask',
    )));
    expect(find.byTooltip('Remove subtask'), findsOneWidget);
    expect(find.byIcon(PortalIcons.close_rounded), findsOneWidget);
    expect(
        t.getTopLeft(find.byType(Checkbox)).dx,
        lessThan(t.getTopLeft(find.byTooltip('Remove subtask')).dx));

    await t.tap(find.byTooltip('Remove subtask'));
    await t.pump();
    expect(removed, 1);
    expect(changed, 0);
  });
}
