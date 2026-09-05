import 'package:flutter/material.dart';

/// The box you type the question into.
///
/// One widget for both shapes portal had: the assistant page's plain field
/// with a send arrow, and portal_task's landing composer with a character
/// count, an attach button and a labelled generate button. Passing
/// [submitLabel] picks the second; leaving it null picks the first.
///
/// The attach button is always drawn when [onAttach] is set, rather than
/// swapping places with submit once you have typed three characters the way
/// portal_task's did -- a button that vanishes mid-sentence is a button you
/// have to delete text to reach.
class AiPromptComposer extends StatelessWidget {
  const AiPromptComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.enabled = true,
    this.busy = false,
    this.onStop,
    this.onAttach,
    this.maxLength,
    this.hintText = '',
    this.submitLabel,
    this.minChars = 1,
    this.stopLabel = 'Stop',
    this.attachLabel = 'Attach a photo',
    this.bordered = false,
  });

  final TextEditingController controller;

  /// Called by the button and by the keyboard's send action.
  final VoidCallback onSubmit;

  /// False while a consent gate is unanswered, or the backend is missing.
  final bool enabled;

  /// A run is in flight: the field locks and the button becomes a stop ring.
  final bool busy;

  /// Cancels the run in flight. Null leaves a plain spinner.
  final VoidCallback? onStop;

  /// Adds an attachment button to the footer. Null draws none.
  final VoidCallback? onAttach;

  /// Caps the field and shows `n/max` in the footer.
  final int? maxLength;

  final String hintText;

  /// Draws submit as a labelled filled button instead of an arrow.
  final String? submitLabel;

  /// How much has to be typed before submit lights up.
  final int minChars;

  final String stopLabel;
  final String attachLabel;

  /// Wraps the field in the accent-bordered card portal_task's landing uses.
  /// The assistant page's own outlined field is the default.
  final bool bordered;

  bool get _canSubmit =>
      enabled && !busy && controller.text.trim().length >= minChars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showFooter =
        maxLength != null || onAttach != null || submitLabel != null;

    // The field itself is built once and left alone. Rebuilding it on every
    // keystroke -- which is what wrapping it in a ListenableBuilder did --
    // drops the platform text-input connection, so a keyboard send action
    // lands on nothing. Only the parts that read the text rebuild.
    final field = TextField(
      controller: controller,
      enabled: enabled,
      // Read-only rather than disabled while a run is in flight: a disabled
      // field disables its own suffix, which is where the stop button lives,
      // so the only way to cancel was unclickable.
      readOnly: busy,
      minLines: bordered ? 2 : 1,
      maxLines: 4,
      maxLength: maxLength,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) {
        if (_canSubmit) onSubmit();
      },
      // The count belongs in the footer next to the buttons, not floating
      // under the field on its own line.
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        hintText: hintText,
        border: bordered ? InputBorder.none : const OutlineInputBorder(),
        isDense: bordered,
        // With a footer there is a submit button down there already.
        suffixIcon: showFooter ? null : _live(_submitButton),
      ),
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        if (showFooter)
          Row(
            children: [
              if (maxLength case final max?)
                _live(
                  (context) => Text(
                    '${controller.text.characters.length}/$max',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const Spacer(),
              if (onAttach case final attach?)
                IconButton(
                  tooltip: attachLabel,
                  onPressed: enabled && !busy ? attach : null,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  visualDensity: VisualDensity.compact,
                ),
              _live(_submitButton),
            ],
          ),
      ],
    );

    if (!bordered) return column;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: column,
    );
  }

  /// Rebuilds one small thing whenever what is typed changes.
  Widget _live(Widget Function(BuildContext) build) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => build(context),
      );

  Widget _submitButton(BuildContext context) {
    final canSubmit = _canSubmit;
    if (busy) {
      // One spinner, and it is also the stop button: the ring shows the run is
      // live, tapping it cancels.
      return IconButton(
        tooltip: stopLabel,
        onPressed: onStop,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              Icon(Icons.stop_rounded, size: 12),
            ],
          ),
        ),
      );
    }
    if (submitLabel case final label?) {
      return FilledButton.icon(
        onPressed: canSubmit ? onSubmit : null,
        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
        label: Text(label),
      );
    }
    return IconButton(
      icon: const Icon(Icons.arrow_upward),
      onPressed: canSubmit ? onSubmit : null,
    );
  }
}
