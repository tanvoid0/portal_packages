# portal_ui_core — design system spine

One page. The contract for apps is `docs/UI_PATTERNS.md`; this is what the
package itself decides. Where this and the code disagree, the code is right.

## Defaults

- **Typeface:** Plus Jakarta Sans, bundled (`pubspec.yaml` fonts, weights 400-800).
  `DesignTokens.fontFamily` defaults to it; `buildPortalTheme` sets it on
  `ThemeData`. An app overrides it through its tokens (journey's Lora headings,
  task's Inter via `PortalTypographyConfig.merge`).
- **Palette:** `lib/src/theme/portal_default_color_schemes.dart` (the default
  scheme) and `portal_color_palettes.dart` / `portal_theme_palette.dart` (the
  switchable catalogue). Apps usually bring a hand-tuned `ColorScheme` and pass
  it through `portalSchemeWithSeed` when the user picks a palette.
- **Contrast gate:** `lib/contrast_gate.dart`; every app scheme test runs it (F6).

## Tokens (`lib/src/tokens/design_tokens.dart`)

`PortalUiTheme.of(context).tokens`: spacing, radii, `typeScale` (xs..xxl plus
emoji and display steps), `textStyles` (display .. overline), motion,
elevation, layout (`pageHorizontal`, `sectionGap`, `listBottomInset`),
`minTapTarget` (48), `iconSizes`, `componentSizes`. Presets in
`portal_design_token_presets.dart`.

## Theme entry

`PortalThemeConfig` (`lib/src/theme/portal_theme_config.dart`): `tokens`,
`colorSchemeBuilder`, `portalUiThemeBuilder`, `extensionsBuilder`,
`componentThemeOptionsBuilder`, `typography`, `customize`. Lower tiers:
`buildPortalTheme` (`theme_factory.dart`), then a hand-built `PortalUiTheme`.

## Extensions it defines

`lib/src/theme/portal_component_extensions.dart`: `PortalStatCardTheme`,
`PortalEmptyStateTheme`, `PortalBadgeTheme`, `PortalProgressTheme`,
`PortalTextFieldTheme`, `PortalCalendarTheme`, `PortalCardTheme`,
`PortalFilterChipTheme`, `PortalNavBarTheme`. Every field is nullable; null
derives from the tokens; a widget argument wins. Also `PortalSemanticColors`
(`portal_semantic_colors.dart`) for success / warning / info / danger.

## Components

`lib/src/components/`: buttons (`PortalButton`, `.icon`, `PortalButtonDock`),
surfaces (`PortalCard`, `PortalSheet`, dialogs), rows (`PortalListItem`,
`PortalListSection`, `PortalSliverListSection`), inputs (`PortalTextField`,
`PortalSelect`, `PortalStepper`, `PortalCalendar`), feedback (`PortalPrompt`,
`PortalAppFeedback`, `PortalBlockingProgress`), states (`PortalEmptyState`,
`PortalSkeleton`, `PortalResultScreen`), navigation (`PortalBottomNavBar`,
`PortalScrollPage`). Formatting: `lib/src/format/` (`PortalFormat`,
`PortalAmount`).

## Deliberately not here

Brand colour, a bespoke typeface, a domain widget (a ledger row's index tab, a
workout sparkline), a date range or year picker, a custom format pattern string
(add a named style). Unreleased additions: `CHANGELOG.md`.
