# Portal UI Kit — component reference

This page is the **static companion** to the [example app](../example): same
components, with a scannable list of where each one comes from and how
customisation works.

Two sources, and the **Source** column says which applies:

- **ships in `portal_ui_core`** — a real widget in the package. Import it and
  compose; brand it through your app's skin. This is the default.
- a **brick name** — Mason generates the source into your app's `lib/ui/`, for
  components ui_core does not ship. If a generated component turns out to be
  shared, promote it into `portal_ui_core` rather than leaving a copy in each
  app. Components travel one direction: brick → app → ui_core, never back.

---

## How customisation works

### 1. Global look and feel (`portal_ui_core`)

- **`buildPortalTheme`** — attach Portal styling to `MaterialApp`. Use **`PortalUiPreset`** (`defaultPreset`, `compact`, `rounded`) for spacing, corner radii, and type scale (`DesignTokens` in code).
- **`colorScheme:`** — pass a Flutter `ColorScheme` to brand the app; Portal maps it into **`PortalUiTheme`** (semantic colours: primary, destructive, outline, muted, etc.).
- **Runtime access** — widgets read **`PortalUiTheme.of(context)`** and **`Theme.of(context)`** for colours and typography.

Relevant source: [`packages/portal_ui_core/lib/src/theme/theme_factory.dart`](../packages/portal_ui_core/lib/src/theme/theme_factory.dart), [`design_tokens.dart`](../packages/portal_ui_core/lib/src/tokens/design_tokens.dart), [`portal_ui_theme.dart`](../packages/portal_ui_core/lib/src/theme/portal_ui_theme.dart).

### 2. Per-widget behaviour and layout (generated `lib/ui/*.dart`)

Bricks emit **plain Dart** into your app. After `mason make …`, you own the files: add parameters, tweak layout, or fork a widget without fighting a package API.

- **Variants and sizes** — each file documents its own `enum`s (e.g. button variant/size, alert variant, badge variant). Search the generated class for `enum`.
- **Theme wiring** — generated widgets typically use `PortalUiTheme.of(context)` and `portal.tokens` (`spacing`, `radii`, `minTapTarget`, `borderWidth`). Changing presets or `colorScheme` updates all of them consistently.
- **Regenerating** — re-running Mason can overwrite files; keep app-specific edits in wrappers or copy bricks into version control and merge carefully.

### 3. Motion utilities (`portal_ui_core`)

- **`PortalShimmer`** — themed shimmer sweep for loading placeholders; used by `PortalSkeleton`.
- **`PortalStaggeredChild`** / **`wrapStaggeredList`** — list reveal animations via `flutter_animate`.
- **`PortalPageTransitions`** — `sharedAxis` and `fadeThrough` routes via the official `animations` package.

```dart
Navigator.of(context).push(
  PortalPageTransitions.fadeThrough(
    context: context,
    page: const SettingsPage(),
  ),
);
```

### 4. Optional brick dependencies

Some generated widgets require an extra line in your app's `pubspec.yaml`:

| Brick | Package |
|-------|---------|
| `portal_spinner` | `flutter_spinkit: ^5.2.1` |
| `portal_slidable` | `flutter_slidable: ^4.0.0` |

### 5. Install command (per brick)

From the repository root, after `mason get`:

```text
mason make <brick_name> -o lib/ui
```

Use your app’s output path instead of `lib/ui` if you prefer another folder.

---

## Actions

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Button | **ships in `portal_ui_core`** | `PortalButton` | `PortalButtonVariant`, `PortalButtonSize`, `leading`, `expand`, labels |
| Toggle | `portal_toggle` | `portal_toggle.dart` | `pressed`, `onPressed`, child (icon/text) |

---

