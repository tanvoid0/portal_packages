## Unreleased

- `PortalPressable`: press state for anything tappable — shrinks to the new `PortalMotion.pressScale` token (0.97) on the effects spring while held, springs back on the spatial one. It hosts the `InkWell`, so the scale follows Material's own pressed state (a press that becomes a scroll releases) and a quick tap still plays the press out before springing back; the ripple is off unless asked for. `PortalCard(onTap:)` presses the whole surface with no ripple, `PortalButton` keeps its ripple and adds the scale (a loading button now goes through the same path and announces as disabled), `PortalFilterChip` and `PortalStatCard` press too.

- Spring motion tokens. `PortalMotion` carries the M3 Expressive springs (`spatialFast/Default/Slow`, `effectsFast/Default/Slow`) as `SpringDescription`s plus `PortalSpringCurve`, a `Curve` that plays a spring to its settle time and exposes that as `duration` for implicit animations. `standard` is now the effects spring (never overshoots, so nothing that lerps opacity, shadows or padding breaks) and `emphasized` the spatial one; page transitions, the stagger reveal, bottom nav, segmented tabs and filter chip run on them.

- Plus Jakarta Sans ships in the package (`assets/fonts/`, OFL). `PortalTypeScale.fontFamily` defaults to it and `buildPortalTheme` sets it as `ThemeData.fontFamily`, so an app gets the fleet typeface with no font of its own; a per-style family in `PortalTextStyles` still wins.

## 0.1.2

- Example app and screenshots.

