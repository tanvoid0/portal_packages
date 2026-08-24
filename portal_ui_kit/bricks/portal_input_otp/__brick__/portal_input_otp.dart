import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// One-time passcode entry with segmented boxes (shadcn Input OTP).
class PortalInputOtp extends StatefulWidget {
  const PortalInputOtp({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;

  @override
  State<PortalInputOtp> createState() => _PortalInputOtpState();
}

class _PortalInputOtpState extends State<PortalInputOtp> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChange);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChange() {
    final text = _controller.text;
    widget.onChanged?.call(text);
    if (text.length >= widget.length) {
      widget.onCompleted?.call(text.substring(0, widget.length));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;
    final text = _controller.text;
    final activeIndex = text.length.clamp(0, widget.length - 1);

    return PortalFocusRing(
      focusNode: _focusNode,
      borderRadius: BorderRadius.circular(t.radii.md),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) SizedBox(width: t.spacing.sm),
                  _OtpCell(
                    char: i < text.length ? text[i] : '',
                    focused: _focusNode.hasFocus && i == activeIndex,
                    portal: portal,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.char,
    required this.focused,
    required this.portal,
  });

  final String char;
  final bool focused;
  final PortalUiTheme portal;

  @override
  Widget build(BuildContext context) {
    final t = portal.tokens;
    final side = focused ? portal.inputFocusBorderSide() : portal.borderSide();

    return AnimatedContainer(
      duration: t.motion.fast,
      width: 40,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: portal.input,
        borderRadius: BorderRadius.circular(t.radii.md),
        border: Border.fromBorderSide(side),
      ),
      child: Text(
        char,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: portal.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
