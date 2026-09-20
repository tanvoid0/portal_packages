import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'portal_theme_build_context.dart';
import 'portal_theme_config.dart';

/// Builds [PortalThemeModes] from [config], following the device's dynamic
/// colour when [PortalThemeConfig.dynamicColor] is on.
///
/// ```dart
/// PortalDynamicColorBuilder(
///   config: myConfig,
///   builder: (context, modes) => MaterialApp(
///     theme: modes.light,
///     darkTheme: modes.dark,
///   ),
/// )
/// ```
///
/// With `dynamicColor` off (the default) this is [PortalThemeConfig.build] and
/// nothing else — no platform channel, no second build. With it on, the
/// widget asks the platform for its scheme ([DynamicColorPlugin]): the first
/// frame is the brand palette, and once the answer lands the seed is
/// harmonised toward the wallpaper's primary ([PortalThemeConfig.build]
/// `wallpaper:`). A device without dynamic colour stays on the brand palette.
///
/// The widget owns the query rather than wrapping [DynamicColorBuilder] so the
/// tree below [builder] keeps its shape whichever way the flag is set: an app
/// can flip `dynamicColor` from a settings screen without its `MaterialApp`
/// — and the navigator under it — being remounted.
class PortalDynamicColorBuilder extends StatefulWidget {
  const PortalDynamicColorBuilder({
    super.key,
    required this.config,
    required this.builder,
    this.accent,
  });

  final PortalThemeConfig config;

  /// Runtime accent, as [PortalThemeConfig.build] takes it. Harmonised too.
  final Color? accent;

  final Widget Function(BuildContext context, PortalThemeModes modes) builder;

  @override
  State<PortalDynamicColorBuilder> createState() =>
      _PortalDynamicColorBuilderState();
}

class _PortalDynamicColorBuilderState extends State<PortalDynamicColorBuilder> {
  /// The device's scheme once the platform has answered; null before that, on
  /// a device without dynamic colour, and whenever the flag is off.
  ColorScheme? _wallpaper;

  @override
  void initState() {
    super.initState();
    _query();
  }

  @override
  void didUpdateWidget(PortalDynamicColorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.dynamicColor == oldWidget.config.dynamicColor) return;
    _wallpaper = null; // off, or on again: brand until the platform answers
    _query();
  }

  Future<void> _query() async {
    if (!widget.config.dynamicColor) return;
    ColorScheme? scheme;
    try {
      // Android answers a CorePalette; desktop an accent colour; iOS neither.
      final palette = await DynamicColorPlugin.getCorePalette();
      if (palette != null) {
        // Light and dark share one hue ladder; the seed only needs the hue.
        scheme = palette.toColorScheme();
      } else {
        final accent = await DynamicColorPlugin.getAccentColor();
        if (accent != null) scheme = ColorScheme.fromSeed(seedColor: accent);
      }
    } on PlatformException {
      // Best-effort read: no dynamic colour here, the brand palette stands.
    }
    // Unmounted, or switched off while the platform was answering.
    if (!mounted || !widget.config.dynamicColor) return;
    setState(() => _wallpaper = scheme);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.config.build(accent: widget.accent, wallpaper: _wallpaper),
    );
  }
}
