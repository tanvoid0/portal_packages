import 'package:flutter/material.dart';

import 'portal_list_item.dart';

/// A single-select (or multi-select) picker row, for [portalOptionSection].
/// Half the fleet's sheets (sort, filter, category, column, duration…) are
/// the same "pick one (or several) of these" shape. Ported from the design
/// kit's `DemoOption`.
class PortalOption {
  const PortalOption(
    this.title, {
    this.subtitle,
    this.leading,
    this.disabledReason,
    this.titleSpans,
  });

  final String title;
  final String? subtitle;
  final PortalListLeading? leading;
  final String? disabledReason;
  final List<InlineSpan>? titleSpans;
}

/// The selectable section itself: one radio row per [options] (checkbox
/// when [multiple]), the [selected] indices outlined and heard so. Sits on
/// top of [PortalListSection.selectable].
PortalListSection portalOptionSection({
  String? header,
  required List<PortalOption> options,
  required Set<int> selected,
  bool multiple = false,
  required ValueChanged<int> onToggle,
}) => PortalListSection.selectable(
  header: header,
  selected: multiple ? null : (selected.isEmpty ? null : selected.first),
  selectedIndices: multiple ? selected : null,
  children: [
    for (final (i, o) in options.indexed)
      PortalListItem(
        title: o.title,
        subtitle: o.subtitle,
        leading: o.leading,
        disabledReason: o.disabledReason,
        titleSpans: o.titleSpans,
        trailing: multiple
            ? PortalListAccessory.checkbox(
                checked: selected.contains(i),
                onChanged: (_) => onToggle(i),
              )
            : PortalListAccessory.radio(
                checked: selected.contains(i),
                onChanged: (_) => onToggle(i),
              ),
      ),
  ],
);
