import 'package:flutter/material.dart';

import '../theme/portal_ui_theme.dart';

enum PortalResultState { success, error, pending }

/// A whole page that reports how something ended: success, error or pending.
///
/// The art slot (G8's per-app spot) and the title and body are centred in the
/// space above the [dock], which is never left as dead space. An error leads
/// with the fix, then offers retry in the dock. The page keeps only a Close
/// ([onClose]); its headline is the template's title, so there is no app-bar
/// title. A whole page failing is this, not a [PortalPrompt].
class PortalResultScreen extends StatelessWidget {
  const PortalResultScreen({
    super.key,
    required this.state,
    required this.title,
    required this.body,
    this.art,
    this.dock,
    this.onClose,
  });

  final PortalResultState state;
  final String title;
  final String body;

  /// The app's illustration for this state (G8), or an icon.
  final Widget? art;

  /// A `PortalButtonDock`: a primary (Done, Retry) and an optional secondary.
  final Widget? dock;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final tokens = portal.tokens;
    final cs = Theme.of(context).colorScheme;
    final styles = tokens.textStyles;

    return Scaffold(
      backgroundColor: portal.surface,
      appBar: onClose == null
          ? null
          : AppBar(
              backgroundColor: portal.surface,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
              ),
            ),
      bottomNavigationBar: dock,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.layout.pageHorizontal,
                    vertical: tokens.spacing.xl,
                  ),
                  child: Semantics(
                    container: true,
                    // A failure is announced when it appears; success and
                    // pending are read in order.
                    liveRegion: state == PortalResultState.error,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (art != null) ...[
                          ExcludeSemantics(child: art!),
                          SizedBox(height: tokens.spacing.xl),
                        ],
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: styles.headline.copyWith(color: cs.onSurface),
                          ),
                        ),
                        SizedBox(height: tokens.spacing.sm),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: styles.body.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
