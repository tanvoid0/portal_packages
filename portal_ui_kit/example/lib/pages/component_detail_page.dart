import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../catalog/component_catalog.dart';
import '../widgets/highlighted_code.dart';

enum _DocTab { preview, usage, source }

class ComponentDetailPage extends StatefulWidget {
  const ComponentDetailPage({super.key, required this.entry});

  final ComponentEntry entry;

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  _DocTab _tab = _DocTab.preview;
  Future<String>? _sourceFuture;

  @override
  void didUpdateWidget(ComponentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _tab = _DocTab.preview;
      _sourceFuture = null;
    }
  }

  Future<String> _loadSource() {
    return rootBundle.loadString('lib/ui/${widget.entry.sourceFileName}');
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final textTheme = Theme.of(context).textTheme;

    final install = widget.entry.installCommand;
    final fromRoot = 'From repository root (after mason get):\n$install';

    return SingleChildScrollView(
      padding: EdgeInsets.all(t.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Text(widget.entry.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: t.spacing.sm),
        Text(widget.entry.description, style: textTheme.bodyLarge?.copyWith(color: portal.onSurfaceVariant)),
        SizedBox(height: t.spacing.lg),
        Text('Install', style: textTheme.titleSmall),
        SizedBox(height: t.spacing.sm),
        _CodeCard(text: fromRoot, onCopy: () => _copy(install)),
        SizedBox(height: t.spacing.lg),
        SegmentedButton<_DocTab>(
          segments: const [
            ButtonSegment(value: _DocTab.preview, label: Text('Preview'), icon: Icon(Icons.visibility_outlined)),
            ButtonSegment(value: _DocTab.usage, label: Text('Usage'), icon: Icon(Icons.code_outlined)),
            ButtonSegment(value: _DocTab.source, label: Text('Source'), icon: Icon(Icons.article_outlined)),
          ],
          selected: {_tab},
          onSelectionChanged: (s) {
            setState(() {
              _tab = s.first;
              if (_tab == _DocTab.source && _sourceFuture == null) {
                _sourceFuture = _loadSource();
              }
            });
          },
        ),
        SizedBox(height: t.spacing.lg),
        if (_tab == _DocTab.preview) _PreviewPanel(entry: widget.entry),
        if (_tab == _DocTab.usage) _UsagePanel(snippet: widget.entry.usageSnippet, onCopy: () => _copy(widget.entry.usageSnippet)),
        if (_tab == _DocTab.source)
          _SourcePanel(
            future: _sourceFuture ??= _loadSource(),
            onCopy: (s) => _copy(s),
          ),
      ],
    ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.entry});

  final ComponentEntry entry;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    final preview = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: Builder(builder: entry.preview),
      ),
    );

    if (portal.isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(t.radii.lg),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                      Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.16),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(t.spacing.lg),
              child: preview,
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.lg),
        side: BorderSide(color: portal.outline.withValues(alpha: 0.55), width: t.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(t.spacing.lg),
        child: preview,
      ),
    );
  }
}

class _UsagePanel extends StatelessWidget {
  const _UsagePanel({required this.snippet, required this.onCopy});

  final String snippet;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.lg),
        side: BorderSide(color: portal.outline.withValues(alpha: 0.55), width: t.borderWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Usage snippet', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            HighlightedCode(
              code: snippet,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({required this.future, required this.onCopy});

  final Future<String> future;
  final void Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Text(
            'Could not load source. Run tool/sync_example_bricks and flutter pub get.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          );
        }
        final code = snapshot.data!;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radii.lg),
            side: BorderSide(color: portal.outline.withValues(alpha: 0.55), width: t.borderWidth),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Generated file', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy all',
                      onPressed: () => onCopy(code),
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ],
                ),
                HighlightedCode(code: code, scrollVertically: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.text, required this.onCopy});

  final String text;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return Card(
      elevation: 0,
      color: portal.muted.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radii.md),
        side: BorderSide(color: portal.outline.withValues(alpha: 0.45), width: t.borderWidth),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HighlightedCode(
                code: text,
                language: 'bash',
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.45,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Copy mason command',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
