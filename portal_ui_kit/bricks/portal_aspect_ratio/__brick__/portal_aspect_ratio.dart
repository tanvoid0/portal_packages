import 'package:flutter/material.dart';

/// Fixed aspect ratio box (shadcn Aspect Ratio).
class PortalAspectRatio extends StatelessWidget {
  const PortalAspectRatio({
    required this.aspectRatio,
    required this.child,
    super.key,
  }) : assert(aspectRatio > 0);

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: aspectRatio, child: child);
  }
}
