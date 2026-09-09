# Portal UI Kit

**Shadcn-inspired Flutter UI primitives**, delivered two ways.

**`portal_ui_core` is the default and the one apps actually use.** It is a real
package: design tokens and theming (`PortalUiTheme`, `DesignTokens`,
`buildPortalTheme`, `PortalThemeConfig`) *and* 15 ready-made widgets
(`PortalButton`, `PortalCard`, `PortalFilterChip`, `PortalEmptyState`,
`PortalSkeleton`, …). Add the path dependency, import it, compose. Brand goes in
a per-app skin that wraps these — see `apps/portal_gym/lib/ui/gym_skin/`.

**[Mason](https://pub.dev/packages/mason_cli) bricks are the escape hatch.**
`bricks/` generates copy-paste Dart into an app's `lib/ui/` for components
ui_core does not ship, when an app needs to own and edit the source. 39 bricks
exist; only three (`portal_button`, `portal_card`, `portal_skeleton`) overlap a
ui_core widget, and for those **prefer ui_core** — the brick and the widget have
drifted into different implementations of the same class name, and having both
in one app makes the import ambiguous.

> Reality check: the bricks, the example gallery and the sync scripts were all
> last touched in one commit on 2026-08-24 and have not moved since. Brick
> adoption in the fleet is three files in `portal_task`, already hand-edited
> past what the current brick source would regenerate — re-running `mason make`
> there would clobber real work. Treat the brick path as unmaintained until
> someone decides otherwise.

See [`../../docs/UI_PATTERNS.md`](../../docs/UI_PATTERNS.md) for the rules that
govern using any of this.

---

## What’s in this repository

| Location | Role |
|----------|------|
| [`packages/portal_ui_core`](packages/portal_ui_core) | Theme factory, `PortalUiTheme` (`ThemeExtension`), spacing/radius/type presets |
| [`bricks/`](bricks/) | One Mason brick per component; each emits a single `.dart` file |
| [`example/`](example) | **Interactive docs** — gallery with Preview, usage snippets, and full source per component |
| [`docs/COMPONENTS.md`](docs/COMPONENTS.md) | **Readable reference** — all bricks, filenames, and how to customize theme vs generated widgets |
| [`tool/sync_example_bricks.ps1`](tool/sync_example_bricks.ps1) / [`.sh`](tool/sync_example_bricks.sh) | Regenerate every brick into `example/lib/ui` (for contributors / CI) |

---

## Prerequisites

- **Flutter** (Dart **3.3+**)
- **Mason CLI**: `dart pub global activate mason_cli`

---

## Compatibility policy

- **portal_ui_core**: semver; patch/minor releases are additive only. Breaking changes require a major version and an entry in [CHANGELOG.md](CHANGELOG.md).
- **Mason bricks**: generated into your app’s `lib/ui/`; kit updates are opt-in via `mason make` or [tool/sync_app_widgets.ps1](tool/sync_app_widgets.ps1).

## Use the kit in your app

### 1. Theme (required)

Add a path dependency on `portal_ui_core` (adjust the path to your layout):

```yaml
dependencies:
  portal_ui_core:
    path: ../portal_ui_kit/packages/portal_ui_core
```

Wrap the app with `buildPortalTheme`:

```dart
import 'package:portal_ui_core/portal_ui_core.dart';

MaterialApp(
  theme: buildPortalTheme(
    brightness: Brightness.light,
    preset: PortalUiPreset.defaultPreset,
  ),
  darkTheme: buildPortalTheme(
    brightness: Brightness.dark,
    preset: PortalUiPreset.compact,
  ),
  // themeMode: ThemeMode.system, ...
);
```

Use **`colorScheme:`** on `buildPortalTheme` for brand colours. **`PortalUiPreset`** (`defaultPreset`, `compact`, `rounded`) switches spacing, radii, and type scale — see [`design_tokens.dart`](packages/portal_ui_core/lib/src/tokens/design_tokens.dart).

### 2. Components (generated into your repo)

From **this kit’s repository root** (or wherever `mason.yaml` is available):

```bash
mason get
mason make portal_button -o path/to/your_app/lib/ui
```

Repeat for other bricks (`portal_text_field`, `portal_card`, …). Full list: **[docs/COMPONENTS.md](docs/COMPONENTS.md)**.

Import the generated files and use the `Portal…` widgets. Generated files are yours to edit — which is also why a brick that overlaps a ui_core widget is a fork waiting to happen. Check `portal_ui_core` first.

---

## Documentation

| Resource | Description |
|----------|-------------|
| **[docs/COMPONENTS.md](docs/COMPONENTS.md)** | Per-component bricks, generated filenames, and customization (theme vs local edits) |
| **[example/](example)** | Run `flutter run` inside `example/` for the live gallery (Preview / Usage / Source tabs) |
| **[docs/legacy_inventory.md](docs/legacy_inventory.md)** | Optional table to map old internal widgets to new bricks when migrating |

---

## Run the example gallery

```bash
cd example
flutter pub get
flutter run
```

---

## Refresh generated UI in the example (contributors)

After changing bricks under `bricks/`, sync into the example from the **repository root**:

```bash
# Windows PowerShell
./tool/sync_example_bricks.ps1

# macOS / Linux
chmod +x tool/sync_example_bricks.sh   # once
./tool/sync_example_bricks.sh
```

The scripts invoke `dart pub global run mason_cli:mason`, so a global `mason` on `PATH` is optional.

Then:

```bash
cd example
flutter pub get
flutter run
```
