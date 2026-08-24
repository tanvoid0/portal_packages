import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Form wrapper (shadcn Form).
class PortalForm extends StatelessWidget {
  const PortalForm({
    required this.child,
    super.key,
    this.formKey,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onChanged,
  });

  final Widget child;
  final GlobalKey<FormState>? formKey;
  final AutovalidateMode autovalidateMode;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      child: child,
    );
  }
}

/// Form field wired to [PortalFormField] label, description, and error UI.
class PortalValidatedField<T> extends FormField<T> {
  PortalValidatedField({
    required String label,
    required Widget Function(FormFieldState<T> state) fieldBuilder,
    super.key,
    this.description,
    super.validator,
    super.initialValue,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
  }) : super(
          builder: (state) {
            return PortalFormField(
              label: label,
              description: description,
              error: state.hasError ? state.errorText : null,
              child: fieldBuilder(state),
            );
          },
        );

  final String? description;
}
