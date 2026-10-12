import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The fulfillment target for a `portal-<app>://ai` deep link / App Actions
/// shortcut: three apps (gym, journey, recipe) hand-built this identically.
///
/// A deep link arrives through `Get.offAllNamed`, so there is no stack under
/// this route — the shared [PopScope] sends the system back gesture to
/// [fallbackRoute] instead of letting it close the app.
///
/// [questionFrom] composes one sentence from whatever App Actions slots
/// Assistant filled (each app's own `xAiQuestionFrom`); when it returns
/// non-null that sentence auto-sends. A bare `?q=` is always pre-filled but
/// never auto-sent — it carries arbitrary text from whatever fired the
/// intent, and auto-sending it would let any installed app run tools against
/// the account. Pass `null` for an app with no App Actions slots of its own
/// (journey): only the `?q=` behaviour applies.
///
/// Left to the app, not folded in here: anything built from [Get.arguments]
/// beyond a question (shopping's speech-to-text listening flow is real
/// per-app divergence, not this shape).
class PortalDeepLinkAssistantView extends StatefulWidget {
  const PortalDeepLinkAssistantView({
    super.key,
    required this.fallbackRoute,
    required this.assistantPage,
    this.questionFrom,
  });

  /// Route the system back gesture lands on.
  final String fallbackRoute;

  /// Builds the embedded assistant page body (each app's `xAssistantPage`).
  final Widget Function({String? initialPrompt, bool autoSend}) assistantPage;

  /// Composes one sentence from the deep link's arguments, or null for none.
  final String? Function(Map<String, String> args)? questionFrom;

  @override
  State<PortalDeepLinkAssistantView> createState() =>
      _PortalDeepLinkAssistantViewState();
}

class _PortalDeepLinkAssistantViewState
    extends State<PortalDeepLinkAssistantView> {
  /// Read in the State, not in a controller's `onInit`: the controller is
  /// lazily put and survives a warm relaunch, so `onInit` runs once ever and
  /// the second voice command would arrive to nobody listening. A route
  /// always builds a fresh State.
  late final Map<String, String> _args = switch (Get.arguments) {
    final Map<Object?, Object?> m => m.map((k, v) => MapEntry('$k', '$v')),
    _ => const <String, String>{},
  };

  String? _prompt;
  bool _autoSend = false;

  @override
  void initState() {
    super.initState();
    final composed = widget.questionFrom?.call(_args);
    if (composed != null) {
      _prompt = composed;
      _autoSend = true;
      return;
    }
    final q = _args['q']?.trim();
    if (q != null && q.isNotEmpty) _prompt = q;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.offAllNamed(widget.fallbackRoute);
      },
      child: Scaffold(
        body: SafeArea(
          child: widget.assistantPage(
            initialPrompt: _prompt,
            autoSend: _autoSend,
          ),
        ),
      ),
    );
  }
}
