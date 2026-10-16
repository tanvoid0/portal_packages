import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../config/app_config.dart';
import 'local_only_session.dart';
import 'portal_google_sign_in.dart';
import 'portal_google_sign_in_registry.dart';
import '../routing/deep_link_service.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';

/// Shared authentication controller used by all Portal apps that use
/// email/password auth. Handles login, registration, demo login, and
/// optional server health-check.
class PortalAuthController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isTestingServer = false.obs;
  final isLogin = true.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final errorMessage = ''.obs;

  /// Errors that belong to one field, set from the server's answer: a wrong
  /// password is the password's own error, a taken email the email's. The view
  /// shows them on the field and clears each as it is edited; [errorMessage]
  /// stays for what no field owns (no connection).
  final emailError = RxnString();
  final passwordError = RxnString();

  /// Whether this install talks to the config's `testServerUrl` rather than
  /// the build's own server.
  final usingTestServer = false.obs;

  final formKey = GlobalKey<FormState>();

  bool get canUseDemoLogin =>
      kDebugMode &&
      _appConfig.demoEmail.trim().isNotEmpty &&
      _appConfig.demoPassword.isNotEmpty;

  bool get canUseGoogleSignIn =>
      _appConfig.googleSignInServerClientId.trim().isNotEmpty;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _googleSignInInstance {
    if (Get.isRegistered<PortalGoogleSignInRegistry>()) {
      return Get.find<PortalGoogleSignInRegistry>().instance;
    }
    return _googleSignIn ??= createPortalGoogleSignIn(
      webClientId: _appConfig.googleSignInServerClientId,
    );
  }

  @override
  void onInit() {
    super.onInit();
    usingTestServer.value = _apiClient.isOverridden;
  }

  /// Points the app at [url] (the test server) or back at the build default.
  /// [ApiClient.switchServer] clears tokens, which is right on a sign-in screen.
  Future<void> setTestServer(String url, bool on) async {
    await _apiClient.switchServer(on ? url : null);
    usingTestServer.value = on;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleMode() {
    isLogin.value = !isLogin.value;
    errorMessage.value = '';
    emailError.value = passwordError.value = null;
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
  }

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  void toggleConfirmPasswordVisibility() =>
      obscureConfirmPassword.value = !obscureConfirmPassword.value;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(value)) return 'Please enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateName(String? value) {
    if (!isLogin.value && (value == null || value.isEmpty)) {
      return 'Name is required';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (!isLogin.value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != passwordController.text) return 'Passwords do not match';
    }
    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    errorMessage.value = '';
    emailError.value = passwordError.value = null;

    // The session is stored by login()/register() itself, so a failure after
    // that point is not a failure to sign in -- saying "check your internet"
    // there sends people hunting a network problem that does not exist while
    // the next launch drops them straight into the app.
    var authenticated = false;
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (isLogin.value) {
        await _apiClient.login(email: email, password: password);
      } else {
        await _apiClient.register(
          email: email,
          password: password,
          name: nameController.text.trim(),
        );
      }
      authenticated = true;

      await Get.find<SessionController>().reloadFromStorage();
      final fallback = Get.find<AppConfig>().routeLoggedIn;
      await Get.find<DeepLinkService>().navigatePostAuth(fallback: fallback);
    } on ApiException catch (e) {
      // A refused sign-in or a taken email belongs to its field.
      if (isLogin.value && e.statusCode == 401) {
        passwordError.value = e.message;
      } else if (!isLogin.value && e.statusCode == 409) {
        emailError.value = e.message;
      } else {
        errorMessage.value = e.message;
      }
    } catch (e, st) {
      developer.log(
        'Auth request failed',
        name: 'PortalAuthController',
        error: e,
        stackTrace: st,
      );
      if (kDebugMode) {
        debugPrint('[PortalAuthController] URL: ${_apiClient.baseUrl}');
        debugPrint('[PortalAuthController] Error: $e');
      }
      errorMessage.value = authenticated
          ? 'Signed in, but this app could not open. Reopen it to continue.'
          : 'Connection error. Please check your internet.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Maps a native Google Sign-In failure to something a person can act on.
  ///
  /// `e.message`, not `e.details`, is where google_sign_in 6.x puts the GMS
  /// text ("com.google.android.gms.common.api.ApiException: 10: "), and
  /// showing it raw is what this used to do. The developer detail — which
  /// OAuth client is missing — goes to the log, not the screen.
  static String _googleSignInPlatformErrorMessage(PlatformException e) {
    final raw = '${e.code} ${e.message ?? ''} ${e.details ?? ''}';
    developer.log(
      'Google sign-in platform error: $raw',
      name: 'PortalAuthController',
    );
    if (e.code == 'sign_in_canceled') return '';
    if (e.code == 'network_error') {
      return 'No internet connection. Check your connection and try again.';
    }
    // Android ApiException 10 (DEVELOPER_ERROR): no OAuth client for this
    // package name + signing key. A user cannot fix it; email still works.
    if (raw.contains('ApiException: 10') || raw.contains('DEVELOPER_ERROR')) {
      return 'Google sign-in is not available in this build. '
          'Sign in with your email and password instead.';
    }
    return 'Google sign-in failed. Please try again.';
  }

  Future<void> signInWithGoogle() async {
    if (!canUseGoogleSignIn || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final account = await _googleSignInInstance.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        errorMessage.value =
            'Could not get Google credentials. Check OAuth client setup.';
        return;
      }

      await _apiClient.loginWithGoogle(idToken: idToken);
      await Get.find<SessionController>().reloadFromStorage();
      final fallback = Get.find<AppConfig>().routeLoggedIn;
      await Get.find<DeepLinkService>().navigatePostAuth(fallback: fallback);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } on PlatformException catch (e) {
      errorMessage.value = _googleSignInPlatformErrorMessage(e);
    } catch (e, st) {
      developer.log(
        'Google sign-in failed',
        name: 'PortalAuthController',
        error: e,
        stackTrace: st,
      );
      errorMessage.value = 'Google sign-in failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithDemo() async {
    if (!canUseDemoLogin || isLoading.value) return;
    if (!isLogin.value) isLogin.value = true;
    errorMessage.value = '';
    emailController.text = _appConfig.demoEmail.trim();
    passwordController.text = _appConfig.demoPassword;
    await submit();
  }

  /// Starts a device-local, no-server-account session: a consent prompt, an
  /// optional one-time encryption choice, then the device lock
  /// ([LocalOnlySession.start] — the only credential this session has).
  /// Declining the encryption prompt doesn't abort the flow; only declining
  /// the first consent, or the device lock failing/being declined, does.
  Future<void> continueWithoutAccount(
    void Function(bool encrypted)? onLocalOnlySessionStarted,
  ) async {
    if (isLoading.value) return;
    final context = Get.context;
    if (context == null) return;
    errorMessage.value = '';

    final proceed = await portalConfirm(
      context,
      title: 'Continue without an account?',
      message: 'Your data stays on this device only. You will be asked to '
          'set up a screen lock to protect it. You can sign in to sync to '
          'the cloud later.',
      confirmLabel: 'Continue',
    );
    if (!proceed) return;

    // Only an app with its own entity-persistence seam reads this choice
    // (see onLocalOnlySessionStarted's doc) — asking it elsewhere offers a
    // promise nothing honours.
    final encrypt = onLocalOnlySessionStarted == null
        ? false
        : await portalConfirm(
            context,
            title: 'Encrypt your data on this device?',
            message: 'There is no copy on a server. If you lose this device '
                'or clear app data, encrypted data cannot be recovered.',
            confirmLabel: 'Encrypt',
            cancelLabel: 'Not now',
          );

    isLoading.value = true;
    try {
      final outcome = await LocalOnlySession.start(encrypted: encrypt);
      switch (outcome) {
        case LocalOnlySessionOutcome.unavailable:
          errorMessage.value = 'Local-only mode is not available in this app.';
        case LocalOnlySessionOutcome.deviceLockDeclined:
          errorMessage.value = 'Local-only mode needs a screen lock. Set up a '
              'fingerprint, Face ID, or PIN on this device, then try again.';
        case LocalOnlySessionOutcome.started:
          onLocalOnlySessionStarted?.call(encrypt);
          await Get.find<SessionController>().reloadFromStorage();
          final fallback = Get.find<AppConfig>().routeLoggedIn;
          await Get.find<DeepLinkService>().navigatePostAuth(fallback: fallback);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkAuthStatus() async {
    return await _apiClient.isLoggedIn();
  }

  Future<void> logout() async {
    await Get.find<SessionController>().signOut();
  }

  Future<void> testServerStatus() async {
    if (isTestingServer.value) return;
    isTestingServer.value = true;
    try {
      final result = await _apiClient.checkHealth();
      if (result == null) {
        Get.snackbar('Server test', 'No response from server');
        return;
      }
      if (result.containsKey('error')) {
        Get.snackbar(
          'Server unreachable',
          result['error']?.toString() ?? 'Unknown error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
          duration: const Duration(seconds: 5),
        );
        return;
      }
      final status = result['status'] ?? 'ok';
      Get.snackbar(
        'Server OK',
        'Status: $status\nURL: ${_apiClient.baseUrl}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isTestingServer.value = false;
    }
  }
}
