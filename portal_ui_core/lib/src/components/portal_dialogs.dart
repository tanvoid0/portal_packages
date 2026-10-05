import 'package:flutter/material.dart';

import '../motion/portal_haptics.dart';
import '../theme/portal_ui_theme.dart';
import 'portal_list_item.dart';
import 'portal_text_field.dart';

/// Asks for one line of text. Resolves to the text, or null when cancelled or
/// dismissed. The same `AlertDialog` chrome as `portalConfirm`.
///
/// [validator] runs on OK (and on the keyboard's done): a returned string is
/// shown under the field and the dialog stays open. [trim] strips surrounding
/// whitespace from the result; the validator sees the raw text.
Future<String?> portalInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? label,
  String? hint,
  String initialValue = '',
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
  FormFieldValidator<String>? validator,
  TextCapitalization textCapitalization = TextCapitalization.sentences,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool trim = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _InputDialog(
      title: title,
      message: message,
      label: label,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      validator: validator,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      maxLines: maxLines,
      trim: trim,
    ),
  );
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.message,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.validator,
    required this.textCapitalization,
    required this.keyboardType,
    required this.maxLines,
    required this.trim,
  });

  final String title;
  final String? message;
  final String? label;
  final String? hint;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool trim;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    PortalHaptics.medium();
    final text = _controller.text;
    Navigator.pop(context, widget.trim ? text.trim() : text);
  }

  @override
  Widget build(BuildContext context) {
    final sp = PortalUiTheme.of(context).tokens.spacing;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              SizedBox(height: sp.md),
            ],
            PortalTextField(
              controller: _controller,
              label: widget.label,
              hint: widget.hint,
              autofocus: true,
              // The dialog returns the trimmed text, so that is what is checked.
              validator: widget.validator == null
                  ? null
                  : (v) => widget.validator!(widget.trim ? v?.trim() : v),
              textCapitalization: widget.textCapitalization,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              textInputAction:
                  widget.maxLines == 1 ? TextInputAction.done : null,
              onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// One row of [portalChoiceDialog].
class PortalChoice<T> {
  const PortalChoice({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// The label in the error colour (delete, sign out).
  final bool isDestructive;
}

/// Picks one of N [choices]. Resolves to its value, or null when cancelled or
/// dismissed. The same chrome as `portalConfirm`; for a long-press menu on a
/// row prefer `showPortalActionSheet`, this is for a question.
Future<T?> portalChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required List<PortalChoice<T>> choices,
  String? message,
  String? cancelLabel = 'Cancel',
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(message),
              ),
            for (final c in choices)
              PortalListItem(
                title: c.label,
                leading:
                    c.icon == null ? null : PortalListLeading.icon(c.icon!),
                destructive: c.isDestructive,
                onTap: () => Navigator.pop(ctx, c.value),
              ),
          ],
        ),
      ),
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelLabel),
          ),
      ],
    ),
  );
}

/// A modal that blocks the screen while work runs: a spinner and a [message].
/// Not dismissible by barrier or back.
///
/// Use [run]: it shows the modal, awaits the task, closes the modal whether
/// the task returned or threw, and hands back the result (or rethrows, so a
/// failure still reaches the caller to tell the user).
class PortalBlockingProgress extends StatelessWidget {
  const PortalBlockingProgress({super.key, this.message});

  final String? message;

  static Future<T> run<T>(
    BuildContext context,
    Future<T> Function() task, {
    String? message,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    // Built by hand so the same route can be removed: a bare pop() would take
    // whatever the task left on top.
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (_) => PortalBlockingProgress(message: message),
    );
    navigator.push(route);
    try {
      return await task();
    } finally {
      if (route.isActive) navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Semantics(
          liveRegion: true,
          label: message ?? 'Loading',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              if (message != null) ...[
                SizedBox(width: tokens.spacing.lg),
                Flexible(child: ExcludeSemantics(child: Text(message!))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
