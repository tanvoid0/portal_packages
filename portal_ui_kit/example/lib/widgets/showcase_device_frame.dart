import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Wraps a screen widget in an iOS device mockup with an optional label.
class ShowcaseDeviceFrame extends StatelessWidget {
  const ShowcaseDeviceFrame({
    required this.label,
    required this.screen,
    super.key,
    this.targetWidth = 280,
  });

  final String label;
  final Widget screen;
  final double targetWidth;

  static final DeviceInfo _device = Devices.ios.iPhone13;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;
    final scale = targetWidth / _device.screenSize.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: targetWidth,
          height: _device.screenSize.height * scale + 48,
          child: FittedBox(
            fit: BoxFit.contain,
            child: DeviceFrame(
              device: _device,
              isFrameVisible: true,
              orientation: Orientation.portrait,
              screen: Material(
                color: Theme.of(context).colorScheme.surface,
                child: screen,
              ),
            ),
          ),
        ),
        SizedBox(height: t.spacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(t.radii.full),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.md,
              vertical: t.spacing.xs,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
