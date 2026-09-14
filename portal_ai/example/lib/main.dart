import 'package:flutter/material.dart';
import 'package:portal_ai/portal_ai.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// The assistant page driven by a canned conversation instead of a model:
/// `onSend` appends the prompt and a scripted reply. Shows the markdown
/// renderer, thinking tile, suggestion cards and proposals without a backend.
void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'portal_ai',
      debugShowCheckedModeBanner: false,
      theme: buildPortalTheme(brightness: Brightness.light),
      darkTheme: buildPortalTheme(brightness: Brightness.dark),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _turns = <AiChatTurn>[
    const AiChatTurn(role: 'user', content: 'How did my week go?'),
    const AiChatTurn(
      role: 'assistant',
      content: '''
**Solid week.** Four sessions, two of them strength.

| day | session | volume |
|---|---|---|
| Mon | Push | 6.2 t |
| Wed | Pull | 5.8 t |
| Fri | Legs | 9.1 t |
| Sun | Run | 8 km |

Bench moved from 80 → 82.5 kg. Want me to bump next week's plan?''',
      payload: {
        'thinking':
            'Pull the last 7 days of workouts, group by type, compare top '
            'sets against the previous block, flag any PRs.',
      },
      took: Duration(milliseconds: 1840),
    ),
  ];

  final _proposals = <AiProposal>[
    const AiProposal(
      id: 'p1',
      title: 'Bench press → 85 kg × 5',
      subtitle: 'Next Monday, Push',
      badge: '+2.5 kg',
    ),
  ];

  Future<void> _send(String prompt) async {
    setState(() => _turns.add(AiChatTurn(role: 'user', content: prompt)));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(
      () => _turns.add(
        AiChatTurn(
          role: 'assistant',
          content:
              'Canned reply to _"$prompt"_ — wire a `PortalAiRuntime` '
              'to get a real one.',
          took: const Duration(milliseconds: 900),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AiAssistantPage(
          title: 'Gym assistant',
          fill: true,
          turns: _turns,
          onSend: _send,
          proposals: _proposals,
          onAcceptProposal: (p) => setState(() => _proposals.remove(p)),
          onDiscardProposal: (p) => setState(() => _proposals.remove(p)),
          suggestions: const [
            AiSuggestion(prompt: 'Plan a 30 minute upper body session'),
            AiSuggestion(prompt: 'What was my best deadlift this month?'),
            AiSuggestion(prompt: 'Am I overtraining?'),
          ],
        ),
      ),
    );
  }
}
