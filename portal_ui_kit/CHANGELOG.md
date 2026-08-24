# Changelog

All notable changes to the Portal UI Kit follow [Semantic Versioning](https://semver.org/).

## Compatibility policy

- **portal_ui_core** (theme + tokens): patch and minor releases are additive only. Breaking API changes require a major version bump and migration notes in this file.
- **Mason bricks** (generated widgets): apps own their generated `lib/ui/` copies. Re-run `mason make` to adopt brick updates; kit changes do not auto-apply to consumers.
- **portal_ui_compat** / **portal_ui**: deprecated aliases for legacy apps. New apps should depend on `portal_ui_core` only.

## [0.1.0] - 2026-05-18

### Added

- `portal_ui_compat` with `PortalUiTokens` mapping to `portal_ui_core` defaults.
- `portal_ui` legacy package re-exporting compat (for `package:portal_ui/portal_ui.dart`).
- `tool/sync_app_widgets.ps1` to generate a curated widget subset into consumer apps.
