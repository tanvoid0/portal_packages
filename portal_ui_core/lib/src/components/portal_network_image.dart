import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/portal_icons.dart';

/// A network image with a cached fetch and a glyph fallback — a missing,
/// empty, or still-loading [url] shows [fallbackIcon] on [fallbackColor]
/// instead of a blank box or a broken-image glyph.
///
/// Give it [size] for a square/circle tile, or [width]/[height] separately
/// (leave either null to size from the parent — an [AspectRatio] above it,
/// say). [shape] clips to [BoxShape.circle] or a rounded rect via
/// [borderRadius]; [border] and [boxShadow] decorate that same outline, for
/// a photo tile that sits on its own against a page background.
class PortalNetworkImage extends StatelessWidget {
  const PortalNetworkImage({
    super.key,
    required this.url,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.fallbackIcon = PortalIcons.image_rounded,
    this.fallbackIconSize,
    this.fallbackIconColor,
    this.fallbackColor,
    this.cacheKey,
  });

  /// Trimmed and checked for empty — a blank string is "no image", not a
  /// fetch worth attempting.
  final String? url;

  /// Sets [width] and [height] together. Ignored where either is set.
  final double? size;
  final double? width;
  final double? height;
  final BoxFit fit;

  final BoxShape shape;

  /// Only meaningful when [shape] is [BoxShape.rectangle].
  final BorderRadius? borderRadius;

  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  final IconData fallbackIcon;

  /// Defaults to 0.42 of the shorter fixed side, clamped 20-36 — the same
  /// scale whether the tile is a 40 list avatar or a 120 hero.
  final double? fallbackIconSize;

  /// Defaults to the theme's `onSurfaceVariant`, dimmed while [url] is
  /// loading. A set colour (a category's accent, say) paints at full
  /// strength throughout instead — it is already a deliberate choice, not
  /// the generic "nothing here yet" muted glyph.
  final Color? fallbackIconColor;

  /// Defaults to the theme's `surfaceContainerHighest`.
  final Color? fallbackColor;

  /// Separate cache entries when [url] alone would collide (a `PageView`
  /// reusing the same remote image at different slots, say).
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final trimmed = url?.trim() ?? '';

    final decoration = BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : borderRadius,
      border: border,
      boxShadow: boxShadow,
    );

    final child = trimmed.isEmpty
        ? _fallback(context, w, h)
        : CachedNetworkImage(
            key: ValueKey(cacheKey ?? trimmed),
            imageUrl: trimmed,
            cacheKey: cacheKey ?? trimmed,
            width: w,
            height: h,
            fit: fit,
            memCacheWidth: _memCacheDimension(w),
            memCacheHeight: _memCacheDimension(h),
            placeholder: (context, url) =>
                _fallback(context, w, h, dimmed: true),
            errorWidget: (context, url, error) => _fallback(context, w, h),
          );

    return Container(
      width: w,
      height: h,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _fallback(BuildContext context, double? w, double? h,
      {bool dimmed = false}) {
    final scheme = Theme.of(context).colorScheme;
    final bg = fallbackColor ??
        scheme.surfaceContainerHighest.withValues(alpha: dimmed ? 0.5 : 1);
    final side = w ?? h;
    final iconSize = fallbackIconSize ??
        (side == null || !side.isFinite ? 28 : (side * 0.42).clamp(20, 36));
    return Container(
      width: w,
      height: h,
      color: bg,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: fallbackIconColor ??
            scheme.onSurfaceVariant.withValues(alpha: dimmed ? 0.35 : 0.55),
      ),
    );
  }

  static int? _memCacheDimension(double? dimension) {
    if (dimension == null || !dimension.isFinite || dimension <= 0) {
      return null;
    }
    return (dimension * 2).round();
  }
}
