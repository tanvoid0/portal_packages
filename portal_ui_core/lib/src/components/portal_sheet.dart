import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

/// The fleet's modal bottom sheet: `showModalBottomSheet` with the Portal
/// defaults filled in once instead of at 36 call sites.
///
/// Surface, corner radius and grabber styling come from the theme's
/// `bottomSheetTheme` (B4). The sheet avoids the status bar, lifts for the
/// keyboard, keeps its content clear of the bottom inset, and slides on the
/// spatial spring at `tokens.motion.medium` (its 1.5% overshoot lifts the
/// bottom edge a few px off the screen for a couple of frames — the price of
/// the spring the spec asks for). Reduce-motion skips the animation.
///
/// ```dart
/// final picked = await PortalSheet.show<Unit>(
///   context,
///   builder: (_) => PortalSheetScaffold(
///     title: 'Units',
///     body: UnitList(onPick: (u) => Navigator.pop(context, u)),
///     scrollable: false, // UnitList is a ListView
///   ),
/// );
/// ```
abstract final class PortalSheet {
  /// Opens a sheet and resolves to what it was popped with, or null when it
  /// was dismissed.
  ///
  /// [title] wraps [builder]'s widget in a [PortalSheetScaffold]: a
  /// `ScrollView` body (`ListView`, `GridView`, …) fills the height and
  /// scrolls itself, anything else scrolls in a `SingleChildScrollView` —
  /// so a custom widget that scrolls internally builds the scaffold itself
  /// with `scrollable: false` instead of passing [title] here. Not both.
  ///
  /// [isScrollControlled] (default true) lets the sheet take the full height;
  /// a `mainAxisSize: min` body stays short, and the keyboard lifts the sheet
  /// rather than squashing it. False caps it at 9/16 of the screen.
  ///
  /// [isDismissible] false blocks the barrier, drag and back — and hides the
  /// grabber, since Material gives the handle its own drag-to-close.
  ///
  /// [detents] are the heights the sheet rests at as fractions of the height
  /// below the status bar, grabber and keyboard, ascending (`[0.45, 0.9]`):
  /// it opens at the first, drags between them and snaps to the nearest. The
  /// smallest detent rests rather than closes — dismissal is the grabber, the
  /// barrier or back — and the body scrolls on the sheet's own controller,
  /// which [PortalSheetScaffold] picks up through `PrimaryScrollController`.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    List<double>? detents,
    bool isScrollControlled = true,
    bool showGrabber = true,
    bool isDismissible = true,
  }) {
    assert(detents == null || detents.isNotEmpty, 'detents must not be empty');
    final motion = PortalUiTheme.of(context).tokens.motion;
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: showGrabber && isDismissible,
      useSafeArea: true,
      isScrollControlled: isScrollControlled || detents != null,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              curve: motion.emphasized,
              duration: motion.medium,
              reverseCurve: motion.standard.flipped,
              reverseDuration: motion.medium,
            ),
      builder: (ctx) {
        final body = builder(ctx);
        final content = title == null
            ? body
            : PortalSheetScaffold(
                title: title,
                body: body,
                scrollable: body is! ScrollView,
              );
        Widget child = content;
        if (detents != null) {
          child = DraggableScrollableSheet(
            expand: false,
            snap: true,
            initialChildSize: detents.first,
            minChildSize: detents.first,
            maxChildSize: detents.last,
            snapSizes: detents,
            shouldCloseOnMinExtent: false,
            builder: (_, controller) => PrimaryScrollController(
              controller: controller,
              child: content,
            ),
          );
        }
        // useSafeArea only clears the top; the bottom inset and the keyboard
        // are the content's to avoid so the surface still runs under them.
        // Outside the detents sheet so its fractions are of the space left.
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Title, scrolling body and a pinned action row — the shape most sheets
/// in the fleet hand-build.
///
/// The body scrolls inside the sheet's height; pass [scrollable] false when
/// it is a `ListView` or another scrollable of its own (it will fill the
/// remaining height). Title, body and actions share the page gutter.
/// [actions] sit in one row, each stretched equally, above a hairline.
class PortalSheetScaffold extends StatelessWidget {
  PortalSheetScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions = const [],
    this.scrollable = true,
    this.onClose,
    this.trailing = const [],
    this.message,
    this.dock,
    this.gutter = true,
  }) : assert(actions.isEmpty || dock == null,
            'a sheet has one footer: pass actions or dock, not both');

  final Widget body;
  final String? title;

  /// Pinned under the body; typically one or two `PortalButton`s. Mutually
  /// exclusive with [dock].
  final List<Widget> actions;

  /// A footer bar (a `PortalButtonDock`) in place of [actions] — stacked,
  /// not inset in the body's gutter.
  final Widget? dock;

  /// Wrap [body] in a `SingleChildScrollView`. Off for a body that scrolls
  /// itself.
  final bool scrollable;

  /// Shows a close button at the title row's end. Defaults to popping the
  /// route; given explicitly it replaces that.
  final VoidCallback? onClose;

  /// Non-close widgets at the title row's end, before the close button.
  final List<Widget> trailing;

  /// Why the sheet asks, under the title: muted, read again when it changes.
  final String? message;

  /// False drops the page gutter around [body] — for a body that brings its
  /// own (a full-bleed [PortalListSection]).
  final bool gutter;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final pad = EdgeInsets.symmetric(horizontal: tokens.layout.pageHorizontal);
    final gutterPad = gutter ? pad : EdgeInsets.zero;
    final hasBar = title != null || trailing.isNotEmpty || onClose != null;

    Widget content = Padding(padding: gutterPad, child: body);
    if (scrollable) {
      content = SingleChildScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        child: content,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasBar)
          Padding(
            padding: pad.copyWith(
              top: tokens.spacing.sm,
              bottom: tokens.spacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: title == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          header: true,
                          child: Text(title!, style: tokens.textStyles.title),
                        ),
                ),
                ...trailing,
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
        if (message case final m?)
          Padding(
            padding: pad.copyWith(bottom: tokens.spacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(m,
                  style: tokens.textStyles.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ),
        Flexible(child: content),
        if (dock != null)
          dock!
        else if (actions.isNotEmpty) ...[
          SizedBox(height: tokens.spacing.md),
          Divider(height: tokens.borderWidth),
          Padding(
            padding: pad.copyWith(top: tokens.spacing.md),
            child: Row(
              spacing: tokens.spacing.sm,
              children: [for (final a in actions) Expanded(child: a)],
            ),
          ),
        ],
        if (dock == null) SizedBox(height: tokens.spacing.lg),
      ],
    );
  }
}
