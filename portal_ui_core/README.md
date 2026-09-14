# portal_ui_core

Design system for the Portal apps: tokens (spacing, radii, type, motion,
elevation, layout), a `PortalUiTheme` ThemeExtension, theme factories and a
set of themed components.

```dart
import 'package:portal_ui_core/portal_ui_core.dart';

MaterialApp(
  theme: buildPortalTheme(brightness: Brightness.light),
  darkTheme: buildPortalTheme(brightness: Brightness.dark),
);

// in a widget
final tokens = PortalUiTheme.of(context).tokens;
Padding(padding: EdgeInsets.all(tokens.spacing.md), child: PortalCard(...));
```

Components: `PortalAppBar`, `PortalBottomNavBar`, `PortalButton`, `PortalCard`,
`PortalConfirmDialog`, `PortalEmptyState`, `PortalFilterChip`, `PortalSkeleton`
/ `PortalListSkeleton`, `PortalScrollPage`, `PortalSearchField`,
`PortalSectionHeader`, `PortalSegmentedTabs`, `PortalStatCard`,
`PortalStartupGate` / `PortalStartupSplash`.

Three tiers of theme entry, take the highest that fits:
`PortalThemeConfig` → `buildPortalTheme` → hand-rolled `PortalUiTheme`.
