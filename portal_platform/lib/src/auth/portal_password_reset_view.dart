import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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
  const PortalPasswordResetView({
    super.key,
    this.email,
    this.resendAfter = const Duration(seconds: 60),
    this.startOnCodeStep = false,
  });

  /// Prefills the email field (e.g. whatever was typed on the login form).
  final String? email;

  /// How long Resend stays asleep after a code is sent.
  final Duration resendAfter;

  /// Opens on the code step, as if the code had just been sent (the countdown
  /// starts too). For a deep link from the reset email, and the design kit.
  final bool startOnCodeStep;

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

  late bool _codeSent = widget.startOnCodeStep;
  bool _isLoading = false;
  String _errorMessage = '';

  Timer? _ticker;
  late int _resendWait = widget.startOnCodeStep ? _startCountdown() : 0;

  /// Counts [_resendWait] down once a second; returns its starting value.
  int _startCountdown() {
    _ticker?.cancel();
    if (widget.resendAfter.inSeconds <= 0) return 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendWait <= 1) t.cancel();
      if (mounted) setState(() => _resendWait--);
    });
    return widget.resendAfter.inSeconds;
  }

  String get _resendIn =>
      '${_resendWait ~/ 60}:${(_resendWait % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _ticker?.cancel();
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

  Future<void> _submit({bool resend = false}) async {
    if (!resend && !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final api = Get.find<ApiClient>();
      if (!_codeSent || resend) {
        await api.requestPasswordReset(email: _emailController.text.trim());
        setState(() {
          _codeSent = true;
          _resendWait = _startCountdown();
        });
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
      appBar: const PortalAppBar(title: 'Reset password'),
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
                    PortalTextField(
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: _codeSent,
                      label: 'Email',
                      prefix: const Icon(Icons.email_outlined),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 16),
                      PortalTextField(
                        controller: _codeController,
                        validator: _validateCode,
                        keyboardType: TextInputType.number,
                        label: 'Verification code',
                        prefix: const Icon(Icons.pin_outlined),
                      ),
                      // The countdown is information, so muted text rather
                      // than a disabled button's label.
                      if (_resendWait > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'You can resend in $_resendIn',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed:
                                _isLoading ? null : () => _submit(resend: true),
                            child: const Text('Resend code'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      PortalTextField(
                        controller: _newPasswordController,
                        validator: _validateNewPassword,
                        obscureToggle: true,
                        label: 'New password',
                        prefix: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: 16),
                      PortalTextField(
                        controller: _confirmPasswordController,
                        validator: _validateConfirmPassword,
                        obscureToggle: true,
                        label: 'Confirm password',
                        prefix: const Icon(Icons.lock_outline),
                      ),
                    ],
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 24),
                    PortalButton(
                      label: _codeSent ? 'Update password' : 'Send code',
                      size: PortalButtonSize.lg,
                      expand: true,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
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
