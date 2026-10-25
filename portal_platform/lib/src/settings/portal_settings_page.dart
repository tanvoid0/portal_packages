import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import '../config/portal_server_prefs.dart';
import '../services/api_client.dart';
import '../session/session_controller.dart';
import '../update/portal_update_service.dart';
import '../update/portal_update_tile.dart';
import '../widgets/portal_app_version.dart';
import 'portal_apps_section.dart';
import 'portal_change_password_page.dart';
import 'portal_server_page.dart';
import 'portal_settings_labels.dart';
import 'portal_settings_sub_page.dart';
import 'portal_theme_controller.dart';

/// One group of rows on [PortalSettingsPage].
class PortalSettingsSection {
  const PortalSettingsSection({
    required this.title,
    required this.children,
    this.slot = PortalSettingsGroup.custom,
  });

  final String title;
  final List<Widget> children;

  /// Where this section renders relative to the page's own groups. Default
  /// [PortalSettingsGroup.custom] renders where it always has — grouped with
  /// the other custom sections, in [PortalSettingsPage.order]'s own slot for
  /// it. Any other group renders this section immediately after that group's
  /// built-in content, so e.g. an app can slide a section in right under
  /// Appearance without displacing it.
  final PortalSettingsGroup slot;
}

/// The groups this page can build for itself, in [_defaultOrder] by default.
///
/// An app passes a subset to [PortalSettingsPage.include] to drop one, and
/// [PortalSettingsPage.order] to move its own sections somewhere other than
/// the default slot.
///
/// Each group is an inline section of the one flat page:
/// [assistant] is the slot for [PortalSettingsPage.assistantSection];
/// [status] is the About section (Mode, App version, Check for updates);
/// [about] is the Account section (change password, sign out, delete
/// account).
enum PortalSettingsGroup {
  profile,
  appearance,
  custom,
  assistant,
  status,
  apps,
  about,
}

/// [PortalSettingsPage.order]'s default: [custom] moves right after
/// [profile] so the nav card built from the rest stays contiguous.
const _defaultOrder = [
  PortalSettingsGroup.profile,
  PortalSettingsGroup.custom,
  PortalSettingsGroup.appearance,
  PortalSettingsGroup.assistant,
  PortalSettingsGroup.apps,
  PortalSettingsGroup.status,
  PortalSettingsGroup.about,
];

/// Segment names for [portalSettingsChildren]'s routes and
/// [PortalSettingsPage.settingsRoute]'s named navigation -- shared so an app
/// builds its full path by combining its own root with one of these rather
/// than retyping e.g. `'account'` itself, and so a cross-app deep link into
/// another app's settings imports that app's root constant plus one of
/// these instead of a hand-typed string.
abstract class PortalSettingsSegment {
  static const appearance = 'appearance';
  static const assistant = 'assistant';
  static const apps = 'apps';
  static const about = 'about';
  static const account = 'account';
  static const changePassword = 'change-password';
}

/// The sub-pages [PortalSettingsPage]'s own rows push, as [GetPage] children
/// -- for an app wiring a nested GetX route tree instead of a plain
/// Navigator stack. Mount this at the same path given to
/// [PortalSettingsPage.settingsRoute] (e.g.
/// `GetPage(name: '/settings', page: () => PortalSettingsPage(settingsRoute:
/// '/home/settings'), children: portalSettingsChildren(...))`), so each row's
/// `Get.toNamed` call resolves against a route that actually exists.
///
/// The page itself is flat and pushes none of these; they remain only as
/// standalone deep-link targets (and [PortalSettingsSegment.changePassword],
/// which the page's change-password row still opens). [include] mirrors
/// [PortalSettingsPage.include] -- [profile] and [custom] build no page here.
/// [assistant] builds nothing when [assistantSection] is null.
List<GetPage> portalSettingsChildren({
  PortalSettingsLabels labels = const PortalSettingsLabels(),
  List<PortalSettingsGroup> include = PortalSettingsGroup.values,
  Widget Function()? assistantSection,
  List<PortalPaletteOption> palettes = const [],
  Future<void> Function(String currentPassword, String newPassword)?
  onChangePassword,
}) => [
  if (include.contains(PortalSettingsGroup.appearance))
    GetPage(
      name: '/${PortalSettingsSegment.appearance}',
      page: () => _AppearancePage(
        labels: labels,
        theme: Get.find<PortalThemeController>(),
        palettes: palettes,
      ),
    ),
  if (include.contains(PortalSettingsGroup.assistant) &&
      assistantSection != null)
    GetPage(
      name: '/${PortalSettingsSegment.assistant}',
      page: () => PortalSettingsSubPage(
        title: labels.assistant,
        children: [assistantSection()],
      ),
    ),
  if (include.contains(PortalSettingsGroup.apps))
    GetPage(
      name: '/${PortalSettingsSegment.apps}',
      page: () => PortalSettingsSubPage(
        title: labels.portalApps,
        children: [
          PortalAppsSection.grouped(
            service: Get.find<PortalUpdateService>(),
            labels: labels,
          ),
        ],
      ),
    ),
  if (include.contains(PortalSettingsGroup.status))
    GetPage(
      name: '/${PortalSettingsSegment.about}',
      page: () => _AboutPage(labels: labels),
    ),
  if (include.contains(PortalSettingsGroup.about))
    GetPage(
      name: '/${PortalSettingsSegment.account}',
      page: () => _AccountPage(
        labels: labels,
        session: Get.find<SessionController>(),
        onChangePassword: onChangePassword,
      ),
      children: [
        // ponytail: this page's own change-password row still falls back to
        // an unnamed push -- it has no settingsRoute to build the absolute
        // path with. Thread one through here if a consumer needs
        // Get.currentRoute to reflect that tap too.
        GetPage(
          name: '/${PortalSettingsSegment.changePassword}',
          page: () => PortalChangePasswordPage(
            labels: labels,
            onSubmit: onChangePassword,
          ),
        ),
      ],
    ),
];

