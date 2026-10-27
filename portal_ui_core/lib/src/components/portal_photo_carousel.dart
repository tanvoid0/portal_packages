import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/portal_icons.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/portal_contrast.dart';
import 'portal_network_image.dart';

/// A swipeable photo hero: a `PageView` of [urls] with a glass pill of
/// expanding dot indicators at the bottom. [peek] < 1 shows the next card's
/// edge (travel_buddy's `TrendingPlaceSwiper`); the default 1 is full-bleed.
/// Dots are hidden under two photos; zero photos shows [fallbackIcon] in a
/// single tile instead of a `PageView`.
class PortalPhotoCarousel extends StatefulWidget {
  const PortalPhotoCarousel({
    super.key,
    required this.urls,
    this.height,
    this.peek = 1,
    this.borderRadius,
    this.fallbackIcon = PortalIcons.image_rounded,
    this.onPageChanged,
    this.semanticLabel,
    this.caption,
  });

  final List<String> urls;
  final double? height;

  /// `PageController.viewportFraction`. 1 is full-bleed; less peeks the
  /// neighbouring photo's edge.
  final double peek;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final ValueChanged<int>? onPageChanged;

  /// Defaults to 'Photo ${index + 1} of $count'.
  final String Function(int index, int count)? semanticLabel;

  /// Bottom caption band over the current photo, travel_buddy's dark-scrim
  /// style -- not the page dots, which always draw.
  final Widget? caption;

  @override
  State<PortalPhotoCarousel> createState() => _PortalPhotoCarouselState();
}

class _PortalPhotoCarouselState extends State<PortalPhotoCarousel> {
  late final _controller = PageController(viewportFraction: widget.peek);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.urls.length;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final label = widget.semanticLabel ??
        (index, total) => 'Photo ${index + 1} of $total';

    Widget photo(int i) => ClipRRect(
          borderRadius: radius,
          child: PortalNetworkImage(
            url: widget.urls[i],
            fit: BoxFit.cover,
            fallbackIcon: widget.fallbackIcon,
          ),
        );

    final body = count == 0
        ? ClipRRect(
            borderRadius: radius,
            child: PortalNetworkImage(url: null, fallbackIcon: widget.fallbackIcon),
          )
        : Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              Semantics(
                liveRegion: true,
                label: label(_page, count),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    widget.onPageChanged?.call(i);
                  },
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.peek < 1 ? 4 : 0,
                    ),
                    child: photo(i),
                  ),
                ),
              ),
              if (widget.caption case final c?)
                PositionedDirectional(start: 0, end: 0, bottom: 0, child: c),
              if (count > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DotPill(count: count, page: _page),
                ),
            ],
          );

    return SizedBox(height: widget.height, child: body);
  }
}

class _DotPill extends StatelessWidget {
  const _DotPill({required this.count, required this.page});

  final int count;
  final int page;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: portal.surface.withValues(alpha: 0.4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++) _CarouselDot(active: i == page),
            ],
          ),
        ),
      ),
    );
  }
}

/// One dot in [_DotPill] -- active dot ~3x as wide, animated.
class _CarouselDot extends StatelessWidget {
  const _CarouselDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : portal.tokens.motion.fast;
    final ink = portalOnColorFor(portal.surface);
    return AnimatedContainer(
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: active ? 1 : .5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
