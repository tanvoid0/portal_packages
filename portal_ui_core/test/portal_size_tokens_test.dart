import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  test('defaults are finance AppIconSize and AppSizes', () {
    const i = PortalIconSizes();
    expect(
      [i.xs, i.sm, i.md, i.lg, i.xl, i.xxl, i.xxxl],
      [14, 16, 18, 22, 28, 36, 44],
    );
    // The two steps task uses that finance lacks.
    expect([i.xxs, i.dense], [12, 20]);

    const c = PortalComponentSizes();
    expect(
      [c.buttonHeightSm, c.buttonHeightMd, c.buttonHeightLg],
      [36, 44, 52],
    );
    expect([c.inputHeightMd, c.inputHeightLg], [48, 56]);
    expect([c.cardPaddingSm, c.cardPaddingMd, c.cardPaddingLg], [14, 18, 22]);
    expect(
      [c.iconContainerSm, c.iconContainerMd, c.iconContainerLg, c.iconContainerXl],
      [36, 44, 52, 60],
    );
    expect([c.trackHeight, c.trackHeightSm, c.dotSm], [6, 4, 6]);
  });

  testWidgets('reachable from the theme, and an app can override', (t) async {
    late DesignTokens seen;
    await t.pumpWidget(MaterialApp(
      theme: buildPortalTheme(brightness: Brightness.light),
      home: Builder(builder: (c) {
        seen = PortalUiTheme.of(c).tokens;
        return const SizedBox();
      }),
    ));
    expect(seen.iconSizes.lg, 22);
    expect(seen.componentSizes.iconContainerMd, 44);

    const custom = DesignTokens(iconSizes: PortalIconSizes(lg: 24));
    expect(custom.iconSizes.lg, 24);
    expect(custom.iconSizes.sm, 16);
  });
}