/// The settings every Portal app has, in one page.
///
/// Everything here is app-independent: the profile is one shared record, the
/// theme mode is a preference, the server and assistant are the same backend,
/// and the app list is the same published manifest. An app supplies only what
/// is genuinely its own — [sections] for its features, [assistantSection] for
/// the backend picker (which lives in `portal_ai`, a package above this one).
///
/// Built from `portal_ui_core`: one flat grouped page of inset sections
/// (profile, Appearance, the app's own, Assistant, Portal apps, About,
/// Account), every row leading with a tonal tile, and Portal Cloud's outage
/// in the bar's status line. Theme and accent open sheets; Mode reports
/// whether Portal Cloud answered when the page opened. Seven taps on App
/// version open the dev server page; nothing announces it. An app with its
/// own chrome for its [sections] passes [sectionBuilder] rather than forking
/// the page — `portal_finance` does, to keep its bordered cards.
///
/// An app whose settings screen is too different to mount this at all can
/// still use the pieces: [PortalStatusSection], [PortalAppsSection] and
/// [PortalUpdateTile] each stand alone. [header] covers the more common case
/// of an app wanting this page embedded under its own chrome rather than the
/// standalone pieces.
///
/// See `docs/SETTINGS.md`.
class PortalSettingsPage extends StatefulWidget {
  const PortalSettingsPage({
    super.key,
    this.labels = const PortalSettingsLabels(),
    this.themeController,
    this.palettes = const [],
    this.assistantSection,
    @Deprecated('pass assistantSection') this.aiSection,
    this.sections = const [],
    this.include = PortalSettingsGroup.values,
    this.order = _defaultOrder,
    this.sectionBuilder,
    this.backgroundColor,
    this.onChangePassword,
    this.onSignIn,
    this.header,
    this.settingsRoute,
  });

  final PortalSettingsLabels labels;

  /// Omit to hide the appearance section entirely — an app that does not let
  /// the user change the theme should not show a control that does nothing.
  final PortalThemeController? themeController;

  /// Selectable palettes. Empty hides the accent row: an app with a
  /// hand-built theme has nothing to switch between. The first is shown while
  /// the controller holds no (or an unknown) id, so list the app's own accent
  /// first.
  final List<PortalPaletteOption> palettes;

  /// The app's AI settings, e.g. `AiSettingsGroup` from `portal_ai`. Shown
  /// inline where [PortalSettingsGroup.assistant] falls, as given: it brings
  /// its own header. Null hides it entirely.
  final Widget? assistantSection;

  /// Legacy form of [assistantSection]: same inline section.
  /// Ignored when [assistantSection] is given.
  final Widget? aiSection;

  /// App-specific groups, rendered where [PortalSettingsGroup.custom] falls.
  /// Their children go in as given — finance's are already inset sections.
  final List<PortalSettingsSection> sections;

  /// Groups to build at all. Anything absent is skipped.
  final List<PortalSettingsGroup> include;

  /// Order to build them in. Anything absent from [include] is skipped either
  /// way, so an app that only reorders can leave `include` alone.
  final List<PortalSettingsGroup> order;

  /// Renders one of [sections]. Default is a kit section header above the
  /// children as given.
  final Widget Function(String title, List<Widget> children)? sectionBuilder;

