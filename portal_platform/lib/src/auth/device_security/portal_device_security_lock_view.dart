import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'device_security_controller.dart';

/// Full-screen unlock UI shown when the app is locked.
class PortalDeviceSecurityLockView extends GetView<DeviceSecurityController> {
  const PortalDeviceSecurityLockView({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Obx(
        () => controller.needsWebPinSetup.value
            ? const _WebPinSetupView()
            : const _WebPinUnlockView(),
      );
    }
    return const _BiometricUnlockView();
  }
}

class _BiometricUnlockView extends GetView<DeviceSecurityController> {
  const _BiometricUnlockView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    controller.strings.unlockTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.strings.unlockSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: controller.isBusy.value
                          ? null
                          : controller.tryUnlock,
                      icon: controller.isBusy.value
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(controller.strings.unlockButton),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebPinUnlockView extends StatefulWidget {
  const _WebPinUnlockView();

  @override
  State<_WebPinUnlockView> createState() => _WebPinUnlockViewState();
}

class _WebPinUnlockViewState extends State<_WebPinUnlockView> {
  final _pinController = TextEditingController();
  DeviceSecurityController get _controller => Get.find<DeviceSecurityController>();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await _controller.submitWebPin(_pinController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pin_outlined, size: 56, color: cs.primary),
                  const SizedBox(height: 24),
                  Text(
                    _controller.strings.unlockTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your app PIN to continue',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  Obx(() {
                    final err = _controller.webPinError.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        err,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Obx(
                    () => FilledButton(
                      onPressed: _controller.isBusy.value ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _controller.isBusy.value
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text(_controller.strings.unlockButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebPinSetupView extends StatefulWidget {
  const _WebPinSetupView();

  @override
  State<_WebPinSetupView> createState() => _WebPinSetupViewState();
}

class _WebPinSetupViewState extends State<_WebPinSetupView> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  DeviceSecurityController get _controller => Get.find<DeviceSecurityController>();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await _controller.setupWebPin(
      _pinController.text,
      _confirmController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  Icon(Icons.pin_outlined, size: 56, color: cs.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Create app PIN',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Web does not support biometrics. Choose a PIN to protect your data on this browser.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  Obx(() {
                    final err = _controller.webPinError.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        err,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Obx(
                    () => FilledButton(
                      onPressed: _controller.isBusy.value ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _controller.isBusy.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save PIN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
