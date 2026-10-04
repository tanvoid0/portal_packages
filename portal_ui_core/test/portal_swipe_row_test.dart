import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// One row that leaves the tree when [remove] is called, as a list would
/// after `onTrigger` — `Dismissible` throws if a dismissed row stays.
class _Host extends StatefulWidget {
  const _Host({required this.row});

  final PortalSwipeRow Function(VoidCallback remove) row;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool _gone = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: buildPortalTheme(brightness: Brightness.light),
        home: Scaffold(
          body: _gone
              ? const SizedBox.shrink()
              : widget.row(() => setState(() => _gone = true)),
        ),
      );
}

/// Full width, as a list gives its rows: the Stack under `Dismissible` sizes to
/// the child, so a narrow one would squeeze the background.
const _row = SizedBox(height: 56, width: double.infinity, child: Text('row'));

void main() {
  final haptics = <String>[];

  setUp(() {
    haptics.clear();
    PortalHaptics.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('a drag past the threshold triggers once, with one medium haptic',
      (t) async {
    var triggers = 0;
    await t.pumpWidget(_Host(
      row: (remove) => PortalSwipeRow(
        key: const ValueKey('row'),
        leading: PortalSwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          foregroundColor: Colors.red,
          onTrigger: () {
            triggers++;
            remove();
          },
        ),
        child: _row,
      ),
    ));

    // 500 of 800 px: well past 40%.
    await t.drag(find.text('row'), const Offset(500, 0));
    await t.pumpAndSettle();

    expect(triggers, 1);
    expect(find.text('row'), findsNothing);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('a toggle fires and the row settles back', (t) async {
    var triggers = 0;
    await t.pumpWidget(_Host(
      row: (_) => PortalSwipeRow(
        key: const ValueKey('row'),
        trailing: PortalSwipeAction(
          icon: Icons.check,
          label: 'Done',
          foregroundColor: Colors.green,
          dismisses: false,
          onTrigger: () => triggers++,
        ),
        child: _row,
      ),
    ));

    await t.drag(find.text('row'), const Offset(-500, 0));
    await t.pumpAndSettle();

    expect(triggers, 1);
    expect(t.getTopLeft(find.text('row')).dx, 0);
  });

  testWidgets('short of the threshold nothing happens', (t) async {
    var triggers = 0;
    await t.pumpWidget(_Host(
      row: (_) => PortalSwipeRow(
        key: const ValueKey('row'),
        leading: PortalSwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          foregroundColor: Colors.red,
          onTrigger: () => triggers++,
        ),
        child: _row,
      ),
    ));

    await t.drag(find.text('row'), const Offset(100, 0));
    await t.pumpAndSettle();

    expect(triggers, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('a fling short of the threshold still triggers', (t) async {
    var triggers = 0;
    await t.pumpWidget(_Host(
      row: (remove) => PortalSwipeRow(
        key: const ValueKey('row'),
        leading: PortalSwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          foregroundColor: Colors.red,
          onTrigger: () {
            triggers++;
            remove();
          },
        ),
        child: _row,
      ),
    ));

    // 120 of 800 px is 15%, well short of the 40% threshold — but thrown.
    await t.fling(find.text('row'), const Offset(120, 0), 1200);
    await t.pumpAndSettle();

    expect(triggers, 1);
  });

  testWidgets('an interrupted drag leaves the row closed', (t) async {
    var triggers = 0;
    await t.pumpWidget(_Host(
      row: (_) => PortalSwipeRow(
        key: const ValueKey('row'),
        leading: PortalSwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          foregroundColor: Colors.red,
          onTrigger: () => triggers++,
        ),
        child: _row,
      ),
    ));

    final gesture = await t.startGesture(t.getCenter(find.text('row')));
    await gesture.moveBy(const Offset(500, 0));
    await t.pump();

    final pulled = t.getTopLeft(find.text('row')).dx;
    expect(pulled, greaterThan(0));
    // Past the threshold the row resists: it never travels as far as the
    // finger, and never further than its own width.
    expect(pulled, lessThan(500));

    // A second finger, a parent list taking over, the app backgrounded.
    await gesture.cancel();
    await t.pumpAndSettle();

    expect(t.getTopLeft(find.text('row')).dx, 0);
    expect(triggers, 0);
  });

  testWidgets('actions are custom semantics actions the row answers',
      (t) async {
    final handle = t.ensureSemantics();
    var triggers = 0;
    await t.pumpWidget(_Host(
      row: (_) => PortalSwipeRow(
        key: const ValueKey('row'),
        leading: PortalSwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          foregroundColor: Colors.red,
          onTrigger: () => triggers++,
        ),
        // The fleet's card: not a semantics boundary, so the action lands on
        // the row's node. A Material `Card` would need `semanticContainer:
        // false`.
        child: const PortalCard(child: _row),
      ),
    ));

    const action = CustomSemanticsAction(label: 'Delete');
    // The row's own label, not the background's: that one is excluded.
    expect(
      t.getSemantics(find.text('row')),
      isSemantics(label: 'row', customActions: [action]),
    );

    t.semantics.performAction(
      find.semantics.byLabel('row'),
      SemanticsAction.customAction,
      args: CustomSemanticsAction.getIdentifier(action),
    );
    await t.pump();

    expect(triggers, 1);
    handle.dispose();
  });
}
