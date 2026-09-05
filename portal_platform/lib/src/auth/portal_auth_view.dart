import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_client.dart';
import 'portal_auth_config.dart';
import 'portal_auth_controller.dart';
import 'portal_password_reset_view.dart';

/// Shared authentication view for all Portal apps using email/password auth.
///
/// Shape is the host app's, not this file's: fields, buttons and corner radii
/// come from the app's `inputDecorationTheme`, `filledButtonTheme` and
/// `outlinedButtonTheme`, so an app restyles its login by restyling its theme
/// and nothing here has to know. Pass a [PortalAuthConfig] for branding and
/// feature flags.
///
/// The layout is a single column on a flat surface: title, subtitle, fields,
/// then one primary action pinned to the foot of the screen where a thumb
/// already is. No wash, no card, no badge — a sign-in screen is a form, and
/// decoration around it only pushes the action further from the thumb.
class PortalAuthView extends GetView<PortalAuthController> {
  const PortalAuthView({super.key, required this.config});

  final PortalAuthConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context, theme, cs),
                          const SizedBox(height: 28),
                          ..._fields(context, cs),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _footer(context, theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ThemeData theme, ColorScheme cs) {
    final signingIn = controller.isLogin.value;
    // Reached by a push from a gate screen in some apps and as the root route
    // in others; only the first can go back, and an arrow that does nothing is
    // worse than no arrow.
    final canGoBack = Navigator.of(context).canPop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: canGoBack
              ? IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                )
              : config.appIconImage != null
                  ? Image.asset(config.appIconImage!, width: 40, height: 40)
                  : Icon(config.appIcon, size: 32, color: cs.onSurface),
        ),
        Text(
          signingIn ? 'Sign in' : 'Create account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          signingIn ? config.appSubtitle : 'Set up your ${config.appTitle}.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        // A visible tell at the moment credentials are typed: a dev/QA server
        // override should never be silently mistaken for Cloud.
        if (Get.isRegistered<ApiClient>() && Get.find<ApiClient>().isOverridden)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Local server · ${Get.find<ApiClient>().baseUrl}',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }

  List<Widget> _fields(BuildContext context, ColorScheme cs) {
    final signingIn = controller.isLogin.value;
    return [
      if (controller.errorMessage.value.isNotEmpty) ...[
        _errorBanner(cs),
        const SizedBox(height: 16),
      ],
      if (!signingIn) ...[
        TextFormField(
          controller: controller.nameController,
          validator: controller.validateName,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        const SizedBox(height: 12),
      ],
      TextFormField(
        controller: controller.emailController,
        validator: controller.validateEmail,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(hintText: 'Email'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: controller.passwordController,
        validator: controller.validatePassword,
        obscureText: controller.obscurePassword.value,
        textInputAction:
            signingIn ? TextInputAction.done : TextInputAction.next,
        // The keyboard's done key is the last field's submit: without this it
        // only dismisses the keyboard and the form sits there.
        onFieldSubmitted: (_) {
          if (signingIn && !controller.isLoading.value) controller.submit();
        },
        decoration: InputDecoration(
          hintText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(
              controller.obscurePassword.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
        ),
      ),
      if (!signingIn) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.confirmPasswordController,
          validator: controller.validateConfirmPassword,
          obscureText: controller.obscureConfirmPassword.value,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!controller.isLoading.value) controller.submit();
          },
          decoration: InputDecoration(
            hintText: 'Confirm password',
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscureConfirmPassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: controller.toggleConfirmPasswordVisibility,
            ),
          ),
        ),
      ],
      if (signingIn)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.isLoading.value
                ? null
                : config.onForgotPassword ??
                    () => showPortalPasswordReset(
                          context,
                          email: controller.emailController.text,
                        ),
            child: const Text('Forgot password?'),
          ),
        ),
    ];
  }

  Widget _errorBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  /// Everything that acts, pinned to the foot. The primary action is the last
  /// thing above the gesture bar in every state, so it does not move as the
  /// form grows between sign-in and sign-up.
  Widget _footer(BuildContext context, ThemeData theme, ColorScheme cs) {
    final signingIn = controller.isLogin.value;
    final busy = controller.isLoading.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.canUseGoogleSignIn) ...[
            OutlinedButton.icon(
              onPressed: busy ? null : controller.signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 10),
          ],
          if (controller.canUseDemoLogin) ...[
            OutlinedButton.icon(
              onPressed: busy ? null : controller.loginWithDemo,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Demo login'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: busy ? null : controller.submit,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(signingIn ? 'Sign in' : 'Create account'),
          ),
          if (config.allowRegistration)
            TextButton(
              onPressed: busy ? null : controller.toggleMode,
              child: Text(
                signingIn
                    ? 'Don\'t have an account? Sign up'
                    : 'Already have an account? Sign in',
              ),
            ),
          if (config.showTestServer)
            TextButton.icon(
              onPressed: controller.isTestingServer.value
                  ? null
                  : controller.testServerStatus,
              icon: controller.isTestingServer.value
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : Icon(
                      Icons.health_and_safety_outlined,
                      size: 18,
                      color: cs.outline,
                    ),
              label: Text(
                controller.isTestingServer.value ? 'Testing…' : 'Test server',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
            ),
        ],
      ),
    );
  }
}
