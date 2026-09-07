import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_toast.dart';
import 'portal_ui_theme.dart';

/// Payload for [AppToast] / [PortalToastHost].
@immutable
class PortalToastData {
  const PortalToastData({
    required this.title,
    this.description,
    this.variant = PortalToastVariant.neutral,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  });

  final String title;
  final String? description;
  final PortalToastVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
}

DesignTokens _tokensFor(BuildContext context) {
  return PortalUiTheme.maybeOf(context)?.tokens ?? DesignTokens.defaults;
}

/// Context-free toast API. Mount [PortalToastHost] once under [Theme]
/// (typically the app root). Call [show] / [success] / [error] from anywhere,
/// including GetX controllers.
class AppToast {
  AppToast._();

  static final ValueNotifier<PortalToastData?> current =
      ValueNotifier<PortalToastData?>(null);

  static int _hostCount = 0;
  static Timer? _timer;
  static OverlayEntry? _fallbackEntry;

  static bool get hasHost => _hostCount > 0;

  static void _attachHost() => _hostCount++;

  static void _detachHost() {
    if (_hostCount > 0) _hostCount--;
  }

  static void show(
    String title, {
    String? description,
    PortalToastVariant variant = PortalToastVariant.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    present(
      PortalToastData(
        title: title,
        description: description,
        variant: variant,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
    );
  }

  static void success(
    String title, {
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      title,
      description: description,
      variant: PortalToastVariant.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    String title, {
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      title,
      description: description,
      variant: PortalToastVariant.destructive,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Toasts waiting for the current one to finish.
  ///
  /// Presenting used to replace whatever was on screen, so two messages
  /// raised together left only the second — a sync result could erase the
  /// error that explained it. They queue instead.
  static final _pending = <PortalToastData>[];

  /// Backlog ceiling. Past this the oldest waiting toast is dropped: a burst
  /// this large is a loop, and making somebody dismiss a dozen stale messages
  /// is worse than losing the middle of the burst.
  static const int maxPending = 3;

  static void present(PortalToastData data) {
    if (current.value != null) {
      // A repeat of what is already on screen or already waiting adds
      // nothing — several repositories failing the same way in one sync
      // cycle is the common case.
      if (_isDuplicate(current.value!, data)) return;
      if (_pending.any((p) => _isDuplicate(p, data))) return;
      _pending.add(data);
      if (_pending.length > maxPending) _pending.removeAt(0);
      return;
    }
    _present(data);
  }

  static void _present(PortalToastData data) {
    _fallbackEntry?.remove();
    _fallbackEntry = null;
    _timer?.cancel();
    current.value = data;
    if (data.duration > Duration.zero) {
      _timer = Timer(data.duration, dismiss);
    }
  }

  static bool _isDuplicate(PortalToastData a, PortalToastData b) =>
      a.title == b.title &&
      a.description == b.description &&
      a.variant == b.variant;

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    current.value = null;
    _fallbackEntry?.remove();
    _fallbackEntry = null;
    if (_pending.isNotEmpty) _present(_pending.removeAt(0));
  }

  /// Drop the current toast and everything waiting behind it.
  ///
  /// For a context change that makes the backlog meaningless, such as signing
  /// out. Tests use it to isolate cases.
  static void clear() {
    _pending.clear();
    dismiss();
  }
}

/// Wraps [child] with [PortalToastHost] in a top-aligned [Stack].
Widget portalWrapWithToast(Widget child) {
  return Stack(
    fit: StackFit.expand,
    children: [
      child,
      const PortalToastHost(),
    ],
  );
}

/// Renders the active [AppToast] at the top of the tree. Put this in the app
/// shell inside [Theme] so every toast uses the current color scheme.
class PortalToastHost extends StatefulWidget {
  const PortalToastHost({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  State<PortalToastHost> createState() => _PortalToastHostState();
}

class _PortalToastHostState extends State<PortalToastHost> {
  @override
  void initState() {
    super.initState();
    AppToast._attachHost();
  }

  @override
  void dispose() {
    AppToast._detachHost();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tokensFor(context);
    final padding = widget.padding ??
        EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.sm, t.spacing.lg, 0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : t.motion.fast;

    return ValueListenableBuilder<PortalToastData?>(
      valueListenable: AppToast.current,
      builder: (context, data, _) {
        return Padding(
          padding: padding,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: t.motion.standard,
            switchOutCurve: t.motion.standard,
            transitionBuilder: (child, animation) {
              if (reduceMotion) {
                return FadeTransition(opacity: animation, child: child);
              }
              final offset = Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: data == null
                ? const SizedBox(
                    key: ValueKey('portal-toast-empty'),
                    width: double.infinity,
                    height: 0,
                  )
                : SizedBox(
                    key: ValueKey(
                      '${data.variant}-${data.title}-${data.description}',
                    ),
                    width: double.infinity,
                    child: PortalToastCard(
                      data: data,
                      onDismiss: AppToast.dismiss,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Opaque toast chrome. Uses [portalToastColors] so glass themes cannot
/// wash out the fill.
class PortalToastCard extends StatelessWidget {
  const PortalToastCard({
    required this.data,
    super.key,
    this.onDismiss,
  });

  final PortalToastData data;
  final VoidCallback? onDismiss;

  IconData get _icon {
    switch (data.variant) {
      case PortalToastVariant.success:
        return Icons.check_circle_outline;
      case PortalToastVariant.destructive:
        return Icons.error_outline;
      case PortalToastVariant.neutral:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.maybeOf(context);
    final t = _tokensFor(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = portalToastColors(context, data.variant);
    final hasAction = data.actionLabel != null && data.onAction != null;
    final actionColor = portal?.primary ?? cs.primary;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radii.md),
          boxShadow: t.elevation.card(theme.brightness),
        ),
        child: Material(
          color: colors.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radii.md),
            side: BorderSide(color: colors.border, width: t.borderWidth),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: t.minTapTarget),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                t.spacing.md,
                t.spacing.sm,
                t.spacing.xs,
                t.spacing.sm,
              ),
              child: Row(
                children: [
                  Icon(_icon, size: 20, color: colors.icon),
                  SizedBox(width: t.spacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (data.description != null &&
                            data.description!.isNotEmpty) ...[
                          SizedBox(height: t.spacing.xs),
                          Text(
                            data.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.foreground.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasAction)
                    TextButton(
                      onPressed: () {
                        data.onAction!();
                        onDismiss?.call();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: actionColor,
                        minimumSize: Size(t.minTapTarget, t.minTapTarget),
                      ),
                      child: Text(data.actionLabel!),
                    ),
                  // No Tooltip here: a host mounted outside the Navigator's
                  // Overlay (the usual app-shell placement) has no Overlay
                  // ancestor, and a tooltip would assert on build. Semantics
                  // carries the label instead.
                  Semantics(
                    label: 'Dismiss',
                    button: true,
                    child: IconButton(
                      onPressed: onDismiss,
                      icon: Icon(Icons.close,
                          size: 18, color: colors.foreground),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        minimumSize: Size(t.minTapTarget, t.minTapTarget),
                        foregroundColor: colors.foreground,
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

/// Shows a themed toast. Prefers [PortalToastHost] when mounted; otherwise
/// inserts an [Overlay] entry (catalog previews, one-off screens).
void showPortalToast(
  BuildContext context,
  String message, {
  String? description,
  PortalToastVariant variant = PortalToastVariant.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final data = PortalToastData(
    title: message,
    description: description,
    variant: variant,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  if (AppToast.hasHost) {
    AppToast.present(data);
    return;
  }

  _showOverlayToast(context, data);
}

/// Legacy snack bar helper — prefer [showPortalToast] / [AppToast].
void showPortalSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  showPortalToast(
    context,
    message,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

void _showOverlayToast(BuildContext context, PortalToastData data) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    AppToast.present(data);
    return;
  }

  final theme = Theme.of(context);
  final t = _tokensFor(context);

  AppToast._fallbackEntry?.remove();
  var removed = false;
  late OverlayEntry entry;
  void removeEntry() {
    if (removed) return;
    removed = true;
    entry.remove();
    if (identical(AppToast._fallbackEntry, entry)) {
      AppToast._fallbackEntry = null;
    }
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final top = MediaQuery.paddingOf(ctx).top + t.spacing.sm;
      return Positioned(
        top: top,
        left: t.spacing.lg,
        right: t.spacing.lg,
        child: Theme(
          data: theme,
          child: PortalToastCard(
            data: data,
            onDismiss: removeEntry,
          ),
        ),
      );
    },
  );
  AppToast._fallbackEntry = entry;
  overlay.insert(entry);
  AppToast._timer?.cancel();
  AppToast._timer = Timer(data.duration, removeEntry);
}
