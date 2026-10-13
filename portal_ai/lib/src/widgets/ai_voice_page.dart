import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

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
    this.micDenied = false,
    this.onOpenSettings,
  });

  final AiVoiceSession session;
  final AiChatLabels labels;

  /// The microphone was refused: the page says so instead of showing an orb
  /// that will never hear. The session cannot know this once [AiVoiceSession.start]
  /// has returned false, so the host that saw that sets it.
  final bool micDenied;

  /// Opens the system's app settings. With none, the page only offers the way
  /// back to typing.
  final VoidCallback? onOpenSettings;

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
    final error = session.error;
    final heard = session.heard;
    final reply = session.reply;
    final phaseLabel = switch (session.phase) {
      AiVoicePhase.listening => labels.listening,
      AiVoicePhase.thinking => labels.working,
      AiVoicePhase.speaking => labels.speaking,
    };

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
            if (!widget.micDenied)
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
        body: widget.micDenied
            ? Center(
                child: PortalEmptyState(
                  icon: PortalIcons.mic_off_rounded,
                  title: labels.micDeniedTitle,
                  message: widget.onOpenSettings == null
                      ? labels.micDeniedNoSettings
                      : labels.micDeniedMessage,
                  actionLabel: widget.onOpenSettings == null
                      ? null
                      : labels.openSettings,
                  onAction: widget.onOpenSettings,
                  secondaryActionLabel: labels.close,
                  onSecondaryAction: () => Navigator.of(context).maybePop(),
                  inCard: false,
                ),
              )
            : error != null
            // The session has no retry: the message, and the way back.
            ? Center(
                child: PortalEmptyState(
                  icon: PortalIcons.cloud_off_rounded,
                  title: labels.voiceErrorTitle,
                  message: error,
                  actionLabel: labels.close,
                  onAction: () => Navigator.of(context).maybePop(),
                  inCard: false,
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AiVoiceOrb(
                          phase: session.phase,
                          level: session.level,
                          label: phaseLabel,
                          size: math.min(
                            _orbSize,
                            MediaQuery.sizeOf(context).shortestSide,
                          ),
                        ),
                      ),
                    ),
                    // A fixed third, captions on or off, so the orb never
                    // moves as they toggle or wrap.
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height / 3,
                      child: _captions && (heard.isNotEmpty || reply.isNotEmpty)
                          ? _Captions(heard: heard, reply: reply)
                          : null,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The orb's painted box. The orb itself is 0.38 of it, so this lands it near
/// the kit's 160 dp presence orb with the halo inside the box.
const double _orbSize = 420;

/// What you said (muted body) over the reply (ink title), centred at the
/// foot. While listening, your words are the caption and take the ink.
/// Long captions scroll, the newest words kept in view.
class _Captions extends StatelessWidget {
  const _Captions({required this.heard, required this.reply});

  final String heard;
  final String reply;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final cs = Theme.of(context).colorScheme;
    final big = t.textStyles.title.copyWith(color: cs.onSurface, height: 1.25);
    return SingleChildScrollView(
      reverse: true,
      padding: EdgeInsets.fromLTRB(
        t.spacing.xl,
        0,
        t.spacing.xl,
        t.spacing.xxl,
      ),
      // Not a live region: the reply is already spoken aloud.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spacing.sm,
        children: [
          if (reply.isEmpty)
            Text(heard, textAlign: TextAlign.center, style: big)
          else ...[
            if (heard.isNotEmpty)
              Text(
                heard,
                textAlign: TextAlign.center,
                style: t.textStyles.body.copyWith(color: cs.onSurfaceVariant),
              ),
            Text(reply, textAlign: TextAlign.center, style: big),
          ],
        ],
      ),
    );
  }
}
