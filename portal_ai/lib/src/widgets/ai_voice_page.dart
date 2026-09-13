import 'package:flutter/material.dart';

import '../chat/ai_voice_session.dart';
import 'ai_chat_labels.dart';
import 'ai_voice_orb.dart';

/// The voice conversation, full screen: the orb, what it is doing, and a
/// caption of what was heard or what is being said. Closes itself when the
/// session ends on its own (an error); the close button ends it by hand.
///
/// Captions are optional -- some people want the words, some find them a
/// distraction from listening -- and the choice lives only for this page.
class AiVoicePage extends StatefulWidget {
  const AiVoicePage({
    super.key,
    required this.session,
    required this.labels,
  });

  final AiVoiceSession session;
  final AiChatLabels labels;

  @override
  State<AiVoicePage> createState() => _AiVoicePageState();
}

class _AiVoicePageState extends State<AiVoicePage> {
  bool _captions = true;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_changed);
  }

  @override
  void dispose() {
    widget.session.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (!widget.session.active) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final labels = widget.labels;
    final theme = Theme.of(context);
    final phaseLabel = switch (session.phase) {
      AiVoicePhase.listening => labels.listening,
      AiVoicePhase.thinking => labels.working,
      AiVoicePhase.speaking => labels.speaking,
    };
    // While listening the caption is the question taking shape; once the
    // reply starts it is the reply. Between the two, the question stays.
    final caption = session.reply.isNotEmpty ? session.reply : session.heard;

    return PopScope(
      onPopInvokedWithResult: (_, _) => session.stop(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: labels.close,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              tooltip: _captions ? labels.captionsOff : labels.captionsOn,
              isSelected: _captions,
              icon: Icon(
                _captions
                    ? Icons.closed_caption
                    : Icons.closed_caption_disabled_outlined,
              ),
              onPressed: () => setState(() => _captions = !_captions),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AiVoiceOrb(
                    phase: session.phase,
                    level: session.level,
                    label: phaseLabel,
                  ),
                ),
              ),
              if (_captions)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    // Reversed so a long reply shows its newest words and the
                    // reader scrolls back for the rest.
                    child: ListView(
                      reverse: true,
                      shrinkWrap: true,
                      children: [
                        Text(
                          session.error ?? caption,
                          textAlign: TextAlign.center,
                          style: session.error != null
                              ? theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.error,
                                )
                              : theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
