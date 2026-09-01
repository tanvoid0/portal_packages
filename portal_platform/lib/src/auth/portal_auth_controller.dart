import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
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

    // The session is stored by login()/register() itself, so a failure after
    // that point is not a failure to sign in -- saying "check your internet"
    // there sends people hunting a network problem that does not exist while
    // the next launch drops them straight into the app.
    var authenticated = false;
    try {
      if (isLogin.value) {
        await _apiClient.login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        await _apiClient.register(
          email: emailController.text.trim(),
          password: passwordController.text,
          name: nameController.text.trim(),
        );
      }
      authenticated = true;

      await Get.find<SessionController>().reloadFromStorage();
      final fallback = Get.find<AppConfig>().routeLoggedIn;
      await Get.find<DeepLinkService>().navigatePostAuth(fallback: fallback);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
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

  /// Maps native Google Sign-In failures to actionable copy (e.g. ApiException 10).
  static String _googleSignInPlatformErrorMessage(PlatformException e) {
    final details = e.details?.toString() ?? '';
    // Android: com.google.android.gms.common.api.ApiException: 10 (DEVELOPER_ERROR)
    if (details.contains('ApiException: 10') ||
        details.contains('DEVELOPER_ERROR')) {
      return 'Google Sign-In is misconfigured in Google Cloud. '
          'Create an Android OAuth client for package com.tanvoid0.portal_task '
          'with your debug SHA-1 (see apps/portal_task/docs/GOOGLE_SIGN_IN.md).';
    }
    return e.message?.trim().isNotEmpty == true
        ? e.message!.trim()
        : 'Google sign-in failed. Please try again.';
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