  /// The page tone. Defaults to the grouped tone in light mode, so the inset
  /// sections read as cards; dark mode keeps the theme's surface.
  final Color? backgroundColor;

  /// Replaces the change-password write. Only an app holding key material
  /// wrapped by the old password needs it; see [PortalChangePasswordForm].
  final Future<void> Function(String currentPassword, String newPassword)?
  onChangePassword;

  /// Shows a Sign in row in the profile's place while signed out. Null shows
  /// nothing there: only the app knows how to reach its login.
  final VoidCallback? onSignIn;

  /// Given, this page builds just its `ListView` with [header] as the first
  /// child -- no `Scaffold`, no [PortalAppBar] -- so a caller already inside
  /// its own Scaffold/AppBar/tab shell (e.g. a tab of a bottom-nav page) can
  /// embed these settings without a second app bar on top of its own.
  ///
  /// Embedded mode drops the app bar's cloud-outage status line along with
  /// the bar itself. Nothing is silently lost: the Status group's own "Mode"
  /// row already reports the same reachability, with the page visible.
  final Widget? header;

  /// Mount path for this page's own `GetPage` node, e.g. `/home/settings`.
  /// Given, the Account section's change-password row opens
  /// `Get.toNamed('$settingsRoute/account/change-password')` against the app's
  /// own route tree (see [portalSettingsChildren]) instead of pushing an
  /// unnamed [MaterialPageRoute]. Null (the default) pushes.
  final String? settingsRoute;

  @override
  State<PortalSettingsPage> createState() => _PortalSettingsPageState();
}

/// Opens a settings sub-page: a named route under [route] when it's given,
/// built from one or more [PortalSettingsSegment]s joined with `/`, else
/// today's unnamed [MaterialPageRoute] push -- see
/// [PortalSettingsPage.settingsRoute].
void _openSettingsPage(
  BuildContext context,
  String? route,
  String segment,
  WidgetBuilder builder,
) {
  if (route != null) {
    Get.toNamed('$route/$segment');
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: builder));
}

/// Shared by [_PortalSettingsPageState] and [_AboutPageState]: true/false
/// once answered, never thrown.
Future<bool> _probeReachable() async {
  try {
    return (await Get.find<ApiClient>().checkBackendReadiness()).isReady;
  } catch (_) {
    // A thrown readiness check (no network, DNS, a 5xx) means we could not
    // reach the backend -- which is exactly "unreachable".
    return false;
  }
}

class _PortalSettingsPageState extends State<PortalSettingsPage> {
  /// Whether Portal Cloud answered when the page opened. Null until it has.
  bool? _reachable;
  String? _version;

  PortalSettingsLabels get _labels => widget.labels;

  @override
  void initState() {
    super.initState();
    _probe();
    // Best-effort read: a build with no package info shows the placeholder.
    PortalAppVersion.load().then((info) {
      if (mounted) setState(() => _version = PortalAppVersion.format(info));
    }, onError: (_) {});
  }

  /// Once, on open -- not polled. An app that mounts this without
  /// PortalBootstrap has no client to ask, and says nothing rather than blame
  /// the server for a wiring mistake.
  Future<void> _probe() async {
    if (!Get.isRegistered<ApiClient>()) return;
    final ready = await _probeReachable();
    if (!mounted) return;
    setState(() => _reachable = ready);
  }

