import 'package:flutter/material.dart';

import '../session/session_controller.dart';

/// The signed-in user's photo, falling back to their initials.
///
/// One widget rather than a `CircleAvatar` per screen: every app shows this in
/// at least two places (app bar and settings), and they had drifted into
/// reading different keys off the user map — gym looked for `avatar` and
/// `profileImageUrl`, neither of which the server has ever sent. The photo URL
/// comes from [SessionController.avatarUrlFor] and nowhere else.
///
/// [foregroundImage] is deliberate: when the URL 404s or the device is offline,
/// Flutter keeps painting the [child], so a stale Google photo URL degrades to
/// initials instead of an error box. A `backgroundImage` would not.
class PortalAvatar extends StatelessWidget {
  const PortalAvatar({
    super.key,
    required this.user,
    this.radius = 18,
    this.fontSize,
    this.imageUrlOverride,
    this.onTap,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Map<String, dynamic>? user;
  final double radius;

  /// Defaults to a size that stays legible as [radius] changes.
  final double? fontSize;

  /// Used when the profile has no Google photo — an app-specific image such as
  /// gym's program owner picture. Ignored when the profile has its own.
  final String? imageUrlOverride;

  final VoidCallback? onTap;
  final String? tooltip;

  /// Overrides the theme colours, for a surface the colour scheme does not
  /// cover -- gym's gradient hero paints white on a translucent circle.
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final signedIn = user != null;
    final url = SessionController.avatarUrlFor(user) ??
        (imageUrlOverride?.trim().isNotEmpty == true
            ? imageUrlOverride!.trim()
            : null);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ??
          (signedIn ? cs.primaryContainer : cs.surfaceContainerHighest),
      foregroundColor: foregroundColor ??
          (signedIn ? cs.onPrimaryContainer : cs.onSurfaceVariant),
      foregroundImage: url == null ? null : NetworkImage(url),
      child: Text(
        SessionController.initialsFor(user),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: fontSize ?? radius * 0.78,
        ),
      ),
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }
    return tooltip == null ? avatar : Tooltip(message: tooltip!, child: avatar);
  }
}
