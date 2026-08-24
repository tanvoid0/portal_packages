import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalAccordionSection {
  const PortalAccordionSection({required this.title, required this.child});

  final String title;
  final Widget child;
}

/// Expansion tiles styled with [PortalUiTheme] (shadcn Accordion).
class PortalAccordion extends StatelessWidget {
  const PortalAccordion({
    required this.sections,
    super.key,
    this.initiallyExpandedIndex,
  });

  final List<PortalAccordionSection> sections;
  final int? initiallyExpandedIndex;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return PortalThemedSurface(
      borderRadius: BorderRadius.circular(t.radii.md),
      borderSide: portal.borderSide(),
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: portal.subtleBorderSide().color),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: initiallyExpandedIndex == i,
                tilePadding: EdgeInsets.symmetric(horizontal: t.spacing.lg, vertical: t.spacing.xs),
                childrenPadding: EdgeInsets.fromLTRB(t.spacing.lg, 0, t.spacing.lg, t.spacing.lg),
                title: Text(
                  sections[i].title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                iconColor: portal.onSurfaceVariant,
                collapsedIconColor: portal.onSurfaceVariant,
                children: [sections[i].child],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