  /// The header of a section built by hand: the one [PortalListSection] draws.
  Widget _header(String title) {
    final sp = PortalUiTheme.of(context).tokens.spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(sp.lg, sp.lg, sp.lg, sp.sm),
      child: PortalSectionHeader(title: title),
    );
  }

  Widget _defaultSection(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_header(title), ...children],
  );

  Widget _profile(SessionController session) => Obx(() {
    final user = session.user.value;
    if (user == null) {
      final onSignIn = widget.onSignIn;
      if (onSignIn == null) return const SizedBox.shrink();
      return PortalListSection(
        children: [
          PortalListItem(
            title: _labels.signIn,
            subtitle: _labels.signInSubtitle,
            leading: PortalListLeading.tile(PortalIcons.login_rounded),
            trailing: const PortalListAccessory.navigate(),
            onTap: onSignIn,
          ),
        ],
      );
    }
    final localOnly = user['local_only'] == true;
    final name = (user['name'] as String?)?.trim() ?? '';
    final email = (user['email'] as String?)?.trim() ?? '';
    final photo = SessionController.avatarUrlFor(user);
    return PortalListSection(
      children: [
        PortalListItem(
          title: name.isEmpty ? _labels.profileFallbackTitle : name,
          subtitle: localOnly
              ? _labels.modeOnDevice
              : (email.isEmpty ? null : email),
          leading: PortalListLeading.avatar(
            SessionController.initialsFor(user),
            image: photo == null ? null : NetworkImage(photo),
            large: true,
          ),
          trailing: const PortalListAccessory.navigate(),
          onTap: () => PortalSheet.show<void>(
            context,
            builder: (_) =>
                _NameSheet(labels: _labels, session: session, current: name),
          ),
        ),
      ],
    );
  });

  /// The Account section, gated on sign-in reactively.
  Widget _account(SessionController session) => Obx(() {
    if (session.user.value == null) return const SizedBox.shrink();
    return _AccountRows(
      labels: _labels,
      session: session,
      onChangePassword: widget.onChangePassword,
      settingsRoute: widget.settingsRoute,
    );
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sp = PortalUiTheme.of(context).tokens.spacing;
    final updates = Get.isRegistered<PortalUpdateService>()
        ? Get.find<PortalUpdateService>()
        : null;
    final buildSection = widget.sectionBuilder ?? _defaultSection;

    // Under PortalTabShell's floating pill (extendBody: true), the Scaffold
    // feeds the pill's height into the body's MediaQuery bottom padding; a
    // fixed sp.xxl alone left the last section (Account/sign-out) under the
    // pill. Adding it clears the pill when there is one and is ~0 standalone.
    final listPadding = EdgeInsets.only(
      top: sp.lg,
      bottom: sp.xxl + MediaQuery.paddingOf(context).bottom,
    );

    final children = <Widget>[];
    for (final group in widget.order) {
      if (!widget.include.contains(group)) continue;
      switch (group) {
        case PortalSettingsGroup.profile:
          if (Get.isRegistered<SessionController>()) {
            children.add(_profile(Get.find<SessionController>()));
          }

        case PortalSettingsGroup.appearance:
          if (widget.themeController case final theme?) {
            children.add(
              _AppearanceRows(
                labels: _labels,
                theme: theme,
                palettes: widget.palettes,
              ),
            );
          }

        case PortalSettingsGroup.custom:
          for (final section in widget.sections) {
            if (section.slot != PortalSettingsGroup.custom) continue;
            children.add(buildSection(section.title, section.children));
          }

        case PortalSettingsGroup.assistant:
          // No header of ours: the section (AiSettingsGroup / AiSettingsSection)
          // draws its own, and a second one above it read as a stutter.
          if (widget.assistantSection ?? widget.aiSection case final section?) {
            children.add(section);
          }

        case PortalSettingsGroup.status:
          children.add(
            _AboutRows(
              labels: _labels,
              reachable: _reachable,
              version: _version,
            ),
          );

        case PortalSettingsGroup.apps:
          // Gated on the same predicate the section itself uses, so iOS and a
          // build with no manifest URL get no section at all.
          if (updates != null && portalCanInstallApps(updates)) {
            children.add(
              PortalAppsSection.grouped(service: updates, labels: _labels),
            );
          }

        case PortalSettingsGroup.about:
          if (Get.isRegistered<SessionController>()) {
            children.add(_account(Get.find<SessionController>()));
          }
      }
      // A section slotted to this group (not the default `custom`, which
      // rendered above in its own case) lands right after the group's own
      // content -- so e.g. an app can slide a section under Appearance
      // without displacing it.
      if (group != PortalSettingsGroup.custom) {
        for (final section in widget.sections.where((s) => s.slot == group)) {
          children.add(buildSection(section.title, section.children));
        }
      }
    }

    if (widget.header case final header?) {
      return ListView(
        padding: listPadding,
        children: [header, ...children],
      );
    }

    final unreachable = _reachable == false;
    return Scaffold(
      backgroundColor:
          widget.backgroundColor ??
          (cs.brightness == Brightness.light ? cs.surfaceContainerHigh : null),
      appBar: PortalAppBar(
        title: _labels.title,
        status: unreachable ? _labels.cloudUnreachable : null,
        statusIcon: PortalIcons.cloud_off_rounded,
      ),
      body: ListView(
        padding: listPadding,
        children: children,
      ),
    );
  }
}

/// The page's [palettes] entry in force: the controller's pick, else the
/// first (the app's own accent). Null when the app offers no palettes.
PortalPaletteOption? _currentPalette(
  PortalThemeController controller,
  List<PortalPaletteOption> palettes,
) {
  if (palettes.isEmpty) return null;
  final id = controller.paletteId.value;
  return palettes.firstWhere((p) => p.id == id, orElse: () => palettes.first);
}

