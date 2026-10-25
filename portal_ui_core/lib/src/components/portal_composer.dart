import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/portal_ui_theme.dart';
import '../theme/portal_theme_helpers.dart';

/// The shape of a [PortalComposer]'s dock.
enum PortalComposerVariant {
  /// A pill floating on the page, filled and unbordered -- the assistant
  /// page's own field.
  floating,

  /// A bordered card the field sits inside, with leading/trailing and the
  /// send button on a footer row below it -- portal_task's landing composer.
  docked,
}

/// The box you type into. Presentational only -- no chat logic, no request
/// handling; the caller owns the controller and what happens on submit.
///
/// The field itself is built once and never rebuilt on keystroke: only the
/// send button (and anything else reading [controller]'s text) rebuilds
/// through a [ListenableBuilder]. Rebuilding the field on every character --
/// what wrapping the whole widget in one would do -- drops the platform text
/// input connection, so the keyboard's own send action lands on nothing.
class PortalComposer extends StatelessWidget {
  const PortalComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.hintText = '',
    this.enabled = true,
    this.busy = false,
    this.onStop,
    this.leading = const [],
    this.trailing = const [],
    this.above,
    this.variant = PortalComposerVariant.floating,
    this.sendLabel = 'Send',
    this.stopLabel = 'Stop',
    this.maxLength,
    this.minChars = 1,
  });

  final TextEditingController controller;

  /// Fired by the send button and by the keyboard's send action. Never
  /// fired with empty text or while [enabled] is false -- callers do not
  /// need to guard against either.
  final VoidCallback onSubmit;
  final FocusNode? focusNode;
  final String hintText;

  /// False while a consent gate is unanswered, or the backend is missing.
  final bool enabled;

  /// A run is in flight: the field goes read-only and the send button
  /// becomes a stop ring.
  final bool busy;

  /// Cancels the run in flight. Null while busy leaves a plain spinner with
  /// no stop action.
  final VoidCallback? onStop;

  /// Buttons before the field's own controls -- an attach button, most
  /// often. Built and enabled by the caller; the dock only lays them out.
  final List<Widget> leading;

  /// Buttons after the field's own controls -- a mic toggle, most often.
  final List<Widget> trailing;

  /// Slot above the field: an attachment strip, a reply-to banner.
  final Widget? above;
  final PortalComposerVariant variant;
  final String sendLabel;
  final String stopLabel;

  /// A hard cap on what can be typed, enforced by the field itself. Flutter's
  /// own counter is suppressed -- a dock this small has nowhere to put it, and
  /// a caller that wants one renders it into [trailing] where it can be
  /// styled like the rest of the row.
  final int? maxLength;

  /// How much text the send button needs before it lights up. The default of
  /// 1 is "not empty"; a caller that wants a real prompt rather than a
  /// keystroke raises it.
  final int minChars;

  bool get _canSubmit =>
      enabled && !busy && controller.text.trim().length >= minChars;

  void _submit() {
    if (_canSubmit) onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final docked = variant == PortalComposerVariant.docked;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: busy,
      minLines: docked ? 2 : 1,
      maxLines: docked ? 4 : 6,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _submit(),
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        hintText: hintText,
        filled: !docked,
        fillColor:
            docked ? null : portalOffPage(context, scheme.surfaceContainerHigh),
        border: docked
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radii.full),
                borderSide: BorderSide.none,
              ),
        contentPadding: docked
            ? null
            : EdgeInsets.symmetric(
                horizontal: tokens.spacing.xl,
                vertical: tokens.spacing.md,
              ),
        isDense: docked,
        prefixIcon: docked || leading.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: leading),
        suffixIcon: docked
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [...trailing, _live(_sendButton)],
              ),
      ),
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (above case final slot?) slot,
        field,
        if (docked)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.xs),
            child: Row(
              children: [
                ...leading,
                const Spacer(),
                ...trailing,
                _live(_sendButton),
              ],
            ),
          ),
      ],
    );

    if (!docked) return column;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radii.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.lg,
          tokens.spacing.md,
          tokens.spacing.sm,
          tokens.spacing.xs,
        ),
        child: column,
      ),
    );
  }

  Widget _live(Widget Function(BuildContext) builder) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => builder(context),
      );

  Widget _sendButton(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final target = tokens.minTapTarget;
    final circle = tokens.avatarSizes.sm * 0.7;

    if (busy) {
      return _circleButton(
        tooltip: stopLabel,
        target: target,
        onTap: onStop,
        child: SizedBox.square(
          dimension: circle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              Icon(
                Icons.stop_rounded,
                size: tokens.typeScale.md,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    final canSubmit = _canSubmit;
    return _circleButton(
      tooltip: sendLabel,
      target: target,
      onTap: canSubmit ? _submit : null,
      child: AnimatedContainer(
        duration: tokens.motion.fast,
        width: circle,
        height: circle,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: canSubmit ? scheme.primary : scheme.surfaceContainerHighest,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_upward_rounded,
          size: tokens.typeScale.xl,
          color: canSubmit ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _circleButton({
    required String tooltip,
    required double target,
    required VoidCallback? onTap,
    required Widget child,
  }) =>
      Tooltip(
        message: tooltip,
        child: SizedBox(
          width: target,
          height: target,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(child: child),
            ),
          ),
        ),
      );
}
