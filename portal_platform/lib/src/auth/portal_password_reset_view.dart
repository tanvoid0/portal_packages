import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_client.dart';

/// Opens the shared two-step password reset screen.
///
/// Pushed on the local [Navigator] rather than a named GetX route so apps do
/// not each have to register a route and a binding for it.
Future<void> showPortalPasswordReset(BuildContext context, {String? email}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => PortalPasswordResetView(email: email)),
  );
}

/// Request a reset code by email, then set a new password with that code.
///
/// Backed by `/auth/password-reset/request` and `/auth/password-reset/complete`
/// — the server mails the one-time code.
class PortalPasswordResetView extends StatefulWidget {
  const PortalPasswordResetView({super.key, this.email});

  /// Prefills the email field (e.g. whatever was typed on the login form).
  final String? email;

  @override
  State<PortalPasswordResetView> createState() =>
      _PortalPasswordResetViewState();
}

class _PortalPasswordResetViewState extends State<PortalPasswordResetView> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.email?.trim() ?? '',
  );
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateCode(String? value) {
    if (!_codeSent) return null;
    if (value == null || value.trim().length < 4) return 'Enter the code';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_codeSent) return null;
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_codeSent) return null;
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final api = Get.find<ApiClient>();
      if (!_codeSent) {
        await api.requestPasswordReset(email: _emailController.text.trim());
        setState(() => _codeSent = true);
        Get.snackbar(
          'Check your email',
          'If an account exists, a reset code was sent to your inbox.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await api.completePasswordReset(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        Get.snackbar(
          'Password updated',
          'Sign in with your new password.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _codeSent
                          ? 'Enter the code we emailed you and your new password.'
                          : 'Enter your account email. We will send a verification code.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: _codeSent,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        validator: _validateCode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        validator: _validateNewPassword,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        validator: _validateConfirmPassword,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_codeSent ? 'Update password' : 'Send code'),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                _codeSent = false;
                                _errorMessage = '';
                                _codeController.clear();
                              }),
                        child: const Text('Use a different email'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