/// A row that counts taps nobody is told about: out of semantics, no ripple.
/// A subclass, not a wrapper, so [PortalListSection] still insets the divider
/// under it to the text column.
class _HiddenTapRow extends PortalListItem {
  const _HiddenTapRow({
    required super.title,
    super.leading,
    super.trailing,
    required this.onHiddenTap,
  });

  final VoidCallback onHiddenTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: onHiddenTap,
    child: super.build(context),
  );
}

/// The Haptics row's current value, from the labels given rather than the
/// page's own -- [_AppearancePage] is pushed with its own copy of [labels].
String _hapticsValueLabel(
  PortalThemeController theme,
  PortalSettingsLabels labels,
) {
  if (!theme.hapticsEnabled.value) return labels.hapticsOff;
  return theme.hapticsIntensity.value == PortalHapticIntensity.light
      ? labels.hapticsLight
      : labels.hapticsFull;
}

/// The Appearance section: Theme, Accent colour and Haptics rows open their
/// sheets. Inline on the page, and the body of [_AppearancePage].
class _AppearanceRows extends StatelessWidget {
  const _AppearanceRows({
    required this.labels,
    required this.theme,
    required this.palettes,
  });

  final PortalSettingsLabels labels;
  final PortalThemeController theme;
  final List<PortalPaletteOption> palettes;

  @override
  Widget build(BuildContext context) => Obx(() {
    final palette = _currentPalette(theme, palettes);
    return PortalListSection(
      header: labels.appearance,
      children: [
        PortalListItem(
          title: labels.theme,
          leading: PortalListLeading.tile(PortalIcons.dark_mode_rounded),
          trailing: PortalListAccessory.navigate(
            value: PortalThemeController.labelFor(theme.themeMode.value),
          ),
          onTap: () => PortalSheet.show<void>(
            context,
            title: labels.theme,
            builder: (_) => _ThemeSheet(controller: theme, labels: labels),
          ),
        ),
        if (palette != null)
          PortalListItem(
            title: labels.accentColour,
            leading: PortalListLeading.tile(PortalIcons.palette_rounded),
            trailing: PortalListAccessory.navigate(
              value: palette.label,
              swatchColor: palette.swatch,
            ),
            onTap: () => PortalSheet.show<void>(
              context,
              title: labels.accentColour,
              builder: (_) =>
                  _AccentSheet(controller: theme, palettes: palettes),
            ),
          ),
        if (!kIsWeb)
          PortalListItem(
            title: labels.haptics,
            leading: PortalListLeading.tile(PortalIcons.vibration_rounded),
            trailing: PortalListAccessory.navigate(
              value: _hapticsValueLabel(theme, labels),
            ),
            onTap: () => PortalSheet.show<void>(
              context,
              title: labels.haptics,
              builder: (_) => _HapticsSheet(controller: theme, labels: labels),
            ),
          ),
      ],
    );
  });
}

/// [_AppearanceRows] on its own page, for the `appearance` route of
/// [portalSettingsChildren].
class _AppearancePage extends StatelessWidget {
  const _AppearancePage({
    required this.labels,
    required this.theme,
    required this.palettes,
  });

  final PortalSettingsLabels labels;
  final PortalThemeController theme;
  final List<PortalPaletteOption> palettes;

  @override
  Widget build(BuildContext context) => PortalSettingsSubPage(
    title: labels.appearance,
    children: [
      _AppearanceRows(labels: labels, theme: theme, palettes: palettes),
    ],
  );
}

/// The About section: Mode, App version (still the 7-tap dev-unlock) and
/// Check for updates. Inline on the page, and the body of [_AboutPage].
class _AboutRows extends StatefulWidget {
  const _AboutRows({
    required this.labels,
    this.reachable,
    this.version,
    this.load = false,
  });

  final PortalSettingsLabels labels;

  /// What the page already knows; null is still loading.
  final bool? reachable;
  final String? version;

  /// Self-load reachability and version on mount -- for [_AboutPage], reached
  /// by its own route with nothing to read from. The page itself passes its
  /// own answers instead, so it probes once, not twice.
  final bool load;

  @override
  State<_AboutRows> createState() => _AboutRowsState();
}

class _AboutRowsState extends State<_AboutRows> {
  bool _checkingUpdate = false;
  bool? _loadedReachable;
  String? _loadedVersion;

  bool? get _reachable => widget.reachable ?? _loadedReachable;
  String? get _version => widget.version ?? _loadedVersion;

