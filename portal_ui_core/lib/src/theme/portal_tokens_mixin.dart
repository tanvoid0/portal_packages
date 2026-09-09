import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'portal_ui_theme.dart';

/// Convenience mixin for [State] subclasses that frequently access tokens.
///
/// Provides short-hand getters so widgets can write `spacing.lg` instead of
/// `PortalUiTheme.of(context).tokens.spacing.lg`.
///
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with PortalTokensMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Padding(
///       padding: EdgeInsets.all(spacing.lg),
///       child: DecoratedBox(
///         decoration: BoxDecoration(
///           borderRadius: BorderRadius.circular(radii.md),
///           boxShadow: elevation.card(brightness),
///         ),
///         child: Text('Hello', style: textStyles.title),
///       ),
///     );
///   }
/// }
/// ```
///
/// For [StatelessWidget] or one-off access, use [PortalUiTheme.of] directly.
mixin PortalTokensMixin<T extends StatefulWidget> on State<T> {
  PortalUiTheme get portal => PortalUiTheme.of(context);
  DesignTokens get tokens => portal.tokens;
  PortalSpacing get spacing => tokens.spacing;
  PortalRadii get radii => tokens.radii;
  PortalTypeScale get typeScale => tokens.typeScale;
  PortalTextStyles get textStyles => tokens.textStyles;
  PortalMotion get motion => tokens.motion;
  PortalElevation get elevation => tokens.elevation;
  Brightness get brightness => Theme.of(context).brightness;
}
