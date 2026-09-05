import 'package:flutter/material.dart';

/// The "here is what leaves your device" gate shown before the first prompt.
///
/// State and persistence stay with the host: portal_task writes a pref and
/// mirrors it to the server, an offline-only app might never show this at all.
/// The package only knows whether to draw the card.
class AiConsent {
  const AiConsent({
    required this.accepted,
    required this.onAccept,
    this.title = 'Before we start',
    this.body =
        'Your prompt is sent to the AI model to generate a reply. '
        'Nothing else leaves this device unless you say so.',
    this.acceptLabel = 'Accept and continue',
    this.footnote = '',
    this.points = const [],
  });

  final bool accepted;
  final VoidCallback onAccept;

  final String title;
  final String body;
  final String acceptLabel;

  /// Small print under the button. Empty draws nothing.
  final String footnote;

  /// What is actually sent, as labelled tiles. Empty draws nothing -- an app
  /// with a one-line story should not be forced into a grid.
  final List<AiConsentPoint> points;
}

/// One item of data the assistant will send, named and iconed.
class AiConsentPoint {
  const AiConsentPoint({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// The gate itself. Shown in place of the empty state until accepted.
class AiConsentCard extends StatelessWidget {
  const AiConsentCard({super.key, required this.consent});

  final AiConsent consent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: scheme.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            consent.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            consent.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (consent.points.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (final point in consent.points)
                  Expanded(child: _PointTile(point: point)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: consent.onAccept,
              child: Text(consent.acceptLabel),
            ),
          ),
          if (consent.footnote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              consent.footnote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({required this.point});

  final AiConsentPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(point.icon, color: scheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            point.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
