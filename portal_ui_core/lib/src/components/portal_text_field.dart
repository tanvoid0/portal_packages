import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/portal_component_extensions.dart';
import '../theme/portal_form_field.dart';
import '../theme/portal_ui_theme.dart';

/// The one text input: label above, hint, helper, error, prefix, suffix.
///
/// Built on [PortalFormField] (label, description and error sit above and
/// below the control) around a [TextFormField] that takes its fill and
/// borders from the app's `InputDecorationTheme`, so focus and error states
/// come from the theme and never from here. A [validator] works inside a
/// `Form`; [errorText] is for a message the caller already has and wins over
/// the helper. [filled] is the borderless pill for a note or an invite-by-ID
/// box. Disabled draws through the theme's disabled border.
///
/// [PortalTextField.amount] is the money input: decimal keypad, a second dot
/// or third decimal stopped at the keyboard, the whole value selected on
/// focus (an existing `12.00` otherwise put the cursor after the pence and
/// typing `5` made `12.005`). Not a search box; that is `PortalSearchField`.
class PortalTextField extends StatefulWidget {
  const PortalTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
    this.filled = false,
    this.prefix,
    this.prefixText,
    this.suffix,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  }) : _selectAllOnFocus = false;

  /// A money input. [currencySymbol] is drawn by the field so it is never
  /// typed. [controller] is required: select-on-focus reads it. Seed it with
  /// [formatAmount].
  PortalTextField.amount({
    super.key,
    required TextEditingController this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.required = false,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.filled = false,
    String? currencySymbol,
    this.suffix,
    bool signed = false,
  })  : initialValue = null,
        obscureText = false,
        keyboardType = TextInputType.numberWithOptions(
          decimal: true,
          signed: signed,
        ),
        textInputAction = null,
        onSubmitted = null,
        inputFormatters = signed ? _signedFormatters : _amountFormatters,
        maxLines = 1,
        minLines = null,
        prefix = null,
        prefixText = currencySymbol,
        autofillHints = null,
        textCapitalization = TextCapitalization.none,
        _selectAllOnFocus = true;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;

  /// Draws the `*` beside the label.
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool autofocus;

  /// Borderless filled pill instead of the theme's bordered field.
  final bool filled;
  final Widget? prefix;
  final String? prefixText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  /// `words` for a name, `sentences` for prose; the amount form has none.
  final TextCapitalization textCapitalization;
  final bool _selectAllOnFocus;

  // Reject an edit that is not a whole amount rather than truncating it to the
  // longest matching prefix, which ate the tail of `1234.56` on a stray dot.
  static TextInputFormatter _amountFormatter(RegExp whole) =>
      TextInputFormatter.withFunction(
        (old, value) => whole.hasMatch(value.text) ? value : old,
      );
  static final _amountFormatters = <TextInputFormatter>[
    _amountFormatter(RegExp(r'^\d*[.,]?\d{0,2}$')),
  ];
  static final _signedFormatters = <TextInputFormatter>[
    _amountFormatter(RegExp(r'^-?\d*[.,]?\d{0,2}$')),
  ];

  /// `12.5` becomes `12.50`, `12.0` becomes `12`, null or zero becomes empty:
  /// what a person would type, so editing starts from a value they can read.
  static String formatAmount(double? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  /// Reads what [formatAmount] and the keyboard produce; garbage is 0.
  static double parseAmount(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  @override
  State<PortalTextField> createState() => _PortalTextFieldState();
}

class _PortalTextFieldState extends State<PortalTextField> {
  FocusNode? _ownFocus;

  FocusNode? get _focus => widget.focusNode ?? _ownFocus;

  @override
  void initState() {
    super.initState();
    if (widget._selectAllOnFocus) _attach();
  }

  @override
  void didUpdateWidget(PortalTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode && widget._selectAllOnFocus) {
      old.focusNode?.removeListener(_onFocus);
      _ownFocus?.removeListener(_onFocus);
      _ownFocus?.dispose();
      _ownFocus = null;
      _attach();
    }
  }

  void _attach() {
    if (widget.focusNode == null) _ownFocus = FocusNode();
    _focus!.addListener(_onFocus);
  }

  void _onFocus() {
    if (!_focus!.hasFocus) return;
    final c = widget.controller!;
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final skin = PortalTextFieldTheme.of(context);
    final pill = OutlineInputBorder(
      borderRadius: skin.borderRadius ?? BorderRadius.circular(tokens.radii.md),
      borderSide: BorderSide.none,
    );

    final decoration = InputDecoration(
      hintText: widget.hint,
      prefixText: widget.prefixText == null ? null : '${widget.prefixText} ',
      prefixIcon: widget.prefix == null
          ? null
          : Padding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.sm,
                end: tokens.spacing.xs,
              ),
              child: widget.prefix,
            ),
      suffixIcon: widget.suffix,
      constraints: BoxConstraints(minHeight: tokens.minTapTarget),
      // The theme's border carries error and focus; only a filled pill drops it.
      filled: widget.filled ? true : null,
      fillColor: widget.filled ? (skin.filledColor ?? portal.input) : null,
      border: widget.filled ? pill : null,
      enabledBorder: widget.filled ? pill : null,
      contentPadding: widget.filled
          ? (skin.contentPadding ??
              EdgeInsets.symmetric(
                horizontal: tokens.spacing.lg,
                vertical: tokens.spacing.md,
              ))
          : null,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);

    return PortalFormField(
      label: widget.label,
      description: widget.helper,
      error: widget.errorText,
      required: widget.required,
      excludeLabelSemantics: true,
      child: Semantics(
        label: widget.label,
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          initialValue: widget.controller == null ? widget.initialValue : null,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          style: tokens.textStyles.body,
          cursorColor: portal.primary,
          decoration: decoration,
        ),
      ),
    );
  }
}
