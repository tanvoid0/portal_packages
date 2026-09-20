import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../motion/portal_haptics.dart';
import '../theme/portal_surface_treatment.dart';
import '../theme/portal_ui_theme.dart';
import '../tokens/portal_radii_utils.dart';
import 'portal_app_bar.dart';
import 'portal_bottom_nav_bar.dart';
import 'portal_pressable.dart';
import 'portal_scroll_page.dart';

/// The fleet's floating action button: the theme's `floatingActionButtonTheme`
/// (colour, corner) drawn through [PortalPressable], so it shrinks under the
/// finger and springs back like every other Portal control, with one
/// `PortalHaptics.medium()` on tap. Flat by decision, like the toolbar and
/// the glass header: `floatingActionButtonTheme.elevation` is ignored, since
/// a shadow that scales with the press can only be painted inside
/// [PortalPressable]'s own `Material`. Apps drop their FAB `elevation:`.
///
/// [PortalFab.extended] carries a label and **collapses to the icon while the
/// page scrolls down**, re-extending on a scroll up or on reaching the top by
/// any route (drag, `animateTo`, `jumpTo`). It follows [scrollController], or
/// the route's [PrimaryScrollController] — which a [PortalScrollPage] body
/// attaches to on Android and iOS, so inside a `PortalScrollPage` it needs no
/// wiring there; desktop targets pass [scrollController].
///
/// Icon-only, so [tooltip] is required; the extended form takes its label as
/// the tooltip once collapsed. No `Hero`: with B2's shared-axis route
/// transition a FAB flight is noise, and two FABs on one screen no longer
/// collide on a tag. Wrap in `PortalHero` for the one page that wants it.
class PortalFab extends StatefulWidget {
  const PortalFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  })  : label = null,
        scrollController = null;

  const PortalFab.extended({
    super.key,
    required this.icon,
    required String this.label,
    required this.onPressed,
    this.tooltip,
    this.scrollController,
  });

  final IconData icon;

  /// Extended form only. Shown beside the icon until the page scrolls down.
  final String? label;

  /// What the button does, for the long-press bubble and the screen reader.
  /// Optional on the extended form, where it defaults to [label].
  final String? tooltip;

  final VoidCallback? onPressed;

  /// The scroll the label follows. Null reads the route's
  /// [PrimaryScrollController].
  final ScrollController? scrollController;

  /// M3's FAB container: 56 dp, and the collapsed extended width.
  static const double size = 56;

  @override
  State<PortalFab> createState() => _PortalFabState();
}

class _PortalFabState extends State<PortalFab> {
  ScrollController? _controller;
  bool _collapsed = false;

  /// Offset per attached position at the last event, so a programmatic move
  /// can be told from the parked tabs of an IndexedStack shell — every tab
  /// attaches to the route's one primary controller.
  var _pixels = <ScrollPosition, double>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  @override
  void didUpdateWidget(PortalFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attach();
  }

  void _attach() {
    final next = widget.label == null
        ? null
        : widget.scrollController ?? PrimaryScrollController.maybeOf(context);
    if (identical(next, _controller)) return;
    _controller?.removeListener(_onScroll);
    _controller = next?..addListener(_onScroll);
  }

  void _onScroll() {
    var collapsed = _collapsed;
    final seen = <ScrollPosition, double>{};
    for (final p in _controller!.positions) {
      final last = _pixels[p];
      seen[p] = p.pixels;
      if (p.userScrollDirection != ScrollDirection.idle) {
        // Under the finger: down collapses, up re-extends.
        collapsed = p.userScrollDirection == ScrollDirection.reverse &&
            p.pixels > p.minScrollExtent;
      } else if (last != null &&
          last != p.pixels &&
          p.pixels <= p.minScrollExtent) {
        // No finger, yet it moved: animateTo/jumpTo (tab re-tap, refresh
        // reset). Reaching the top re-extends; a parked tab never moves.
        collapsed = false;
      }
    }
    _pixels = seen;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final theme = Theme.of(context);
    final fab = theme.floatingActionButtonTheme;
    final cs = theme.colorScheme;
    final background = fab.backgroundColor ?? cs.primaryContainer;
    final foreground = fab.foregroundColor ?? cs.onPrimaryContainer;
    // One radius drives the fill and the splash clip so they never disagree;
    // a theme shape that is not a rounded rect falls back to the token.
    final radius = switch (fab.shape) {
      RoundedRectangleBorder(:final borderRadius) =>
        borderRadius.resolve(Directionality.of(context)),
      _ => tokens.radii.circular(),
    };
    final extended = widget.label != null && !_collapsed;

    return Tooltip(
      message: widget.tooltip ?? widget.label!,
      // The visible label already names it; saying it twice helps no one.
      excludeFromSemantics: extended && widget.tooltip == null,
      child: PortalPressable(
        onTap: widget.onPressed,
        haptic: PortalHapticKind.medium,
        ripple: true,
        borderRadius: radius,
        splashColor: foreground.withValues(alpha: 0.12),
        highlightColor: foreground.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(color: background, borderRadius: radius),
          child: IconTheme.merge(
            // Pinned like Material's FAB: the ambient icon theme is 22 under
            // applyPortalComponentThemes, and lg either side of a 24 icon is
            // what makes the collapsed box exactly [size] wide.
            data: IconThemeData(color: foreground, size: 24),
            child: DefaultTextStyle.merge(
              style: (fab.extendedTextStyle ?? theme.textTheme.labelLarge!)
                  .copyWith(color: foreground),
              child: AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : tokens.motion.medium,
                curve: tokens.motion.standard,
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  height: PortalFab.size,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon),
                        if (extended) ...[
                          SizedBox(
                            width: fab.extendedIconLabelSpacing ??
                                tokens.spacing.sm,
                          ),
                          Text(widget.label!),
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
    );
  }
}

/// M3 Expressive's floating toolbar: a glass pill of icon actions that hovers
/// over the page, above the floating nav. Each [PortalAction] is a
/// [PortalActionButton] — the same tooltip-and-badge icon button the app bar
/// draws — so an action reads alike wherever it sits.
///
/// Glass on every visual theme, like the collapsed [PortalHeader]: the
/// navigation layer is the one place glass belongs, so nothing inside the
/// pill (or under it in a sheet) should be glass again. No shadow — a blurred
/// tint over a shadow's fill just reads as a darker pill; the hairline is
/// the edge, as on the header.
///
/// Put it in `Scaffold.floatingActionButton` with
/// `floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat`.
/// [clearance] is the space kept under the pill for a nav bar that floats
/// over the body — [PortalBottomNavBar.overlayClearance] by default; pass 0
/// when the same `Scaffold` owns the nav in `bottomNavigationBar` and already
/// lifts the slot above it.
class PortalToolbar extends StatelessWidget {
  const PortalToolbar({
    super.key,
    required this.actions,
    this.clearance = PortalBottomNavBar.overlayClearance,
  });

  final List<PortalAction> actions;

  /// Bottom padding under the pill. See the class doc.
  final double clearance;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final glass = portal.glassStyle ??
        PortalGlassStyle.forBrightness(Theme.of(context).brightness);
    final radius = tokens.radii.circular(tokens.radii.full);

    return Padding(
      padding: EdgeInsets.only(bottom: clearance),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass.blurSigma,
            sigmaY: glass.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: portal.card.withValues(alpha: glass.tintAlpha),
              borderRadius: radius,
              border: Border.fromBorderSide(portal.borderSide()),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final a in actions) PortalActionButton(action: a),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
