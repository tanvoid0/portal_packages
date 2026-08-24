# Portal UI Kit — example (documentation app)

This Flutter app is the **live showcase** for the kit: every registered Mason brick has an overview entry with:

- **Preview** — interactive demo
- **Usage** — copy-paste snippet for your app
- **Source** — full generated `lib/ui/*.dart` (bundled as assets)

Theme and spacing use [portal_ui_core](../packages/portal_ui_core) presets from the sidebar (wide layout) or drawer footer (narrow).

## Regenerate `lib/ui` from bricks

From the **repository root** (not `example/`), run:

- Windows: `.\tool\sync_example_bricks.ps1`
- Unix: `./tool/sync_example_bricks.sh`

Then:

```bash
cd example
flutter pub get
flutter run
```

## More context

- [Root README](../README.md) — project overview, theming, and `mason make` in consumer apps
- [Component reference (docs)](../docs/COMPONENTS.md) — all bricks, filenames, and customization notes in one place
