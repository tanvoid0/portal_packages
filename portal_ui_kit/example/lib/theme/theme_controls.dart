import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Sidebar controls: color palette, visual theme style, and light/dark mode.
class ThemeControls extends StatelessWidget {
  const ThemeControls({
    super.key,
    required this.paletteId,
    required this.visualThemeId,
    required this.themeMode,
    required this.onPaletteChanged,
    required this.onVisualThemeChanged,
    required this.onThemeModeChanged,
  });

  final PortalThemePaletteId paletteId;
  final String visualThemeId;
  final ThemeMode themeMode;
  final ValueChanged<PortalThemePaletteId> onPaletteChanged;
  final ValueChanged<String> onVisualThemeChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final visualThemes = PortalVisualThemeCatalog.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Color palette', style: textTheme.labelLarge),
        SizedBox(height: t.spacing.xs),
        Text(
          'Accent and surface colors — independent of layout style.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        _PalettePicker(
          selected: paletteId,
          onChanged: onPaletteChanged,
        ),
        SizedBox(height: t.spacing.lg),
        Text('Theme style', style: textTheme.labelLarge),
        SizedBox(height: t.spacing.xs),
        Text(
          'Layout, borders, density, and component chrome via ThemeData.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        ...visualThemes.map((visual) {
          final selected = visual.id == visualThemeId;
          return Padding(
            padding: EdgeInsets.only(bottom: t.spacing.xs),
            child: _VisualThemeTile(
              visual: visual,
              selected: selected,
              onTap: () => onVisualThemeChanged(visual.id),
            ),
          );
        }),
        SizedBox(height: t.spacing.md),
        Text('Appearance', style: textTheme.labelLarge),
        SizedBox(height: t.spacing.xs),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {themeMode},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onThemeModeChanged(s.first);
          },
        ),
        SizedBox(height: t.spacing.sm),
        _ImportHint(paletteId: paletteId, visualThemeId: visualThemeId),
      ],
    );
  }
}

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({
    required this.selected,
    required this.onChanged,
  });

  final PortalThemePaletteId selected;
  final ValueChanged<PortalThemePaletteId> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(t.radii.md),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.spacing.sm),
        child: Wrap(
          spacing: t.spacing.sm,
          runSpacing: t.spacing.sm,
          children: [
            for (final palette in PortalThemeCatalog.all)
              _PaletteSwatch(
                palette: palette,
                selected: palette.id == selected,
                onTap: () => onChanged(palette.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final PortalThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = PortalUiTheme.of(context).tokens;

    return Tooltip(
      message: palette.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radii.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.xs,
            vertical: t.spacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radii.sm),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.25)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.seedColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.4),
                  ),
                ),
              ),
              SizedBox(height: t.spacing.xs),
              Text(
                palette.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualThemeTile extends StatelessWidget {
  const _VisualThemeTile({
    required this.visual,
    required this.selected,
    required this.onTap,
  });

  final PortalVisualTheme visual;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final isExperimental = visual.tags.contains('experimental');

    return Material(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.md),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.md,
            vertical: t.spacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                _iconFor(visual.id),
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              SizedBox(width: t.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          visual.label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                        ),
                        if (isExperimental) ...[
                          SizedBox(width: t.spacing.xs),
                          Text(
                            'exp',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      color: scheme.tertiary,
                                    ),
                          ),
                        ],
                      ],
                    ),
                    if (visual.description != null)
                      Text(
                        visual.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 18, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'material' => Icons.layers_outlined,
        'clean' => Icons.auto_awesome_outlined,
        'atomic' => Icons.grid_view_rounded,
        'glass' => Icons.blur_on_outlined,
        'expressive' => Icons.waves_outlined,
        _ => Icons.palette_outlined,
      };
}

class _ImportHint extends StatelessWidget {
  const _ImportHint({
    required this.paletteId,
    required this.visualThemeId,
  });

  final PortalThemePaletteId paletteId;
  final String visualThemeId;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(t.radii.sm),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.spacing.sm),
        child: Text(
          "PortalThemeComposer.build(\n"
          "  palette: PortalThemeCatalog.byId(PortalThemePaletteId.${paletteId.name}),\n"
          "  visualTheme: PortalVisualThemeRegistry.instance.byId('$visualThemeId'),\n"
          ")",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
                height: 1.35,
                fontSize: 10,
              ),
        ),
      ),
    );
  }
}