  // Server-switch reveal: 7 taps on the App version row (Android's own
  // dev-options gesture), or a debug build. The gesture is only a
  // discoverability gate -- PortalServerPrefs.localUrlFrom's private-host
  // check is what actually stops this reaching a real server.
  bool _devToolsUnlocked = kDebugMode;
  int _serverTaps = 0;

  PortalSettingsLabels get _labels => widget.labels;

  @override
  void initState() {
    super.initState();
    if (!_devToolsUnlocked) {
      PortalServerPrefs.devToolsUnlocked().then((unlocked) {
        if (unlocked && mounted) setState(() => _devToolsUnlocked = true);
      });
    }
    // Null means the caller had no answer yet, or none at all (reached
    // through its own named route rather than pushed with a snapshot) --
    // probe rather than stay stuck on "Checking..." forever.
    if (!widget.load) return;
    _probe();
    PortalAppVersion.load().then((info) {
      if (mounted) {
        setState(() => _loadedVersion = PortalAppVersion.format(info));
      }
    }, onError: (_) {});
  }

  Future<void> _probe() async {
    if (!Get.isRegistered<ApiClient>()) return;
    final ready = await _probeReachable();
    if (!mounted) return;
    setState(() => _loadedReachable = ready);
  }

  void _onVersionTap() {
    if (_devToolsUnlocked) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PortalServerPage(labels: _labels)),
      );
      return;
    }
    _serverTaps++;
    if (_serverTaps >= 7) {
      PortalServerPrefs.unlockDevTools();
      setState(() => _devToolsUnlocked = true);
    }
  }

  Future<void> _checkForUpdates(PortalUpdateService service) async {
    setState(() => _checkingUpdate = true);
    final result = await service.check();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (result.status == PortalUpdateStatus.updateAvailable) {
      await showPortalUpdateDialog(context, service, result.release!);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.status == PortalUpdateStatus.upToDate
              ? _labels.upToDate
              : result.message ?? _labels.updateCheckFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updates = Get.isRegistered<PortalUpdateService>()
        ? Get.find<PortalUpdateService>()
        : null;
    // ponytail: Mode reflects reachability only; routing-aware text needs a modeLabel callback — add when an app asks.
    final mode = switch (_reachable) {
      null => _labels.checking,
      true => _labels.modeCloud,
      false => _labels.modeOnDevice,
    };
    return PortalListSection(
      header: _labels.about,
      children: [
        // Nothing to be in a mode of without a client.
        if (Get.isRegistered<ApiClient>())
          PortalListItem(
            title: _labels.mode,
            leading: PortalListLeading.tile(
              PortalIcons.swap_horiz_rounded,
              tone: PortalListTone.tertiary,
            ),
            trailing: PortalListAccessory.value(
              mode,
              sentiment: PortalValueSentiment.dim,
            ),
          ),
        _HiddenTapRow(
          title: _labels.appVersion,
          leading: PortalListLeading.tile(
            PortalIcons.info_rounded,
            tone: PortalListTone.tertiary,
          ),
          trailing: PortalListAccessory.value(
            _version ?? '…',
            sentiment: PortalValueSentiment.dim,
          ),
          onHiddenTap: _onVersionTap,
        ),
        if (updates != null && updates.isEnabled)
          PortalListItem(
            title: _labels.checkForUpdates,
            leading: PortalListLeading.tile(
              PortalIcons.system_update_rounded,
              tone: PortalListTone.tertiary,
            ),
            trailing: _checkingUpdate
                ? PortalListAccessory.value(
                    _labels.checking,
                    sentiment: PortalValueSentiment.dim,
                  )
                : PortalListAccessory.none,
            onTap: _checkingUpdate ? null : () => _checkForUpdates(updates),
          ),
      ],
    );
  }
}

/// [_AboutRows] on its own page, for the `about` route of
/// [portalSettingsChildren].
class _AboutPage extends StatelessWidget {
  const _AboutPage({required this.labels});

  final PortalSettingsLabels labels;

  @override
  Widget build(BuildContext context) => PortalSettingsSubPage(
    title: labels.about,
    children: [_AboutRows(labels: labels, load: true)],
  );
}

/// The Account section: change password, sign out, delete account. Inline on
/// the page, and the body of [_AccountPage] for a deep link to it.
class _AccountRows extends StatefulWidget {
  const _AccountRows({
    required this.labels,
    required this.session,
    required this.onChangePassword,
    this.settingsRoute,
  });

  final PortalSettingsLabels labels;
  final SessionController session;
  final Future<void> Function(String currentPassword, String newPassword)?
  onChangePassword;

