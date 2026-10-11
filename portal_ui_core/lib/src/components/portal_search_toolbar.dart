import 'package:flutter/material.dart';

import '../theme/portal_icons.dart';
import '../theme/portal_theme_helpers.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_search_field.dart';

/// A removable chip shown under a [PortalSearchToolbar]'s search row — an
/// active filter the user can clear without reopening the filter sheet.
@immutable
class PortalSearchToolbarChip {
  const PortalSearchToolbarChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;
}

/// Search field with optional filter/sort icon actions and a row of active
/// filter chips underneath.
///
/// Generalizes the search+filter row several apps hand-built per list screen
/// (task's own `AppListSearchToolbar` now delegates here; it was already
/// used by four of task's own hubs). [filterCount] draws a small dot on the
/// filter button once it is non-zero — it does not print the number; an app
/// that wants the count itself (gym's exercise library) composes its own
/// button rather than bending this one, since that is a different look, not
/// a missing parameter.
class PortalSearchToolbar extends StatelessWidget {
  const PortalSearchToolbar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onClear,
    this.filterCount = 0,
    this.onFilterTap,
    this.sortLabel,
    this.onSortTap,
    this.chips = const [],
    this.padding,
    this.autofocus = false,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final int filterCount;
  final VoidCallback? onFilterTap;
  final String? sortLabel;
  final VoidCallback? onSortTap;
  final List<PortalSearchToolbarChip> chips;
  final EdgeInsets? padding;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tokens = context.portalTokens;
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(tokens.spacing.lg, 0, tokens.spacing.lg, tokens.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: controller != null
                    ? ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller!,
                        builder: (context, value, _) => PortalSearchField(
                          controller: controller,
                          autofocus: autofocus,
                          hintText: hintText,
                          onChanged: onChanged,
                          onClear: onClear == null
                              ? null
                              : () {
                                  controller?.clear();
                                  onClear?.call();
                                  onChanged?.call('');
                                },
                        ),
                      )
                    : PortalSearchField(
                        controller: controller,
                        autofocus: autofocus,
                        hintText: hintText,
                        onChanged: onChanged,
                        onClear: onClear,
                      ),
              ),
              if (onFilterTap != null) ...[
                SizedBox(width: tokens.spacing.sm),
                _ToolbarIconButton(
                  icon: PortalIcons.filter_list_rounded,
                  tooltip: 'Filters',
                  hasDot: filterCount > 0,
                  onTap: onFilterTap!,
                ),
              ],
              if (onSortTap != null) ...[
                SizedBox(width: tokens.spacing.sm),
                _ToolbarIconButton(
                  icon: PortalIcons.sort_rounded,
                  tooltip: sortLabel ?? 'Sort',
                  hasDot: false,
                  onTap: onSortTap!,
                ),
              ],
            ],
          ),
          if (chips.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.sm),
            Wrap(
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.sm,
              children: [
                for (final chip in chips)
                  InputChip(
                    label: Text(chip.label),
                    onDeleted: chip.onRemoved,
                    deleteIcon: Icon(PortalIcons.close_rounded, size: tokens.iconSizes.sm),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.hasDot,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: portal.surfaceVariant,
          borderRadius: BorderRadius.circular(tokens.radii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(tokens.radii.md),
            child: SizedBox(
              width: tokens.minTapTarget,
              height: tokens.minTapTarget,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: tokens.iconSizes.dense, color: portal.mutedForeground),
                  if (hasDot)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: portal.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
