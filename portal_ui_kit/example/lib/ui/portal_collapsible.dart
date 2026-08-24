import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Single disclosure with animated body (shadcn Collapsible).
class PortalCollapsible extends StatefulWidget {
  const PortalCollapsible({
    required this.title,
    required this.child,
    super.key,
    this.initiallyOpen = false,
  });

  final String title;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<PortalCollapsible> createState() => _PortalCollapsibleState();
}

class _PortalCollapsibleState extends State<PortalCollapsible> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(t.radii.sm),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: portal.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeOut,
          sizeCurve: Curves.easeOut,
          crossFadeState: _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          firstChild: Padding(
            padding: EdgeInsets.only(bottom: t.spacing.md),
            child: widget.child,
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
