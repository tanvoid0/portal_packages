import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_client.dart';
import 'portal_settings_labels.dart';

/// The change-password form, without a scaffold around it.
///
/// Separate from [PortalChangePasswordPage] because `portal_task` renders it
/// inside its own settings sub-page chrome (a large page header and its own
/// back button) rather than an [AppBar], and that is the only difference
/// between the two apps' screens — the fields, the validation and the reveal
/// toggles were identical.
///
/// [onSubmit] replaces the whole write, not just a step of it: the server
/// call is one line, and an app with key material wrapped by the old password
/// has work on both sides of it. `portal_task` verifies the current password
/// against its vault wrap first and rewraps the DEK after, which cannot live
/// here — `portal_vault` sits *above* this package. Whatever it throws is
/// shown in place; throw an [ApiException] for a message the user should read.
///
/// The form pops with `true` once [onSubmit] returns.
class PortalChangePasswordForm extends StatefulWidget {
  const PortalChangePasswordForm({
    super.key,
    this.labels = const PortalSettingsLabels(),
    this.onSubmit,
  });

  final PortalSettingsLabels labels;
  final Future<void> Function(String currentPassword, String newPassword)?
      onSubmit;

  @override
  State<PortalChangePasswordForm> createState() =>
      _PortalChangePasswordFormState();
}

class _PortalChangePasswordFormState extends State<PortalChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _defaultSubmit(String current, String next) =>
      Get.find<ApiClient>()
          .changePassword(currentPassword: current, newPassword: next);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await (widget.onSubmit ?? _defaultSubmit)(_current.text, _next.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            labels.changePasswordIntro,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _PasswordField(
            controller: _current,
            label: labels.currentPassword,
            labels: labels,
            validator: (v) =>
                (v == null || v.isEmpty) ? labels.currentPasswordMissing : null,
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _next,
            label: labels.newPassword,
            labels: labels,
            validator: (v) =>
                (v == null || v.length < 8) ? labels.newPasswordTooShort : null,
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _confirm,
            label: labels.confirmPassword,
            labels: labels,
            validator: (v) =>
                v != _next.text ? labels.passwordsDoNotMatch : null,
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(labels.changePasswordSubmit),
          ),
        ],
      ),
    );
  }
}

/// Change the password of the signed-in Portal account, on its own screen.
///
/// Lifted out of `portal_task`, which was the only app that had one — the
/// account is shared, so the other five could sign in with a password they
/// had no way to change.
class PortalChangePasswordPage extends StatelessWidget {
  const PortalChangePasswordPage({
    super.key,
    this.labels = const PortalSettingsLabels(),
    this.onSubmit,
  });

  final PortalSettingsLabels labels;
  final Future<void> Function(String currentPassword, String newPassword)?
      onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(labels.changePassword)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            PortalChangePasswordForm(labels: labels, onSubmit: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.labels,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final PortalSettingsLabels labels;
  final String? Function(String?) validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscure,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure
              ? widget.labels.showPassword
              : widget.labels.hidePassword,
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
