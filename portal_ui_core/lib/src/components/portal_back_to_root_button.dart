import 'package:flutter/material.dart';

/// Leading button for an app-root screen: one tap back to the shell.
///
/// A real `IconButton` (48 dp target, named by [tooltip]) with the platform's
/// back glyph. [onPressed] defaults to `Navigator.maybePop`, which is what
/// `Get.back()` is under a `GetMaterialApp`; pass your own to pop a nested
/// navigator or leave the app. Drop it in `PortalAppBar(leading:)`.
class PortalBackToRootButton extends StatelessWidget {
  const PortalBackToRootButton({super.key, this.onPressed, this.tooltip});

  final VoidCallback? onPressed;

  /// Defaults to Material's localized "Back".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const BackButtonIcon(),
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
