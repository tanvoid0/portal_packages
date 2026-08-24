import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

enum PortalAvatarSize { sm, md, lg }

/// Circle avatar with optional image or initials fallback (shadcn Avatar).
class PortalAvatar extends StatelessWidget {
  PortalAvatar({
    super.key,
    this.image,
    this.initials,
    this.size = PortalAvatarSize.md,
  }) : assert(
          image != null || (initials?.trim().isNotEmpty ?? false),
          'Provide image or non-empty initials',
        );

  final ImageProvider? image;
  final String? initials;
  final PortalAvatarSize size;

  double _diameter(DesignTokens t) {
    switch (size) {
      case PortalAvatarSize.sm:
        return t.minTapTarget * 0.72;
      case PortalAvatarSize.md:
        return t.minTapTarget * 0.9;
      case PortalAvatarSize.lg:
        return t.minTapTarget * 1.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final d = _diameter(t);

    final child = image != null
        ? DecorationImage(image: image!, fit: BoxFit.cover)
        : null;

    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: portal.muted,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(portal.subtleBorderSide()),
        image: child,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Text(
              _twoInitials(initials!),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: portal.onMuted,
                    fontSize: d * 0.32,
                    fontWeight: FontWeight.w600,
                  ),
            )
          : null,
    );
  }

  static String _twoInitials(String raw) {
    final s = raw.toUpperCase().trim();
    if (s.isEmpty) return '?';
    if (s.length <= 2) return s;
    return s.substring(0, 2);
  }
}
