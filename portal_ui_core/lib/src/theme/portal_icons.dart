import 'package:material_symbols_icons/symbols.dart';

export 'package:material_symbols_icons/symbols.dart' show Symbols;

/// The fleet's icon set: Material Symbols, one voice.
///
/// Every glyph is `Symbols.<name>_rounded` — the rounded style is the only one
/// the fleet draws, so the outlined and sharp fonts tree-shake to nothing in a
/// release build. Weight (400), grade (0) and optical size (24) come from the
/// theme's `IconThemeData` set by `buildPortalTheme`; never pass them at a
/// call site. Selection is `fill` 0 → 1 on the *same* glyph
/// (`Icon(Symbols.home_rounded, fill: 1)`), not a second `_filled` icon —
/// `PortalBottomNavBar` and `PortalFilterChip` animate it for you.
///
/// `PortalIcons` and `Symbols` are the same class; the alias exists so the
/// fleet's icon set has a Portal name to grep for.
typedef PortalIcons = Symbols;
