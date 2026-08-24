import 'package:flutter/material.dart';

import 'theme_pair.dart';

/// Simple theme picker. Callers that used the old Provider-backed widget can
/// pass [currentTheme] / [onThemeChanged]; with no callbacks it is display-only.
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({
    super.key,
    this.title = 'Theme',
    this.currentTheme,
    this.currentThemeMode,
    this.onThemeChanged,
    this.onThemeModeChanged,
  });

  final String title;
  final ThemePair? currentTheme;
  final ThemeMode? currentThemeMode;
  final ValueChanged<String>? onThemeChanged;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final theme in customThemes)
          ListTile(
            title: Text(theme.name),
            selected: currentTheme?.name == theme.name,
            onTap: onThemeChanged == null
                ? null
                : () => onThemeChanged!(theme.name),
          ),
      ],
    );
  }
}
