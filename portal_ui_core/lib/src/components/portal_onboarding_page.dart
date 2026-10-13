import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';
import 'portal_app_identity.dart';
import 'portal_button.dart';
import 'portal_button_dock.dart';
import 'portal_prompt.dart';

/// The signed-out start screen: the app's mark, its promise in [greeting]
/// and what it does in [question], centred above a dock with one primary
/// action. Ported from the design kit's `KitOnboarding` onto ui_core
/// primitives, so every app gets the same shape and differs only in
/// [identity] and copy.
///
/// Offline, a compact warning sits over the dock and [onSignIn] is disabled,
/// carrying the same reason as the button's hint.
class PortalOnboardingPage extends StatelessWidget {
  const PortalOnboardingPage({
    required this.identity,
    required this.greeting,
    required this.question,
    required this.onSignIn,
    this.hero,
    this.footnote,
    this.offline = false,
    this.signInLabel = 'Sign in',
    this.backgroundColor,
    super.key,
  });

  final PortalAppIdentity identity;

  /// Break on a line where it reads ('Your money,\nin one place'); the
  /// break is not heard.
  final String greeting;
  final String question;
  final VoidCallback onSignIn;

  /// Replaces [identity]'s default mark above the heading.
  final Widget? hero;

  /// A small muted line under the heading (terms, a version string).
  final String? footnote;

  final bool offline;
  final String signInLabel;
  final Color? backgroundColor;

  static const _offlineMessage =
      'No connection. Signing in needs the internet.';

  /// Past a phone's width the hero, copy and sign-in button stop stretching
  /// and sit centred in a comfortable measure instead of spanning a tablet.
  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;

    final heading = Semantics(
      header: true,
      label: '${greeting.replaceAll('\n', ' ')}. $question',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(
              greeting,
              textAlign: TextAlign.center,
              style: t.textStyles.display.copyWith(color: cs.onSurface),
            ),
            SizedBox(height: t.spacing.xs),
            Text(
              question,
              textAlign: TextAlign.center,
              style: t.textStyles.title.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        // Centred in what the dock leaves; too short (large text), it
        // scrolls, and the dock never moves. Never clamps TextScaler.
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.layout.pageHorizontal,
                      vertical: t.spacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        hero ?? _DefaultMark(identity: identity),
                        SizedBox(height: t.spacing.lg),
                        heading,
                        if (footnote != null) ...[
                          SizedBox(height: t.spacing.lg),
                          Text(
                            footnote!,
                            textAlign: TextAlign.center,
                            style: t.textStyles.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: PortalButtonDock(
        primary: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: t.spacing.md,
              children: [
                if (offline)
                  const PortalPrompt(
                    size: PortalPromptSize.compact,
                    sentiment: PortalSentiment.warning,
                    icon: Icons.cloud_off_rounded,
                    message: _offlineMessage,
                  ),
                // Off while offline; the warning above is its reason, and the
                // button carries it as its hint.
                Semantics(
                  hint: offline ? _offlineMessage : null,
                  child: PortalButton(
                    label: signInLabel,
                    size: PortalButtonSize.lg,
                    expand: true,
                    onPressed: offline ? null : onSignIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's identity, drawn as a hero mark when the caller gives no [hero]
/// of its own: [identity.logo] if there is one, else [identity.icon] on the
/// theme's primary.
class _DefaultMark extends StatelessWidget {
  const _DefaultMark({required this.identity});

  final PortalAppIdentity identity;

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(_size / 4);
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cs.primary, borderRadius: radius),
        child: identity.logo != null
            ? ClipRRect(
                borderRadius: radius,
                child: Image(
                  image: identity.logo!,
                  width: _size,
                  height: _size,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(identity.icon, size: 40, color: cs.onPrimary),
      ),
    );
  }
}
