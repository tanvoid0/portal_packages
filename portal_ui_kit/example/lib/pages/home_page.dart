import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../catalog/component_catalog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onPick});

  final void Function(ComponentEntry entry) onPick;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.all(t.spacing.lg),
      children: [
        Text('Portal UI Kit', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: t.spacing.sm),
        Text(
          'Copy-paste components for Flutter, generated with Mason into your lib/ui folder. '
          'Tokens and theme live in portal_ui_core. Pick a color palette and theme style '
          '(Material, Clean, Atomic, Glass, …) in the sidebar to preview every component.',
          style: textTheme.bodyLarge?.copyWith(color: PortalUiTheme.of(context).onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.lg),
        Text('Components', style: textTheme.titleMedium),
        SizedBox(height: t.spacing.sm),
        Text(
          'Pick a component in the sidebar to see a live preview, usage snippet, and the generated source.',
          style: textTheme.bodyMedium?.copyWith(color: PortalUiTheme.of(context).onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.xl),
        for (final cat in ComponentCategory.values) ...[
          Text(cat.catalogLabel, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: t.spacing.sm),
          Wrap(
            spacing: t.spacing.sm,
            runSpacing: t.spacing.sm,
            children: [
              for (final e in kComponentCatalog.where((c) => c.category == cat))
                ActionChip(
                  label: Text(e.title),
                  onPressed: () => onPick(e),
                ),
            ],
          ),
          SizedBox(height: t.spacing.xl),
        ],
      ],
    );
  }
}
