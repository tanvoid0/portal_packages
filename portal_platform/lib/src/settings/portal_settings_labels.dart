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
    this.deleteAccount = 'Delete account',
    this.deleteAccountConfirmTitle = 'Delete your account?',
    this.deleteAccountConfirmMessage =
        'This deletes your Portal account and everything stored against it on '
            'the server, in every Portal app. It cannot be undone.',
    this.deleteAccountFailed = 'Could not delete your account.',
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
    this.serverLocalDetail = 'Local',
    this.serverCloud = 'Cloud',
    this.serverLocal = 'Local',
    this.serverLocalHost = 'Host and port',
    this.serverLocalHint =
        '10.0.2.2 reaches your machine from an Android emulator; '
            'use your computer\'s LAN IP from a physical device.',
    this.serverCheck = 'Check',
    this.serverSwitch = 'Switch and sign out',
    this.serverSwitchConfirmTitle = 'Switch server?',
    this.serverSwitchConfirmMessage =
        'You will be signed out. Sign back in against the new server.',
    this.serverInvalidHost =
        'Only a local-network address is allowed here (e.g. 10.0.2.2, '
            '192.168.x.x, localhost).',
    this.loading = 'Loading…',
    this.tryAgain = 'Try again',
    this.install = 'Install',
    this.update = 'Update',
    this.uninstall = 'Uninstall',
    this.uninstallConfirmMessage =
        'Android will ask you to confirm. Anything this app stored on the '
            'device goes with it; what is on the server does not.',
    this.open = 'Open',
    this.installAll = 'Install all',
    this.downloading = 'Downloading',
    this.installAllDone = 'Installed',
    this.installAllFailed = 'skipped',
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
  final String deleteAccount;
  final String deleteAccountConfirmTitle;
  final String deleteAccountConfirmMessage;
  final String deleteAccountFailed;
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
  final String serverLocalDetail;
  final String serverCloud;
  final String serverLocal;
  final String serverLocalHost;
  final String serverLocalHint;
  final String serverCheck;
  final String serverSwitch;
  final String serverSwitchConfirmTitle;
  final String serverSwitchConfirmMessage;
  final String serverInvalidHost;

  // App list.
  final String loading;
  final String tryAgain;
  final String install;
  final String update;
  final String uninstall;
  final String uninstallConfirmMessage;
  final String open;
  final String installAll;
  final String downloading;
  final String installAllDone;
  final String installAllFailed;
  final String noOtherApps;
  final String appListFailed;
}
