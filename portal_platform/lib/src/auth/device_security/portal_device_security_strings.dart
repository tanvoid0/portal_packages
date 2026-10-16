/// Localized copy for device-security UI. Host apps supply translated strings.
class PortalDeviceSecurityStrings {
  const PortalDeviceSecurityStrings({
    required this.settingsTitle,
    required this.settingsSubtitle,
    required this.unavailableSubtitle,
    required this.unlockTitle,
    required this.unlockSubtitle,
    required this.unlockButton,
    required this.authenticateReason,
    required this.enableReason,
    required this.notAvailableMessage,
    required this.enableFailedMessage,
    this.noScreenLockSubtitle = 'Set a screen lock on this phone first.',
    this.openSettingsButton = 'Open phone settings',
    this.forgotPinButton = 'Forgot PIN?',
  });

  final String settingsTitle;
  final String settingsSubtitle;
  final String unavailableSubtitle;
  final String unlockTitle;
  final String unlockSubtitle;
  final String unlockButton;
  final String authenticateReason;
  final String enableReason;
  final String notAvailableMessage;
  final String enableFailedMessage;

  /// Lead when the phone has no screen lock: what to set up first.
  final String noScreenLockSubtitle;
  final String openSettingsButton;
  final String forgotPinButton;
}