  /// Same value as [PortalSettingsPage.settingsRoute] -- see
  /// [_openSettingsPage].
  final String? settingsRoute;

  @override
  State<_AccountRows> createState() => _AccountRowsState();
}

class _AccountRowsState extends State<_AccountRows> {
  String? _deleteError;

  PortalSettingsLabels get _labels => widget.labels;

  Future<void> _signOut() async {
    final confirmed = await portalConfirm(
      context,
      title: _labels.signOutConfirmTitle,
      message: _labels.signOutConfirmMessage,
      confirmLabel: _labels.signOut,
      cancelLabel: _labels.cancel,
    );
    if (confirmed) await widget.session.signOut();
  }

  /// Deletes the account server-side, then signs out.
  ///
  /// Play requires an in-app deletion path for any app that creates accounts,
  /// so this belongs here rather than in one app's own settings.
  Future<void> _deleteAccount() async {
    final confirmed = await portalConfirm(
      context,
      title: _labels.deleteAccountConfirmTitle,
      message: _labels.deleteAccountConfirmMessage,
      confirmLabel: _labels.deleteAccount,
      cancelLabel: _labels.cancel,
      isDestructive: true,
    );
    if (confirmed && mounted) await _runDelete();
  }

  Future<void> _runDelete() async {
    setState(() => _deleteError = null);
    try {
      await widget.session.deleteAccount();
    } catch (error) {
      // Still signed in, and the account still exists. Saying nothing here
      // would read as a delete that worked.
      if (!mounted) return;
      setState(() => _deleteError = '${_labels.deleteAccountFailed} $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = PortalUiTheme.of(context).tokens.spacing;
    // A local-only session has no password and no server account to delete
    // — both rows would just 401/throw against an account that never
    // existed server-side.
    final localOnly = widget.session.user.value?['local_only'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_deleteError case final error?)
          Padding(
            padding: EdgeInsets.fromLTRB(sp.lg, 0, sp.lg, sp.sm),
            child: PortalPrompt(
              size: PortalPromptSize.compact,
              sentiment: PortalSentiment.negative,
              message: error,
              action: (label: _labels.retry, onPressed: _runDelete),
            ),
          ),
        PortalListSection(
          header: _labels.account,
          children: [
            if (!localOnly)
              PortalListItem(
                title: _labels.changePassword,
                leading: PortalListLeading.tile(PortalIcons.lock_rounded),
                trailing: const PortalListAccessory.navigate(),
                onTap: () => _openSettingsPage(
                  context,
                  widget.settingsRoute,
                  '${PortalSettingsSegment.account}/'
                  '${PortalSettingsSegment.changePassword}',
                  (_) => PortalChangePasswordPage(
                    labels: _labels,
                    onSubmit: widget.onChangePassword,
                  ),
                ),
              ),
            PortalListItem(
              title: _labels.signOut,
              leading: PortalListLeading.tile(PortalIcons.logout_rounded),
              onTap: _signOut,
            ),
            if (!localOnly)
              PortalListItem(
                title: _labels.deleteAccount,
                leading: PortalListLeading.tile(
                  PortalIcons.delete_rounded,
                  tone: PortalListTone.error,
                ),
                destructive: true,
                onTap: _deleteAccount,
              ),
          ],
        ),
      ],
    );
  }
}

/// [_AccountRows] on its own page, for the `account` route of
/// [portalSettingsChildren].
class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.labels,
    required this.session,
    required this.onChangePassword,
  });

  final PortalSettingsLabels labels;
  final SessionController session;
  final Future<void> Function(String currentPassword, String newPassword)?
  onChangePassword;

  @override
  Widget build(BuildContext context) => PortalSettingsSubPage(
    title: labels.account,
    children: [
      _AccountRows(
        labels: labels,
        session: session,
        onChangePassword: onChangePassword,
      ),
    ],
  );
}

/// Edit name: one field over a Save dock. Save is off while the field is
/// blank and busy while the write runs; a failed write is a retry prompt under
/// the field, never a close.
///
/// The profile is one record shared by every Portal app, so the write is
/// [SessionController.updateName], not a per-app display name.
class _NameSheet extends StatefulWidget {
  const _NameSheet({
    required this.labels,
    required this.session,
    required this.current,
  });

