import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// The painted pill's height, and the hit area around it.
///
/// Batch K, K1: the 44dp minimum box used to sit *inside* the button's
/// padding, so md painted 68dp and lg 76dp where the kit paints 48 and 56.
/// The height belongs to the painted box; the tap target is a box around it,
/// never taller paint (`UI_PATTERNS.md`).
void main() {
  const tokens = DesignTokens(); // the shipped minTapTarget, 44

  Future<void> pump(WidgetTester tester, PortalButtonSize size) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildPortalTheme(
            brightness: Brightness.light,
            tokens: tokens,
          ),
          home: Scaffold(
            body: Center(
              child: PortalButton(
                label: 'Save',
                size: size,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

  /// The painted box is the `Ink`'s, not the tap target's.
  double paintedHeight(WidgetTester tester) => tester
      .getSize(
        find.descendant(of: find.byType(PortalButton), matching: find.byType(Ink)),
      )
      .height;

  double tapHeight(WidgetTester tester) =>
      tester.getSize(find.byType(PortalButton)).height;

  testWidgets('md paints 48', (tester) async {
    await pump(tester, PortalButtonSize.md);
    expect(paintedHeight(tester), 48);
  });

  testWidgets('lg paints 56', (tester) async {
    await pump(tester, PortalButtonSize.lg);
    expect(paintedHeight(tester), 56);
  });

  testWidgets('sm paints 36', (tester) async {
    await pump(tester, PortalButtonSize.sm);
    expect(paintedHeight(tester), 36);
  });

  testWidgets('a small button still takes a full tap target', (tester) async {
    await pump(tester, PortalButtonSize.sm);
    expect(paintedHeight(tester), lessThan(tokens.minTapTarget));
    expect(tapHeight(tester), greaterThanOrEqualTo(tokens.minTapTarget));
  });

  testWidgets('md and lg already clear the tap target, so they are not grown',
      (tester) async {
    for (final size in [PortalButtonSize.md, PortalButtonSize.lg]) {
      await pump(tester, size);
      expect(tapHeight(tester), paintedHeight(tester));
    }
  });
}
