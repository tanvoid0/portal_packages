import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

import 'catalog/component_catalog.dart';
import 'pages/component_detail_page.dart';
import 'pages/home_page.dart';
import 'pages/ui_kit_showcase_page.dart';
import 'theme/theme_controls.dart';

enum _DocsView { overview, showcase, component }

class PortalDocsApp extends StatefulWidget {
  const PortalDocsApp({super.key});

  @override
  State<PortalDocsApp> createState() => _PortalDocsAppState();
}

class _PortalDocsAppState extends State<PortalDocsApp> {
  final GlobalKey<ScaffoldState> _narrowScaffoldKey =
      GlobalKey<ScaffoldState>();

  ThemeMode _themeMode = ThemeMode.system;
  PortalThemePaletteId _paletteId = PortalThemePaletteId.violet;
  String _visualThemeId = kPortalDefaultVisualThemeId;
  _DocsView _view = _DocsView.overview;
  ComponentEntry? _selected;

  void _pick(ComponentEntry e) {
    final scaffold = _narrowScaffoldKey.currentState;
    if (scaffold?.isDrawerOpen == true) {
      Navigator.pop(scaffold!.context);
    }
    setState(() {
      _view = _DocsView.component;
      _selected = e;
    });
  }

  void _goHome() => setState(() {
        _view = _DocsView.overview;
        _selected = null;
      });

  void _openShowcase() => setState(() {
        _view = _DocsView.showcase;
        _selected = null;
      });

  String get _themeKey => '${_paletteId.name}-$_visualThemeId';

  String get _appBarTitle => switch (_view) {
        _DocsView.overview => 'Portal UI Kit',
        _DocsView.showcase => 'UI Kit Showcase',
        _DocsView.component => _selected?.title ?? 'Portal UI Kit',
      };

  Widget get _body => switch (_view) {
        _DocsView.overview => HomePage(onPick: _pick),
        _DocsView.showcase => const UiKitShowcasePage(),
        _DocsView.component => ComponentDetailPage(entry: _selected!),
      };

  @override
  Widget build(BuildContext context) {
    final palette = PortalThemeCatalog.byId(_paletteId);
    final visual = PortalVisualThemeRegistry.instance.byId(_visualThemeId);
    final themes = PortalThemeComposer.build(
      palette: palette,
      visualTheme: visual,
    );

    return MaterialApp(
      key: ValueKey(_themeKey),
      title: 'Portal UI Kit',
      debugShowCheckedModeBanner: false,
      theme: themes.light,
      darkTheme: themes.dark,
      themeMode: _themeMode,
      home: Builder(
        builder: (context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 800;

              final nav = _DocsSideNav(
                view: _view,
                selected: _selected,
                paletteId: _paletteId,
                visualThemeId: _visualThemeId,
                themeMode: _themeMode,
                onHome: _goHome,
                onShowcase: _openShowcase,
                onPick: _pick,
                onPaletteChanged: (id) => setState(() => _paletteId = id),
                onVisualThemeChanged: (id) =>
                    setState(() => _visualThemeId = id),
                onThemeModeChanged: (m) => setState(() => _themeMode = m),
              );

              final appBar = AppBar(
                title: Text(_appBarTitle),
                automaticallyImplyLeading: !wide,
                actions: [
                  if (_view != _DocsView.overview)
                    IconButton(
                      tooltip: 'Back to overview',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goHome,
                    ),
                  if (!wide)
                    IconButton(
                      tooltip: 'Cycle theme (system / light / dark)',
                      onPressed: () {
                        setState(() {
                          _themeMode = switch (_themeMode) {
                            ThemeMode.system => ThemeMode.light,
                            ThemeMode.light => ThemeMode.dark,
                            ThemeMode.dark => ThemeMode.system,
                          };
                        });
                      },
                      icon: Icon(switch (_themeMode) {
                        ThemeMode.system => Icons.brightness_auto_outlined,
                        ThemeMode.light => Icons.light_mode_outlined,
                        ThemeMode.dark => Icons.dark_mode_outlined,
                      }),
                    ),
                ],
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 300,
                      child: Material(
                        elevation: 1,
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        child: nav,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Scaffold(
                        appBar: appBar,
                        body: PortalThemeBackdrop(child: _body),
                      ),
                    ),
                  ],
                );
              }

              return Scaffold(
                key: _narrowScaffoldKey,
                drawer: Drawer(child: nav),
                appBar: appBar,
                body: PortalThemeBackdrop(child: _body),
              );
            },
          );
        },
      ),
    );
  }
}

class _DocsSideNav extends StatelessWidget {
  const _DocsSideNav({
    required this.view,
    required this.selected,
    required this.paletteId,
    required this.visualThemeId,
    required this.themeMode,
    required this.onHome,
    required this.onShowcase,
    required this.onPick,
    required this.onPaletteChanged,
    required this.onVisualThemeChanged,
    required this.onThemeModeChanged,
  });

  final _DocsView view;
  final ComponentEntry? selected;
  final PortalThemePaletteId paletteId;
  final String visualThemeId;
  final ThemeMode themeMode;
  final VoidCallback onHome;
  final VoidCallback onShowcase;
  final void Function(ComponentEntry) onPick;
  final ValueChanged<PortalThemePaletteId> onPaletteChanged;
  final ValueChanged<String> onVisualThemeChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final t = PortalUiTheme.of(context).tokens;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                t.spacing.lg, t.spacing.lg, t.spacing.lg, t.spacing.sm),
            child: Text(
              'Portal UI',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Overview'),
            selected: view == _DocsView.overview,
            onTap: onHome,
          ),
          ListTile(
            leading: const Icon(Icons.phone_iphone_outlined),
            title: const Text('Showcase'),
            selected: view == _DocsView.showcase,
            onTap: onShowcase,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: t.spacing.sm),
              children: [
                for (final cat in ComponentCategory.values) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        t.spacing.md, t.spacing.md, t.spacing.md, t.spacing.xs),
                    child: Text(
                      cat.catalogLabel.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ),
                  for (final e
                      in kComponentCatalog.where((c) => c.category == cat))
                    ListTile(
                      dense: true,
                      title: Text(e.title),
                      selected:
                          view == _DocsView.component && selected?.id == e.id,
                      onTap: () => onPick(e),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(t.spacing.md),
            child: ThemeControls(
              paletteId: paletteId,
              visualThemeId: visualThemeId,
              themeMode: themeMode,
              onPaletteChanged: onPaletteChanged,
              onVisualThemeChanged: onVisualThemeChanged,
              onThemeModeChanged: onThemeModeChanged,
            ),
          ),
        ],
      ),
    );
  }
}