  final PortalSettingsLabels labels;
  final SessionController session;
  final String current;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _name = TextEditingController(text: widget.current);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    if (name == widget.current) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.updateName(name);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = widget.labels.nameSaveFailed;
      });
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final sp = PortalUiTheme.of(context).tokens.spacing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: PortalSheetScaffold(
            title: labels.editName,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalTextField(
                  controller: _name,
                  label: labels.nameDialogTitle,
                  helper: labels.nameDialogHelper,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                if (_error case final error?)
                  Padding(
                    padding: EdgeInsets.only(top: sp.md),
                    child: PortalPrompt(
                      size: PortalPromptSize.compact,
                      sentiment: PortalSentiment.negative,
                      message: error,
                      action: (label: labels.retry, onPressed: _save),
                    ),
                  ),
              ],
            ),
          ),
        ),
        PortalButtonDock(
          primary: ListenableBuilder(
            listenable: _name,
            builder: (_, __) => PortalButton(
              label: labels.save,
              size: PortalButtonSize.lg,
              expand: true,
              isLoading: _busy,
              busyLabel: labels.savingName,
              onPressed: _name.text.trim().isEmpty ? null : _save,
            ),
          ),
        ),
      ],
    );
  }
}

/// The Theme row's picker: applies on tap, so no dock.
class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.controller, required this.labels});

  final PortalThemeController controller;
  final PortalSettingsLabels labels;

  static IconData _icon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => PortalIcons.brightness_auto_rounded,
    ThemeMode.light => PortalIcons.light_mode_rounded,
    ThemeMode.dark => PortalIcons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context) => Obx(() {
    final current = controller.themeMode.value;
    return PortalListSection.selectable(
      selected: ThemeMode.values.indexOf(current),
      children: [
        for (final mode in ThemeMode.values)
          PortalListItem(
            title: PortalThemeController.labelFor(mode),
            subtitle: mode == ThemeMode.system ? labels.themeSystemHint : null,
            leading: PortalListLeading.icon(_icon(mode)),
            trailing: PortalListAccessory.radio(
              checked: mode == current,
              onChanged: (_) {
                controller.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
          ),
      ],
    );
  });
}

/// The Haptics row's picker: Off plus every [PortalHapticIntensity], applied
/// on tap like [_ThemeSheet] — no dock, no confirm, nothing to lose by
/// trying a level and backing out.
class _HapticsSheet extends StatelessWidget {
  const _HapticsSheet({required this.controller, required this.labels});

  final PortalThemeController controller;
  final PortalSettingsLabels labels;

  @override
  Widget build(BuildContext context) => Obx(() {
    final enabled = controller.hapticsEnabled.value;
    final intensity = controller.hapticsIntensity.value;
    final selected = !enabled
        ? 0
        : (intensity == PortalHapticIntensity.light ? 1 : 2);
    return PortalListSection.selectable(
      selected: selected,
      children: [
        PortalListItem(
          title: labels.hapticsOff,
          leading: PortalListLeading.icon(PortalIcons.vibration_rounded),
          trailing: PortalListAccessory.radio(
            checked: selected == 0,
            onChanged: (_) {
              controller.setHapticsEnabled(false);
              Navigator.pop(context);
            },
          ),
        ),
        PortalListItem(
          title: labels.hapticsLight,
          leading: PortalListLeading.icon(PortalIcons.vibration_rounded),
          trailing: PortalListAccessory.radio(
            checked: selected == 1,
            onChanged: (_) {
              _pick(PortalHapticIntensity.light);
              Navigator.pop(context);
            },
          ),
        ),
        PortalListItem(
          title: labels.hapticsFull,
          leading: PortalListLeading.icon(PortalIcons.vibration_rounded),
          trailing: PortalListAccessory.radio(
            checked: selected == 2,
            onChanged: (_) {
              _pick(PortalHapticIntensity.full);
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  });

  void _pick(PortalHapticIntensity intensity) {
    controller.setHapticsEnabled(true);
    controller.setHapticsIntensity(intensity);
  }
}

/// The Accent colour row's picker: swatches in a [PortalChoiceGrid], applied
/// on tap; the grid announces the selected one and checks it.
class _AccentSheet extends StatelessWidget {
  const _AccentSheet({required this.controller, required this.palettes});

  final PortalThemeController controller;
  final List<PortalPaletteOption> palettes;

  @override
  Widget build(BuildContext context) {
    final sheet = Theme.of(context).bottomSheetTheme;
    final ground =
        sheet.modalBackgroundColor ??
        sheet.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerLow;
    return Obx(() {
      final picked = _currentPalette(controller, palettes);
      return PortalChoiceGrid(
        groundColor: ground,
        choices: [
          for (final p in palettes) PortalChoiceOption.color(p.label, p.swatch),
        ],
        selected: picked == null ? null : palettes.indexOf(picked),
        onSelected: (i) {
          controller.setPaletteId(palettes[i].id);
          Navigator.pop(context);
        },
      );
    });
  }
}
