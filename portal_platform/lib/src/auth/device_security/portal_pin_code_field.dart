import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A segmented, one-box-per-digit PIN entry (Netflix-style) instead of a
/// plain obscured [TextField] — the box count shows how many digits the PIN
/// can hold, and each fills in as the user types.
///
/// A single real [TextField] still drives input (keyboard, paste, IME) —
/// it's just painted invisible and stacked under the boxes, which read its
/// [controller] to render themselves. That keeps focus/paste behaving
/// exactly like a normal text field; the boxes are pure display.
/// [TextField.enableInteractiveSelection] is off: a tap or long-press would
/// otherwise place the (invisible) caret or draw selection handles over the
/// boxes rather than just focusing the field, scrambling digit order.
class PortalPinCodeField extends StatefulWidget {
  const PortalPinCodeField({
    super.key,
    required this.controller,
    required this.maxLength,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;

  /// Box count. The field never exceeds this many digits.
  final int maxLength;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PortalPinCodeField> createState() => _PortalPinCodeFieldState();
}

class _PortalPinCodeFieldState extends State<PortalPinCodeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(PortalPinCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = widget.controller.text;
    const spacing = 8.0;
    const boxHeight = 44.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Box width shrinks to keep every box on one row (a narrow phone
          // viewport wrapping the last box to its own line looked broken),
          // but never grows past the design size.
          final fit =
              (constraints.maxWidth - spacing * (widget.maxLength - 1)) /
                  widget.maxLength;
          final boxWidth = fit.clamp(0.0, 36.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.maxLength; i++) ...[
                    if (i > 0) const SizedBox(width: spacing),
                    _PinDigitBox(
                      width: boxWidth,
                      height: boxHeight,
                      filled: i < text.length,
                      focused: _focusNode.hasFocus && i == text.length,
                      colors: cs,
                    ),
                  ],
                ],
              ),
              // Invisible but tappable/typable — real IME input lands here.
              // alwaysIncludeSemantics keeps the field (and the Semantics
              // label/value below) reachable by a screen reader despite
              // opacity 0; the boxes carry no semantics of their own.
              Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: SizedBox(
                  width: widget.maxLength * 40.0,
                  height: boxHeight,
                  child: Semantics(
                    textField: true,
                    label: 'PIN',
                    value: '${text.length} of ${widget.maxLength} digits entered',
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(widget.maxLength),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PinDigitBox extends StatelessWidget {
  const _PinDigitBox({
    required this.width,
    required this.height,
    required this.filled,
    required this.focused,
    required this.colors,
  });

  final double width;
  final double height;
  final bool filled;
  final bool focused;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: focused ? colors.primary : colors.outlineVariant,
            width: focused ? 2 : 1,
          ),
        ),
        child: filled
            ? Icon(Icons.circle, size: 10, color: colors.onSurface)
            : null,
      ),
    );
  }
}
