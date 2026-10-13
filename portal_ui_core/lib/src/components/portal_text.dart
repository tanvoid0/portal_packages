import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';

/// Text that shrinks to fit its box instead of overflowing or clipping.
///
/// Drop-in for [Text] where the box width is fixed and the string can run
/// long or be translated — button labels, chips, single-line titles, stat
/// values. Pass the token style as [style]; the glyph shrinks no smaller than
/// [minFontSize] then ellipsizes.
///
/// Not for body copy: a paragraph that can wrap and push the page down does
/// not need shrinking — plain [Text] is right there. Reach for this only when
/// the box cannot grow.
///
/// Caveat: this wraps [AutoSizeText], which measures with a `LayoutBuilder`.
/// A `LayoutBuilder` throws when something asks it for an intrinsic size, so
/// do **not** put a [PortalText] inside an `IntrinsicHeight`/`IntrinsicWidth`
/// (or anything that measures intrinsics, like some `Table`/`IntrinsicColumnWidth`
/// cells). Keep plain [Text] there.
class PortalText extends StatelessWidget {
  const PortalText(
    this.data, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.minFontSize = 10,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.stepGranularity = 1,
    this.group,
  });

  final String data;
  final TextStyle? style;
  final int maxLines;

  /// Floor for the shrunk glyph, in logical px. Below this it ellipsizes
  /// rather than shrink further.
  final double minFontSize;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final double stepGranularity;

  /// Share a group so a row of labels all settle on the same shrunk size.
  final AutoSizeGroup? group;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      data,
      style: style,
      maxLines: maxLines,
      minFontSize: minFontSize,
      stepGranularity: stepGranularity,
      textAlign: textAlign,
      overflow: overflow,
      group: group,
    );
  }
}