## Form & input

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Text field | `portal_text_field` | `portal_text_field.dart` | Label, hint, validation, controllers |
| Text area | `portal_text_area` | `portal_text_area.dart` | `minLines` / `maxLines`, label, hint |
| Label | `portal_label` | `portal_label.dart` | Text, required indicator |
| Checkbox | `portal_checkbox` | `portal_checkbox.dart` | Value, label, subtitle, `onChanged` |
| Switch | `portal_switch` | `portal_switch.dart` | Boolean value and label |
| Slider | `portal_slider` | `portal_slider.dart` | Value range, discrete steps, label |
| Radio group | `portal_radio_group` | `portal_radio_group.dart` | `PortalRadioOption` rows, group value |
| Select | `portal_select` | `portal_select.dart` | Items, value, `onChanged` |
| Calendar | `portal_calendar` | `portal_calendar.dart` | Selected day, `onSelected`, navigation |

---

## Feedback

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Alert | `portal_alert` | `portal_alert.dart` | Variant (e.g. destructive), title, description, actions |
| Snack bar | `portal_snackbar` | `portal_snackbar.dart` | Opaque themed toast (`AppToast` + `PortalToastHost`); variants: neutral / success / destructive |
| Progress | `portal_progress` | `portal_progress.dart` | Determinate value vs indeterminate |
| Skeleton | **ships in `portal_ui_core`** | `PortalSkeleton` | Width, height, shape (shimmer via `portal_ui_core`) |
| Spinner | `portal_spinner` | `portal_spinner.dart` | `PortalSpinnerStyle`, size, color — requires `flutter_spinkit` |
| Slidable | `portal_slidable` | `portal_slidable.dart` | Start/end swipe actions — requires `flutter_slidable` |

---

## Layout

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Card | **ships in `portal_ui_core`** | `PortalCard` | `PortalCardVariant` (standard, glass, hero, asymmetric), `PortalCardElevation`, `heroAccent`, optional tap |
| Divider | `portal_divider` | `portal_divider.dart` | Spacing around rule |
| Separator | `portal_separator` | `portal_separator.dart` | Horizontal vs vertical, length |
| Aspect ratio | `portal_aspect_ratio` | `portal_aspect_ratio.dart` | `aspectRatio`, child |
| Scroll area | `portal_scroll_area` | `portal_scroll_area.dart` | Scrollbar visibility, controller |
| Collapsible | `portal_collapsible` | `portal_collapsible.dart` | Title, animated body |
| Accordion | `portal_accordion` | `portal_accordion.dart` | List of sections |

---

## Overlay

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Alert dialog | `portal_dialog` | `portal_dialog.dart` | `showPortalAlertDialog` — title, message, confirm/cancel, destructive styling |
| Sheet | `portal_sheet` | `portal_sheet.dart` | `showPortalSheet` content, sizing |
| Tooltip | `portal_tooltip` | `portal_tooltip.dart` | Message, child trigger |
| Command palette | `portal_command` | `portal_command.dart` | `showPortalCommand` items, search |
| Dropdown menu | `portal_dropdown_menu` | `portal_dropdown_menu.dart` | Trigger, `PortalMenuAction` list |

---

## Navigation

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Tabs | `portal_tabs` | `portal_tabs.dart` | Tab labels, tab view height, children |
| Breadcrumb | `portal_breadcrumb` | `portal_breadcrumb.dart` | Items, taps |
| Pagination | `portal_pagination` | `portal_pagination.dart` | Current/total pages, `onPageChanged` |

---

## Display

| Component | Source | Class / file | What you customize |
|-----------|-------------|----------------|--------------------|
| Badge | `portal_badge` | `portal_badge.dart` | `PortalBadgeVariant`, label |
| Avatar | `portal_avatar` | `portal_avatar.dart` | Image, initials, `PortalAvatarSize` |
| Table | `portal_table` | `portal_table.dart` | Column headers, row data |

---

## Interactive documentation

Run the [example app](../example) for **Preview**, **Usage** snippets, and **full generated source** for each brick:

```bash
cd example
flutter pub get
flutter run
```

After changing bricks in this repo, sync files into the example with [`tool/sync_example_bricks.ps1`](../tool/sync_example_bricks.ps1) or [`tool/sync_example_bricks.sh`](../tool/sync_example_bricks.sh) from the repository root.
