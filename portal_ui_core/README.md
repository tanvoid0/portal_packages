# portal_ui_core

Design system for the Portal apps: tokens (spacing, radii, type, motion,
elevation, layout), a `PortalUiTheme` ThemeExtension, theme factories and a
set of themed components.

<p>
<img src="https://raw.githubusercontent.com/tanvoid0/portal_packages/main/portal_ui_core/doc/screenshots/light.png" width="180" alt="Buttons, stat cards and cards, light theme">
<img src="https://raw.githubusercontent.com/tanvoid0/portal_packages/main/portal_ui_core/doc/screenshots/dark.png" width="180" alt="Same page, dark theme">
<img src="https://raw.githubusercontent.com/tanvoid0/portal_packages/main/portal_ui_core/doc/screenshots/light_states.png" width="180" alt="Filter chips, segmented tabs, search, skeleton and empty state">
<img src="https://raw.githubusercontent.com/tanvoid0/portal_packages/main/portal_ui_core/doc/screenshots/dark_states.png" width="180" alt="Same, dark theme">
</p>

Every screenshot is the `example/` app — run it on a device to walk the
components with a brightness and preset toggle in the app bar.

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
