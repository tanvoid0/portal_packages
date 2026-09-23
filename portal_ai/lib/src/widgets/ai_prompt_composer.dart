import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// The box you type the question into.
///
/// One widget for both shapes portal had: the assistant page's plain field
/// with a send arrow, and portal_task's landing composer with a character
/// count, an attach button and a labelled generate button. Passing
/// [submitLabel] picks the second; leaving it null picks the first. Both
/// shapes render through [PortalComposer] -- [bordered] just picks its
/// [PortalComposerVariant.docked] over [PortalComposerVariant.floating].
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
    this.focusNode,
    this.enabled = true,
    this.busy = false,
    this.onStop,
    this.onAttach,
    this.onMic,
    this.listening = false,
    this.maxLength,
    this.hintText = '',
    this.submitLabel,
    this.minChars = 1,
    this.sendLabel = 'Send',
    this.stopLabel = 'Stop',
    this.attachLabel = 'Attach a photo',
    this.micLabel = 'Speak',
    this.micStopLabel = 'Stop listening',
    this.bordered = false,
  });

  final TextEditingController controller;

  /// Kept by the page so focus (and the keyboard with it) survives a send.
  final FocusNode? focusNode;

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

  /// Toggles a voice conversation. Null draws no microphone -- the page
  /// leaves it null unless the device can hear and speak on its own.
  final VoidCallback? onMic;

  /// The voice conversation is on: the microphone draws selected.
  final bool listening;

  /// A hard cap, enforced by the field, plus an `n/max` count beside the
  /// field's own controls.
  final int? maxLength;

  final String hintText;

  /// Draws submit's tooltip from this instead of [sendLabel]. `PortalComposer`
  /// has no labelled-button slot, so this no longer swaps the arrow for a
  /// `FilledButton` the way it used to -- it only renames what a screen
  /// reader hears.
  final String? submitLabel;

  /// How much text send needs before it lights up. 1 is "not empty".
  final int minChars;

  final String sendLabel;
  final String stopLabel;
  final String attachLabel;
  final String micLabel;
  final String micStopLabel;

  /// Wraps the field in the accent-bordered card portal_task's landing uses.
  /// The assistant page's own outlined field is the default.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return PortalComposer(
      controller: controller,
      onSubmit: onSubmit,
      focusNode: focusNode,
      hintText: hintText,
      enabled: enabled,
      busy: busy,
      onStop: onStop,
      variant: bordered
          ? PortalComposerVariant.docked
          : PortalComposerVariant.floating,
      sendLabel: submitLabel ?? sendLabel,
      stopLabel: stopLabel,
      maxLength: maxLength,
      minChars: minChars,
      leading: [
        // Attach sits on the leading edge, the way every assistant puts it:
        // it acts on what you are about to write, while mic and send act on
        // what is written.
        if (onAttach case final attach?) _attachButton(attach),
      ],
      trailing: [
        if (onMic != null) _micButton(),
        // A cap you cannot see is a cap that truncates you by surprise --
        // one muted count beside the buttons, only when there is a cap.
        if (maxLength case final max?) _counter(max),
      ],
    );
  }

  /// A paperclip, not a photo frame: this button takes a PDF or a text file
  /// as readily as an image, and an icon that promises pictures is an icon
  /// that hides the feature from anyone holding a document.
  Widget _attachButton(VoidCallback attach) => IconButton(
    tooltip: attachLabel,
    onPressed: enabled && !busy ? attach : null,
    icon: const Icon(Icons.attach_file_rounded),
    visualDensity: VisualDensity.compact,
  );

  /// Selected while the conversation is on, so a screen reader hears the
  /// state and not just the icon.
  Widget _micButton() => IconButton(
    tooltip: listening ? micStopLabel : micLabel,
    onPressed: enabled && !busy ? onMic : null,
    isSelected: listening,
    icon: Icon(listening ? Icons.mic : Icons.mic_none_rounded),
    visualDensity: VisualDensity.compact,
  );

  Widget _counter(int max) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Text(
      '${controller.text.characters.length}/$max',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
