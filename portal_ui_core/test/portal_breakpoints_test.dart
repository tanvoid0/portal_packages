import 'package:flutter_test/flutter_test.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

void main() {
  test('classFor lands on the right bucket at each boundary', () {
    expect(PortalBreakpoints.classFor(0), PortalSizeClass.compact);
    expect(PortalBreakpoints.classFor(599), PortalSizeClass.compact);
    expect(PortalBreakpoints.classFor(600), PortalSizeClass.medium);
    expect(PortalBreakpoints.classFor(839), PortalSizeClass.medium);
    expect(PortalBreakpoints.classFor(840), PortalSizeClass.expanded);
    expect(PortalBreakpoints.classFor(1199), PortalSizeClass.expanded);
    expect(PortalBreakpoints.classFor(1200), PortalSizeClass.large);
  });

  test('content cap: phone uncapped, wider classes capped and ordered', () {
    expect(portalMaxContentWidth(PortalSizeClass.compact).isFinite, isFalse);
    expect(
      portalMaxContentWidth(PortalSizeClass.medium) <
          portalMaxContentWidth(PortalSizeClass.expanded),
      isTrue,
    );
    expect(
      portalMaxContentWidth(PortalSizeClass.expanded) <
          portalMaxContentWidth(PortalSizeClass.large),
      isTrue,
    );
  });
}
