import 'dart:convert';

import 'package:flutter/material.dart';

import '../runtime/portal_ai_runtime.dart';
import '../tools/ai_tool.dart';

/// Drop-in assistant UI: prompt box, live step log and a confirmation prompt
/// before any tool that changes data.
///
/// ```dart
/// AiAssistantSheet.show(context, runtime: Get.find<PortalAiRuntime>());
/// ```
class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({
    super.key,
    required this.runtime,
    this.title = 'Assistant',
    this.suggestions = const [],
    this.onSettings,
    this.tools,
  });

  final PortalAiRuntime runtime;
  final String title;

  /// Example prompts shown as tappable chips before the first run.
  final List<String> suggestions;

  /// Opens the app's own AI settings, when it has any. The model and key live
  /// on the server, so there is nothing to configure here by default.
  final VoidCallback? onSettings;

  /// Overrides [PortalAiRuntime.tools] for this sheet, for tools that have to
  /// be built per call site (e.g. closed over a Riverpod ref).
  final List<AiTool>? tools;

  static Future<void> show(
    BuildContext context, {
    required PortalAiRuntime runtime,
    String title = 'Assistant',
    List<String> suggestions = const [],
    VoidCallback? onSettings,
    List<AiTool>? tools,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AiAssistantSheet(
        runtime: runtime,
        title: title,
        suggestions: suggestions,
        onSettings: onSettings,
        tools: tools,
      ),
    );
  }

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final _input = TextEditingController();
  final _steps = <AiAgentStep>[];
  bool _running = false;
  String? _reply;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _running) return;
    setState(() {
      _running = true;
      _reply = null;
      _error = null;
      _steps.clear();
    });
    try {
      final result = await widget.runtime.ask(
        prompt,
        tools: widget.tools,
        confirm: _confirm,
        onStep: (step) {
          if (mounted) setState(() => _steps.add(step));
        },
      );
      if (mounted) setState(() => _reply = result.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<bool> _confirm(AiTool tool, AiToolCall call) async {
    if (!mounted) return false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tool.name.replaceAll('_', ' ')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tool.description),
            if (call.args.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                const JsonEncoder.withIndent('  ').convert(call.args),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return approved ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title, style: theme.textTheme.titleMedium),
              ),
              if (widget.onSettings != null)
                IconButton(
                  tooltip: 'AI settings',
                  icon: const Icon(Icons.tune),
                  onPressed: widget.onSettings,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_steps.isEmpty && _reply == null && _error == null)
                    _Suggestions(
                      suggestions: widget.suggestions,
                      onTap: (text) {
                        _input.text = text;
                        _send();
                      },
                    ),
                  for (final step in _steps)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        step.failed ? Icons.error_outline : Icons.check_circle_outline,
                        color: step.failed ? theme.colorScheme.error : null,
                        size: 20,
                      ),
                      title: Text(step.call.name.replaceAll('_', ' ')),
                      subtitle: Text(step.result),
                    ),
                  if (_reply != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_reply!, style: theme.textTheme.bodyMedium),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            enabled: !_running,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'What should I do?',
              border: const OutlineInputBorder(),
              suffixIcon: _running
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: _send,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final suggestion in suggestions)
          ActionChip(label: Text(suggestion), onPressed: () => onTap(suggestion)),
      ],
    );
  }
}
