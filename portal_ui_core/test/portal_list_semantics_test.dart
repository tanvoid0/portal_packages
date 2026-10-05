import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('an interactive leading checkbox is reachable', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalListItem(
      title: 'Milk',
      leading: PortalListLeading.interactive(Semantics(
        label: 'Bought',
        child: Checkbox(value: false, onChanged: (v) {}),
      )),
    )));
    final node = t.getSemantics(find.byType(Checkbox));
    expect(node.label, contains('Bought'));
    expect(node.flagsCollection.isChecked.name, 'isFalse');
    h.dispose();
  });

  testWidgets('a decorative leading stays out of semantics', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalListItem(
      title: 'Milk',
      leading: PortalListLeading.tile(Icons.add),
    )));
    final node = t.getSemantics(find.text('Milk'));
    expect(node.label, 'Milk');
    expect(node.flagsCollection.isButton, isFalse);
    h.dispose();
  });

  testWidgets('an interactive widget accessory keeps its button', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalListItem(
      title: 'Plan',
      trailing: PortalListAccessory.widget(
        TextButton(onPressed: () {}, child: const Text('Upgrade')),
        interactive: true,
      ),
    )));
    final node = t.getSemantics(find.byType(TextButton));
    expect(node.label, 'Upgrade');
    expect(node.flagsCollection.isButton, isTrue);
    h.dispose();
  });

  testWidgets('valueAndAction reads the value and names the button',
      (t) async {
    final h = t.ensureSemantics();
    var taps = 0;
    await t.pumpWidget(host(PortalListItem(
      title: 'Rent',
      trailing: PortalListAccessory.valueAndAction(
        '£800',
        icon: Icons.check,
        tooltip: 'Mark rent paid',
        onPressed: () => taps++,
      ),
    )));
    expect(t.getSemantics(find.text('Rent')).label, 'Rent, £800');
    expect(t.getSemantics(find.byType(IconButton)).tooltip, 'Mark rent paid');
    await t.tap(find.byIcon(Icons.check));
    expect(taps, 1);
    h.dispose();
  });

  int labelled(WidgetTester t, String text) {
    var n = 0;
    void walk(SemanticsNode node) {
      if (node.label.contains(text)) n++;
      node.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
    return n;
  }

  testWidgets('an interactive leading does not make the trailing read twice',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalListItem(
      title: 'Milk',
      leading: PortalListLeading.interactive(Semantics(
        label: 'Bought',
        child: Checkbox(value: false, onChanged: (v) {}),
      )),
      trailing: const PortalListAccessory.value('£5'),
    )));
    expect(labelled(t, '£5'), 1);
    h.dispose();
  });

  testWidgets('a disabled reason is the hint and meta is in the label',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(PortalListItem(
      title: 'Sync',
      meta: 'Last run 2h ago',
      disabledReason: 'Sign in first',
      onTap: () {},
    )));
    final node = t.getSemantics(find.text('Sync'));
    expect(node.hint, 'Sign in first');
    expect(node.label, contains('Last run 2h ago'));
    h.dispose();
  });
}
