/// Every user-visible string on the shared settings page and its widgets.
///
/// Defaults are English. An app that localises its own screens passes its
/// translated strings instead — `portal_task` renders
/// [PortalStatusSection] and [PortalAppsSection] inside a hub where every
/// other row comes from `LocaleKeys`, and without this those two rows are the
/// only untranslated ones on the page.
///
/// Same shape as `AiBackendLabels` in `portal_ai`, deliberately: an app wiring
/// up both should not have to learn two conventions.
class PortalSettingsLabels {
  const PortalSettingsLabels({
    this.title = 'Settings',
    this.appearance = 'Appearance',
    this.assistant = 'Assistant',
    this.status = 'Status',
    this.portalApps = 'Portal apps',
    this.about = 'About',
    this.profileFallbackTitle = 'Your profile',
    this.nameDialogTitle = 'Your name',
    this.nameDialogHelper = 'Shared by every Portal app',
    this.nameSaveFailed = 'Could not save your name.',
    this.cancel = 'Cancel',
    this.save = 'Save',
    this.signOut = 'Sign out',
    this.signOutConfirmTitle = 'Sign out?',
    this.signOutConfirmMessage = 'You will need to sign in again.',
    this.notSignedIn = 'Not signed in',
    this.appVersion = 'App version',
    this.serverTitle = 'Server',
    this.serverOnline = 'Online',
    this.serverUnreachable = 'Unreachable',
    this.assistantNeedsServer = 'Needs the server',
    this.assistantNotConfigured = 'No model configured on the server',
    this.assistantUnknown = 'Could not read assistant status',
    this.checking = 'Checking…',
    this.checkAgain = 'Check again',
    this.loading = 'Loading…',
    this.tryAgain = 'Try again',
    this.install = 'Install',
    this.open = 'Open',
    this.noOtherApps = 'No other apps published yet',
    this.appListFailed = 'Could not load the app list.',
  });

  final String title;

  // Section headings.
  final String appearance;
  final String assistant;
  final String status;
  final String portalApps;
  final String about;

  // Profile.
  final String profileFallbackTitle;
  final String nameDialogTitle;
  final String nameDialogHelper;
  final String nameSaveFailed;
  final String cancel;
  final String save;
  final String signOut;
  final String signOutConfirmTitle;
  final String signOutConfirmMessage;
  final String notSignedIn;
  final String appVersion;

  // Status rows.
  final String serverTitle;
  final String serverOnline;
  final String serverUnreachable;
  final String assistantNeedsServer;
  final String assistantNotConfigured;
  final String assistantUnknown;
  final String checking;
  final String checkAgain;

  // App list.
  final String loading;
  final String tryAgain;
  final String install;
  final String open;
  final String noOtherApps;
  final String appListFailed;
}
