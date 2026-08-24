import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Multiline text field (shadcn Textarea).
class PortalTextArea extends StatelessWidget {
  const PortalTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.minLines = 3,
    this.maxLines = 6,
    this.onChanged,
    this.enabled = true,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final useFormShell = label != null || helper != null;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      enabled: enabled,
      inputFormatters: inputFormatters,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyMedium,
      cursorColor: portal.primary,
      decoration: portalInputDecoration(
        context,
        label: useFormShell ? null : label,
        hint: hint,
        helper: useFormShell ? null : helper,
        errorText: useFormShell ? null : errorText,
        enabled: enabled,
      ).copyWith(
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.all(portal.tokens.spacing.lg),
      ),
    );

    if (!useFormShell) return field;

    return PortalFormField(
      label: label,
      description: helper,
      error: errorText,
      child: field,
    );
  }
}
