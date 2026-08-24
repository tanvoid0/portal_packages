# Legacy widget inventory

Use this table when migrating from an older Portal UI or internal widget set to the Mason-based **brick** outputs. Each row is optional team documentation: add your legacy class names and the replacement brick or widget.

| Legacy widget / file | Replacement brick | Generated file (`lib/ui/`) | Notes |
|----------------------|-------------------|----------------------------|-------|
| | | | |

**How to fill this in**

1. Find usages of the old component in your app.
2. Add a `portal_ui_core` dependency and apply `buildPortalTheme` if not already done.
3. Run `mason make <brick_name> -o lib/ui` for the matching brick from [COMPONENTS.md](COMPONENTS.md).
4. Replace the legacy widget with the new `Portal…` class (or your edited copy).
5. Record the mapping in the table above so the next migration is faster.

For the canonical list of bricks and APIs, see **[COMPONENTS.md](COMPONENTS.md)**.
