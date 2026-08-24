import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

class PortalTextField extends StatelessWidget {
  const PortalTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final useFormShell = label != null || helper != null;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      enabled: enabled,
      autofillHints: autofillHints,
      style: Theme.of(context).textTheme.bodyMedium,
      cursorColor: portal.primary,
      decoration: portalInputDecoration(
        context,
        label: useFormShell ? null : label,
        hint: hint,
        helper: useFormShell ? null : helper,
        errorText: useFormShell ? null : errorText,
        prefix: prefix,
        suffix: suffix,
        enabled: enabled,
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
