## Unreleased

- `portalSettingsChildren()` (new): the settings sub-pages as `GetPage`
  children, for an app wiring a nested GetX route tree instead of a plain
  Navigator stack. Mount it under the same path given to the new
  `PortalSettingsPage.settingsRoute` (nullable `String`) — non-null, every
  row's `onTap` becomes `Get.toNamed` against that route instead of an
  unnamed `MaterialPageRoute` push; null (the default) keeps today's push
  behaviour exactly, so an existing caller is unaffected. `PortalSettingsSegment`
  carries the route segment names (`appearance`, `assistant`, `apps`,
  `about`, `account`, `change-password`) both this helper and
  `settingsRoute`'s navigation use, so a consuming app builds its own full
  paths from its root plus these rather than hand-typing each segment.
- The About sub-page self-probes reachability and loads the app version when
  not handed a snapshot (e.g. reached through `portalSettingsChildren()`'s
  own route rather than pushed from the hub), instead of staying stuck on
  "Checking...".
- `PortalDeepLinkAssistantView`'s back gesture now pops normally when there
  is a stack under it (`canPop: Navigator.of(context).canPop()`); a cold
  deep link (empty stack) still bounces to `fallbackRoute` exactly as before.
- `PortalSettingsPage` nests the infrequent groups behind their own pages: Appearance, Assistant, Portal apps and About are now one coalesced nav card of rows, each pushing a `PortalSettingsSubPage`; Account is its own separate card/page. The constructor is unchanged — `include`/`order` still take the same `PortalSettingsGroup` values, just rendered through a row instead of inline. The default `order` also changed (custom sections now come right after Profile instead of after Appearance, and Portal apps now comes before About) — every call site that doesn't pass its own `order` picks up the new layout.
- `PortalSettingsSubPage` (new): the chrome a pushed settings page shares with the hub — same background tone, `PortalAppBar`, and list padding.
- `PortalPasswordResetView` now builds on `portal_ui_core`'s `PortalAppBar`, `PortalTextField` and `PortalButton` instead of raw `AppBar`/`TextFormField`/`FilledButton` — presentation only, same fields, validation and API calls. The password fields use `PortalTextField.obscureToggle` for the show/hide eye.
- `PortalAuthConfig.of(identity)`: builds a config from a `portal_ui_core` `PortalAppIdentity` so an app states its icon/name/tagline once. `identity.logo` isn't forwarded — `appIconImage` is an asset path, not an `ImageProvider` — pass it on the plain constructor if needed. Needs `portal_ui_core` 0.3.0 (`PortalAppIdentity`); the constraint is raised to match.
- `PortalSettingsSection.slot` (new, defaults to `PortalSettingsGroup.custom`): a section can render right after a named group's own content instead of only in the `custom` slot.
- `PortalSettingsPage.header` (new): given, the page is just its `ListView` with `header` first — no `Scaffold`/`PortalAppBar` — for a caller embedding it under its own chrome. Loses the app bar's cloud-outage line; the Status group's own Mode row still reports it.

- `PortalSettingsPage` rebuilt as the grouped kit page: inset sections from `portal_ui_core`, a tonal tile on every row, headers as written (no longer upper-cased), and Portal Cloud's outage in the bar's status line. Needs `portal_ui_core` 0.2.1 (`PortalListAccessory.navigate(swatch:)`, `PortalAppBar(status:)`); the constraint is raised to match.
  - Profile is an account cell that opens an Edit name sheet; signed out, `onSignIn` (new) adds a Sign in row.
  - Appearance: Theme and Accent colour rows open sheets that apply on tap. The accent row shows the first of `palettes` while the controller holds no id.
  - `assistantSection` (new) draws the app's AI settings inline in the Assistant slot. `aiSection` is deprecated: it still works, as one "Assistant" row that opens the widget on its own page.
  - Status: Mode (Portal Cloud / On-device, from one readiness probe on open), App version (seven taps still open the server page) and Check for updates. This replaces the old Server and Assistant health rows.
  - The About group now holds the account block: Change password, Sign out, Delete account, under an "Account" heading. A failed delete is a retry prompt above the rows. The device-security row is no longer added here; an app that has one mounts it in its own `sections`.
  - `sectionBuilder` now wraps only `sections`; its default is a kit header over the children as given.
- `PortalAppsSection.grouped`: the same list as a kit section, with skeleton, error (retry), empty and data states, Check again on the header, a More button and long press holding Uninstall, and Install / Update asked in a sheet that shows what is new. The default constructor is unchanged.
- `portalInstallAndReport`: the install-and-snackbar tail of `showPortalUpdateDialog`, shared with the Install / Update sheet.
- `portalCanInstallApps` reads Flutter's `defaultTargetPlatform` rather than `Platform.isAndroid`, so a widget test can render the app list.
- `PortalSettingsLabels`: `account`, `signIn`, `signInSubtitle`, `editName`, `theme`, `accentColour`, `mode`, `modeCloud`, `modeOnDevice`, `cloudUnreachable`, `checkForUpdates`, `upToDate`, `updateCheckFailed`, `more`, `retry`, `whatsNew`, `later`. The sign out and delete account confirmations carry the new copy.

## 0.1.1

- Source moved to the public `portal_packages` repository; `repository:` link now resolves.
