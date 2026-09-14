import 'package:flutter/material.dart';
import 'package:portal_ui_core/portal_ui_core.dart';

/// Component gallery: every ui_core component on one scrolling page, with
/// brightness and preset switches in the app bar. Also the source of the
/// screenshots in the README.
void main() => runApp(const GalleryApp());

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  var _dark = false;
  var _preset = PortalUiPreset.defaultPreset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'portal_ui_core',
      debugShowCheckedModeBanner: false,
      theme: buildPortalTheme(
        brightness: _dark ? Brightness.dark : Brightness.light,
        preset: _preset,
      ),
      home: GalleryPage(
        dark: _dark,
        preset: _preset,
        onDarkChanged: (v) => setState(() => _dark = v),
        onPresetChanged: (p) => setState(() => _preset = p),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    required this.dark,
    required this.preset,
    required this.onDarkChanged,
    required this.onPresetChanged,
  });

  final bool dark;
  final PortalUiPreset preset;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<PortalUiPreset> onPresetChanged;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  var _tab = 0;
  var _nav = 0;
  var _chip = 1;
  var _loading = false;

  @override
  Widget build(BuildContext context) {
    final tokens = PortalUiTheme.of(context).tokens;
    final gap = SizedBox(height: tokens.spacing.lg);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PortalAppBar(
        title: 'portal_ui_core',
        subtitle: widget.preset.name,
        actions: [
          PortalAction(
            icon: widget.dark ? Icons.light_mode : Icons.dark_mode,
            label: widget.dark ? 'Light theme' : 'Dark theme',
            onPressed: () => widget.onDarkChanged(!widget.dark),
          ),
          PortalAction(
            icon: Icons.tune,
            label: 'Next preset',
            onPressed: () {
              final all = PortalUiPreset.values;
              widget.onPresetChanged(
                all[(all.indexOf(widget.preset) + 1) % all.length],
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [
          const PortalSectionHeader(title: 'Buttons', icon: Icons.smart_button),
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              for (final v in PortalButtonVariant.values)
                PortalButton(label: v.name, variant: v, onPressed: () {}),
              PortalButton(
                label: 'Loading',
                isLoading: _loading,
                leading: const Icon(Icons.cloud_upload),
                onPressed: () async {
                  setState(() => _loading = true);
                  await Future<void>.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _loading = false);
                },
              ),
            ],
          ),
          gap,
          const PortalSectionHeader(title: 'Stats', icon: Icons.insights),
          Row(
            children: [
              Expanded(
                child: PortalStatCard(
                  value: '12.4k',
                  label: 'Steps',
                  icon: Icons.directions_walk,
                ),
              ),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: PortalStatCard(
                  value: '48 min',
                  label: 'Active',
                  icon: Icons.timer,
                  accentColor: scheme.tertiary,
                ),
              ),
            ],
          ),
          gap,
          const PortalSectionHeader(title: 'Cards', icon: Icons.style),
          for (final v in PortalCardVariant.values) ...[
            PortalCard(
              variant: v,
              elevation: PortalCardElevation.soft,
              onTap: () {},
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center),
                title: Text('PortalCard.${v.name}'),
                subtitle: const Text('Tap ripple, themed border and radius'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
          gap,
          const PortalSectionHeader(title: 'Filters & tabs', icon: Icons.filter_alt),
          PortalFilterChipRow(
            children: [
              for (final (i, label) in ['All', 'Strength', 'Cardio', 'Mobility'].indexed)
                PortalFilterChip(
                  label: label,
                  selected: _chip == i,
                  onTap: () => setState(() => _chip = i),
                ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          PortalSegmentedTabs(
            labels: const ['Today', 'Week', 'Month'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          gap,
          const PortalSectionHeader(title: 'Search', icon: Icons.search),
          const PortalSearchField(hintText: 'Search exercises'),
          gap,
          const PortalSectionHeader(title: 'Loading', icon: Icons.hourglass_top),
          const PortalListSkeleton(itemCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics()),
          gap,
          const PortalSectionHeader(title: 'Empty', icon: Icons.inbox),
          PortalEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No workouts yet',
            message: 'Log your first session and it shows up here.',
            actionLabel: 'Add workout',
            onAction: () {},
          ),
          gap,
          const PortalSectionHeader(title: 'Dialog', icon: Icons.warning_amber),
          PortalButton(
            label: 'Confirm dialog',
            variant: PortalButtonVariant.destructive,
            onPressed: () => portalConfirm(
              context,
              title: 'Delete workout?',
              message: 'This cannot be undone.',
              confirmLabel: 'Delete',
              isDestructive: true,
            ),
          ),
          SizedBox(height: tokens.spacing.xl),
        ],
      ),
      bottomNavigationBar: PortalBottomNavBar(
        selectedIndex: _nav,
        onDestinationSelected: (i) => setState(() => _nav = i),
        destinations: const [
          PortalNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
          PortalNavDestination(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Stats', badgeCount: 3),
          PortalNavDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
