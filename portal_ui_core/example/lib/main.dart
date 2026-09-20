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
      // PortalThemeConfig, not buildPortalTheme: only the config path applies
      // the component sub-themes the gallery exists to show.
      theme: _dark
          ? PortalThemeConfig(tokens: designTokensForPreset(_preset)).dark()
          : PortalThemeConfig(tokens: designTokensForPreset(_preset)).light(),
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
  var _slider = 0.4;

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
            icon: widget.dark ? Symbols.light_mode_rounded : Symbols.dark_mode_rounded,
            label: widget.dark ? 'Light theme' : 'Dark theme',
            onPressed: () => widget.onDarkChanged(!widget.dark),
          ),
          PortalAction(
            icon: Symbols.tune_rounded,
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
          const PortalSectionHeader(title: 'Buttons', icon: Symbols.smart_button_rounded),
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              for (final v in PortalButtonVariant.values)
                PortalButton(label: v.name, variant: v, onPressed: () {}),
              PortalButton(
                label: 'Loading',
                isLoading: _loading,
                leading: const Icon(Symbols.cloud_upload_rounded),
                onPressed: () async {
                  setState(() => _loading = true);
                  await Future<void>.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _loading = false);
                },
              ),
            ],
          ),
          gap,
          const PortalSectionHeader(title: 'Stats', icon: Symbols.insights_rounded),
          Row(
            children: [
              Expanded(
                child: PortalStatCard(
                  value: '12.4k',
                  label: 'Steps',
                  icon: Symbols.directions_walk_rounded,
                ),
              ),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: PortalStatCard(
                  value: '48 min',
                  label: 'Active',
                  icon: Symbols.timer_rounded,
                  accentColor: scheme.tertiary,
                ),
              ),
            ],
          ),
          gap,
          const PortalSectionHeader(title: 'Cards', icon: Symbols.style_rounded),
          for (final v in PortalCardVariant.values) ...[
            PortalCard(
              variant: v,
              elevation: PortalCardElevation.soft,
              onTap: () {},
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Symbols.fitness_center_rounded),
                title: Text('PortalCard.${v.name}'),
                subtitle: const Text('Tap ripple, themed border and radius'),
                trailing: const Icon(Symbols.chevron_right_rounded),
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
          gap,
          const PortalSectionHeader(title: 'Filters & tabs', icon: Symbols.filter_alt_rounded),
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
          SizedBox(height: tokens.spacing.md),
          DefaultTabController(
            length: 3,
            child: TabBar(
              tabs: [
                for (final t in ['Overview', 'History', 'Notes']) Tab(text: t),
              ],
            ),
          ),
          gap,
          const PortalSectionHeader(title: 'Slider & pickers', icon: Symbols.tune_rounded),
          Slider(
            value: _slider,
            label: '${(_slider * 100).round()}%',
            divisions: 10,
            onChanged: (v) => setState(() => _slider = v),
          ),
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              PortalButton(
                label: 'Pick date',
                variant: PortalButtonVariant.secondary,
                onPressed: () => showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                ),
              ),
              PortalButton(
                label: 'Pick time',
                variant: PortalButtonVariant.secondary,
                onPressed: () => showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                ),
              ),
              PortalButton(
                label: 'Bottom sheet',
                variant: PortalButtonVariant.secondary,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => Padding(
                    padding: EdgeInsets.all(tokens.spacing.lg),
                    child: const PortalEmptyState(
                      icon: Symbols.layers_rounded,
                      title: 'Themed sheet',
                      message: 'radii.xl top, drag handle, panel surface.',
                    ),
                  ),
                ),
              ),
            ],
          ),
          gap,
          const PortalSectionHeader(title: 'Search', icon: Symbols.search_rounded),
          const PortalSearchField(hintText: 'Search exercises'),
          gap,
          const PortalSectionHeader(title: 'Loading', icon: Symbols.hourglass_top_rounded),
          const PortalListSkeleton(itemCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics()),
          gap,
          const PortalSectionHeader(title: 'Empty', icon: Symbols.inbox_rounded),
          PortalEmptyState(
            icon: Symbols.inbox_rounded,
            title: 'No workouts yet',
            message: 'Log your first session and it shows up here.',
            actionLabel: 'Add workout',
            onAction: () {},
          ),
          gap,
          const PortalSectionHeader(title: 'Dialog', icon: Symbols.warning_rounded),
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
          PortalNavDestination(icon: Symbols.home_rounded, label: 'Home'),
          PortalNavDestination(icon: Symbols.bar_chart_rounded, label: 'Stats', badgeCount: 3),
          PortalNavDestination(icon: Symbols.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }
}
