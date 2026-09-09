import 'package:flutter/material.dart';

/// Scrollable region with token-styled scrollbar (shadcn Scroll Area).
class PortalScrollArea extends StatelessWidget {
  const PortalScrollArea({
    required this.child,
    super.key,
    this.controller,
    this.showScrollbar = false,
    this.padding,
  });

  final Widget child;
  final ScrollController? controller;
  final bool showScrollbar;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      controller: controller,
      padding: padding,
      child: child,
    );
    if (!showScrollbar || controller == null) return scroll;
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: scroll,
    );
  }
}
