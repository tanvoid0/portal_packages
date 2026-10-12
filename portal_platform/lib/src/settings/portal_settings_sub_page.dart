import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// A page pushed from a [PortalSettingsPage] nav row: same chrome as the hub
/// (tone, app bar, list padding) so a sub-page reads as part of the same
/// screen rather than a different one bolted on.
class PortalSettingsSubPage extends StatelessWidget {
  const PortalSettingsSubPage({
    super.key,
    required this.title,
    required this.children,
    this.backgroundColor,
  });

  final String title;
  final List<Widget> children;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sp = PortalUiTheme.of(context).tokens.spacing;
    return Scaffold(
      backgroundColor:
          backgroundColor ??
          (cs.brightness == Brightness.light ? cs.surfaceContainerHigh : null),
      appBar: PortalAppBar(title: title),
      body: ListView(
        padding: EdgeInsets.only(top: sp.lg, bottom: sp.xxl),
        children: children,
      ),
    );
  }
}
