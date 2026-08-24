import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Click-triggered anchored panel (shadcn Popover).
class PortalPopover extends StatefulWidget {
  const PortalPopover({
    required this.trigger,
    required this.content,
    super.key,
    this.width,
    this.anchor = Alignment.bottomLeft,
    this.follower = Alignment.topLeft,
    this.offset = Offset.zero,
  });

  final Widget trigger;
  final Widget content;
  final double? width;
  final Alignment anchor;
  final Alignment follower;
  final Offset offset;

  @override
  State<PortalPopover> createState() => _PortalPopoverState();
}

class _PortalPopoverState extends State<PortalPopover> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    final portal = PortalUiTheme.of(context);
    final t = portal.tokens;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _controller.hide,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: widget.anchor,
                followerAnchor: widget.follower,
                offset: widget.offset,
                child: Material(
                  color: Colors.transparent,
                  child: PortalThemedSurface(
                    color: portal.popover,
                    borderRadius: BorderRadius.circular(t.radii.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 180,
                        maxWidth: widget.width ?? 320,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(t.spacing.md),
                        child: widget.content,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: GestureDetector(
          onTap: _controller.toggle,
          child: widget.trigger,
        ),
      ),
    );
  }
}
