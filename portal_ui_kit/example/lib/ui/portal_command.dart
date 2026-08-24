import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalCommandItem<T> {
  const PortalCommandItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.keywords = const [],
    this.destructive = false,
  });

  final String title;
  final T value;
  final String? subtitle;
  final IconData? icon;
  final List<String> keywords;
  final bool destructive;

  String get _searchBlob =>
      [title, if (subtitle != null) subtitle!, ...keywords].join(' ').toLowerCase();
}

/// Full-screen or centered searchable command list (shadcn Command).
Future<T?> showPortalCommand<T>({
  required BuildContext context,
  required List<PortalCommandItem<T>> items,
  String title = 'Command palette',
  String hintText = 'Search…',
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => _PortalCommandDialog<T>(
      items: items,
      title: title,
      hintText: hintText,
    ),
  );
}

class _PortalCommandDialog<T> extends StatefulWidget {
  const _PortalCommandDialog({
    required this.items,
    required this.title,
    required this.hintText,
  });

  final List<PortalCommandItem<T>> items;
  final String title;
  final String hintText;

  @override
  State<_PortalCommandDialog<T>> createState() => _PortalCommandDialogState<T>();
}

class _PortalCommandDialogState<T> extends State<_PortalCommandDialog<T>> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<PortalCommandItem<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((e) => e._searchBlob.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Dialog(
      backgroundColor: portal.popover,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.lg),
        side: portal.borderSide(),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 420),
        child: Padding(
          padding: EdgeInsets.all(t.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: t.spacing.md),
              TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: Icon(Icons.search, color: portal.onSurfaceVariant),
                  filled: true,
                  fillColor: portal.surfaceVariant.withValues(alpha: 0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radii.md),
                    borderSide: BorderSide(color: portal.outline, width: t.borderWidth),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radii.md),
                    borderSide: BorderSide(color: portal.outline, width: t.borderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(t.radii.md),
                    borderSide: BorderSide(color: portal.primary, width: t.borderWidth + 0.5),
                  ),
                ),
              ),
              SizedBox(height: t.spacing.md),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: portal.onSurfaceVariant,
                              ),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final e = _filtered[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(e.value),
                                borderRadius: BorderRadius.circular(t.radii.sm),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: t.spacing.md,
                                    vertical: t.spacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      if (e.icon != null) ...[
                                        Icon(e.icon, size: 20, color: portal.onSurfaceVariant),
                                        SizedBox(width: t.spacing.md),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.title,
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                    color: e.destructive ? portal.destructive : null,
                                                    fontWeight: e.destructive ? FontWeight.w600 : null,
                                                  ),
                                            ),
                                            if (e.subtitle != null)
                                              Text(
                                                e.subtitle!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: portal.onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
